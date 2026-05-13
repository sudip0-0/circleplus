abstract interface class NotificationRepository {
  Future<void> requestPermissionAndSyncToken(String userId);
}
