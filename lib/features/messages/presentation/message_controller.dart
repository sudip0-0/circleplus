import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
