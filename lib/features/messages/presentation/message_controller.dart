import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../services/storage/storage_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/firebase_message_repository.dart';
import '../domain/message.dart';
import '../domain/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FirebaseMessageRepository();
});

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
    required List<int> bytes,
    required String contentType,
    required String fileExtension,
    required String? text,
  }) async {
    final sender = await _requireProfile();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uploaded = await ref
          .read(storageServiceProvider)
          .uploadBytes(
            type: StorageUploadType.messagePhoto,
            bytes: Uint8List.fromList(bytes),
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

  Future<AppUser> _requireProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(user.id);
    if (profile == null) {
      throw StateError('Create your profile before sending messages.');
    }
    return profile;
  }

  void _logState(String event, [Map<String, Object?> details = const {}]) {
    if (state.hasError) {
      AppLogger.error(event, state.error!, details);
      return;
    }
    AppLogger.success(event, details);
  }
}
