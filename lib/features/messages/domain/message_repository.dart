import '../../profile/domain/app_user.dart';
import 'message.dart';

abstract interface class MessageRepository {
  Stream<List<MessageModel>> watchMessages(String circleId, {int limit});

  Future<void> sendTextMessage({
    required String circleId,
    required String text,
    required AppUser sender,
  });

  Future<void> sendPhotoMessage({
    required String circleId,
    required String mediaUrl,
    required String? text,
    required AppUser sender,
  });

  /// Soft-deletes a message by overwriting it with a 'deleted' type and
  /// clearing content fields. Only the original sender may call this.
  Future<void> softDeleteMessage({
    required String circleId,
    required String messageId,
    required String senderId,
  });
}
