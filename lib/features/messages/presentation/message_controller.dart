import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/require_current_profile.dart';
import '../../../services/storage/storage_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../domain/message.dart';

final circleMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, circleId) {
      return ref.watch(messageRepositoryProvider).watchMessages(circleId);
    });

final messageControllerProvider =
    AsyncNotifierProvider<MessageController, void>(MessageController.new);

class MessageController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendTextMessage({
    required String circleId,
    required String text,
  }) async {
    final sender = await _requireProfile();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(messageRepositoryProvider)
          .sendTextMessage(circleId: circleId, text: text, sender: sender);
    });
    _logState('message.sendText', {'circleId': circleId});
  }

  Future<void> uploadPhotoMessage({
    required String circleId,
    required Uint8List bytes,
    required String contentType,
    required String fileExtension,
    String? text,
  }) async {
    final sender = await _requireProfile();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uploaded = await ref
          .read(storageServiceProvider)
          .uploadBytes(
            type: StorageUploadType.messagePhoto,
            bytes: bytes,
            contentType: contentType,
            fileExtension: fileExtension,
            circleId: circleId,
          );
      await ref
          .read(messageRepositoryProvider)
          .sendPhotoMessage(
            circleId: circleId,
            mediaUrl: uploaded.publicUrl,
            text: text,
            sender: sender,
          );
    });
    _logState('message.sendPhoto', {'circleId': circleId});
  }

  Future<void> softDeleteMessage({
    required String circleId,
    required String messageId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(messageRepositoryProvider)
          .softDeleteMessage(circleId: circleId, messageId: messageId);
    });
    _logState('message.softDelete', {
      'circleId': circleId,
      'messageId': messageId,
    });
  }

  Future<AppUser> _requireProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    return requireCurrentProfile(
      profileRepository: ref.read(profileRepositoryProvider),
      userId: user.id,
    );
  }

  void _logState(String event, [Map<String, Object?> details = const {}]) {
    if (state.hasError) {
      AppLogger.error(event, state.error!, details);
      return;
    }
    AppLogger.success(event, details);
  }
}
