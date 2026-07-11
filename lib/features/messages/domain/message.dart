import '../../../core/utils/firestore_date.dart';

enum MessageType {
  text,
  photo,
  system,
  deleted;

  static MessageType fromName(String? value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.circleId,
    required this.senderId,
    required this.senderName,
    required this.senderPhotoUrl,
    required this.type,
    required this.text,
    required this.mediaUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String circleId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Non-null when the sender has soft-deleted the message.
  final DateTime? deletedAt;

  bool get isDeleted => type == MessageType.deleted || deletedAt != null;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'circleId': circleId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type.name,
      'text': text,
      'mediaUrl': mediaUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
    };
  }

  factory MessageModel.fromMap(Map<String, Object?> map) {
    return MessageModel(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderPhotoUrl: map['senderPhotoUrl'] as String?,
      type: MessageType.fromName(map['type'] as String?),
      text: map['text'] as String?,
      mediaUrl: map['mediaUrl'] as String?,
      createdAt: readFirestoreDate(map['createdAt']),
      updatedAt: readNullableFirestoreDate(map['updatedAt']),
      deletedAt: readNullableFirestoreDate(map['deletedAt']),
    );
  }
}
