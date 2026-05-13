import '../../profile/domain/app_user.dart';
import 'message.dart';

abstract interface class MessageRepository {
  Stream<List<MessageModel>> watchMessages(String circleId);

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
}
