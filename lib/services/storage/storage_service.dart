import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  const UploadedMedia({required this.objectKey, required this.publicUrl});

  final String objectKey;
  final String publicUrl;
}

abstract interface class StorageService {
  Future<UploadedMedia> uploadBytes({
    required StorageUploadType type,
    required Uint8List bytes,
    required String contentType,
    required String fileExtension,
    String? circleId,
  });
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return R2PresignedUrlStorageService();
});

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

  @override
  Future<UploadedMedia> uploadBytes({
    required StorageUploadType type,
    required Uint8List bytes,
    required String contentType,
    required String fileExtension,
    String? circleId,
  }) async {
    AppLogger.info('media.upload.start', {'type': type.requestValue});
    if (_signerUrl.isEmpty) {
      throw const AppException(
        'Developer setup required: media upload needs --dart-define=R2_UPLOAD_SIGNER_URL=https://your-worker-url. Flutter does not read the root .env file automatically.',
      );
    }

    final user = _firebaseAuth.currentUser;
    final token = await user?.getIdToken();
    if (user == null || token == null) {
      throw const AppException('You must be signed in to upload media.');
    }

    final signRequest = {
      'type': type.requestValue,
      'contentType': contentType,
      'fileExtension': fileExtension,
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
    final publicUrl = body['publicUrl'] as String?;
    final objectKey = body['objectKey'] as String?;
    if (uploadUrl == null || publicUrl == null || objectKey == null) {
      throw const AppException('Upload signer returned an invalid response.');
    }

    final uploadResponse = await _client.put(
      Uri.parse(uploadUrl),
      headers: {'content-type': contentType},
      body: bytes,
    );
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw AppException('Media upload failed: ${uploadResponse.body}');
    }

    AppLogger.success('media.upload.complete', {
      'type': type.requestValue,
      'objectKey': objectKey,
    });
    return UploadedMedia(objectKey: objectKey, publicUrl: publicUrl);
  }
}
