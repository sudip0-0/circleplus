import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/domain/app_user.dart';
import '../domain/message.dart';
import '../domain/message_repository.dart';

class FirebaseMessageRepository implements MessageRepository {
  FirebaseMessageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _circles =>
      _firestore.collection('circles');

  @override
  Stream<List<MessageModel>> watchMessages(String circleId) {
    return _circles
        .doc(circleId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> sendTextMessage({
    required String circleId,
    required String text,
    required AppUser sender,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final circleRef = _circles.doc(circleId);
    final messageRef = circleRef.collection('messages').doc();
    final now = DateTime.now();
    final message = MessageModel(
      id: messageRef.id,
      circleId: circleId,
      senderId: sender.id,
      senderName: sender.displayName,
      senderPhotoUrl: sender.photoUrl,
      type: MessageType.text,
      text: trimmed,
      mediaUrl: null,
      createdAt: now,
      updatedAt: null,
    );

    final batch = _firestore.batch();
    batch.set(messageRef, message.toMap());
    batch.update(circleRef, {
      'lastMessageText': trimmed,
      'lastMessageAt': now,
      'updatedAt': now,
    });
    await batch.commit();
  }

  @override
  Future<void> sendPhotoMessage({
    required String circleId,
    required String mediaUrl,
    required String? text,
    required AppUser sender,
  }) async {
    final circleRef = _circles.doc(circleId);
    final messageRef = circleRef.collection('messages').doc();
    final now = DateTime.now();
    final caption = _blankToNull(text);
    final message = MessageModel(
      id: messageRef.id,
      circleId: circleId,
      senderId: sender.id,
      senderName: sender.displayName,
      senderPhotoUrl: sender.photoUrl,
      type: MessageType.photo,
      text: caption,
      mediaUrl: mediaUrl,
      createdAt: now,
      updatedAt: null,
    );

    final batch = _firestore.batch();
    batch.set(messageRef, message.toMap());
    batch.update(circleRef, {
      'lastMessageText': caption ?? 'Photo',
      'lastMessageAt': now,
      'updatedAt': now,
    });
    await batch.commit();
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
