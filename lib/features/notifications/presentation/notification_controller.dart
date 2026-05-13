import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/firebase_notification_repository.dart';
import '../domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, void>(
      NotificationController.new,
    );

class NotificationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> requestPermissionAndSyncToken() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(notificationRepositoryProvider)
          .requestPermissionAndSyncToken(user.id);
    });
  }
}
