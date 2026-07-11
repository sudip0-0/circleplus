import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';

const r2UploadSignerUrlDefineName = 'R2_UPLOAD_SIGNER_URL';

enum StorageUploadType {
  avatar,
  circleCover,
  messagePhoto,
  pulsePhoto;

  String get requestValue {
    return switch (this) {
      StorageUploadType.avatar => 'avatar',
      StorageUploadType.circleCover => 'circleCover',
      StorageUploadType.messagePhoto => 'messagePhoto',
      StorageUploadType.pulsePhoto => 'pulsePhoto',
    };
  }
}

class UploadedMedia {
  const UploadedMedia({required this.objectKey});

  /// R2 object key stored in Firestore. Resolve to a signed URL for display.
  final String objectKey;
}

abstract interface class StorageService {
  Future<UploadedMedia> uploadBytes({
    required StorageUploadType type,
    required Uint8List bytes,
    required String contentType,
    required String fileExtension,
    String? circleId,
  });

  /// Returns a short-lived HTTPS URL for [objectKey], or [objectKey] itself
  /// when it is already an absolute http(s) URL (legacy public media).
  Future<String> resolveDownloadUrl({
    required String objectKey,
    String? circleId,
  });
}

class R2PresignedUrlStorageService implements StorageService {
  R2PresignedUrlStorageService({
    http.Client? client,
    FirebaseAuth? firebaseAuth,
    String signerUrl = const String.fromEnvironment(
      r2UploadSignerUrlDefineName,
    ),
  }) : _client = client ?? http.Client(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _signerUrl = signerUrl;

  final http.Client _client;
  final FirebaseAuth _firebaseAuth;
  final String _signerUrl;

  final Map<String, ({String url, DateTime expiresAt})> _downloadCache = {};

  bool get _hasSigner => _signerUrl.isNotEmpty;

  @override
  Future<UploadedMedia> uploadBytes({
    required StorageUploadType type,
    required Uint8List bytes,
    required String contentType,
    required String fileExtension,
    String? circleId,
  }) async {
    AppLogger.info('media.upload.start', {'type': type.requestValue});
    _requireSigner();

    final token = await _requireIdToken();
    final signRequest = <String, Object?>{
      'action': 'upload',
      'type': type.requestValue,
      'contentType': contentType,
      'fileExtension': fileExtension,
      'contentLength': bytes.length,
    };
    if (circleId != null) {
      signRequest['circleId'] = circleId;
    }

    final signResponse = await _client.post(
      Uri.parse(_signerUrl),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(signRequest),
    );

    if (signResponse.statusCode != 200) {
      throw AppException(
        'Could not prepare media upload: ${signResponse.body}',
      );
    }

    final body = jsonDecode(signResponse.body) as Map<String, dynamic>;
    final uploadUrl = body['uploadUrl'] as String?;
    final objectKey = body['objectKey'] as String?;
    if (uploadUrl == null || objectKey == null) {
      throw const AppException('Upload signer returned an invalid response.');
    }

    final responseHeaders = body['headers'];
    final uploadHeaders = <String, String>{
      'content-type': contentType,
      'content-length': '${bytes.length}',
    };
    if (responseHeaders is Map) {
      responseHeaders.forEach((key, value) {
        if (key is String && value is String) {
          uploadHeaders[key] = value;
        }
      });
    }

    final uploadResponse = await _client.put(
      Uri.parse(uploadUrl),
      headers: uploadHeaders,
      body: bytes,
    );
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw AppException('Media upload failed: ${uploadResponse.body}');
    }

    AppLogger.success('media.upload.complete', {
      'type': type.requestValue,
      'objectKey': objectKey,
    });
    return UploadedMedia(objectKey: objectKey);
  }

  @override
  Future<String> resolveDownloadUrl({
    required String objectKey,
    String? circleId,
  }) async {
    final trimmed = objectKey.trim();
    if (trimmed.isEmpty) {
      throw const AppException('Missing media reference.');
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final cached = _downloadCache[trimmed];
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return cached.url;
    }

    _requireSigner();
    final token = await _requireIdToken();
    final requestBody = <String, Object?>{
      'action': 'download',
      'objectKey': trimmed,
    };
    if (circleId != null) {
      requestBody['circleId'] = circleId;
    }

    final response = await _client.post(
      Uri.parse(_signerUrl),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw AppException('Could not resolve media download: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final downloadUrl = body['downloadUrl'] as String?;
    final expiresIn = body['expiresInSeconds'] as int? ?? 300;
    if (downloadUrl == null) {
      throw const AppException('Download signer returned an invalid response.');
    }

    _downloadCache[trimmed] = (
      url: downloadUrl,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn - 30)),
    );
    return downloadUrl;
  }

  void _requireSigner() {
    if (!_hasSigner) {
      throw const AppException(
        'Developer setup required: media upload needs --dart-define=R2_UPLOAD_SIGNER_URL=https://your-worker-url. Flutter does not read the root .env file automatically.',
      );
    }
  }

  Future<String> _requireIdToken() async {
    final user = _firebaseAuth.currentUser;
    final token = await user?.getIdToken();
    if (user == null || token == null) {
      throw const AppException('You must be signed in to access media.');
    }
    return token;
  }
}
