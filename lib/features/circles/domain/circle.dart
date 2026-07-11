import '../../../core/utils/firestore_date.dart';

class CircleModel {
  const CircleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.createdBy,
    required this.inviteCode,
    required this.memberCount,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String createdBy;
  final String inviteCode;
  final int memberCount;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'createdBy': createdBy,
      'inviteCode': inviteCode,
      'memberCount': memberCount,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CircleModel.fromMap(Map<String, Object?> map) {
    return CircleModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      coverUrl: map['coverUrl'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberCount: map['memberCount'] as int? ?? 0,
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageAt: readNullableFirestoreDate(map['lastMessageAt']),
      createdAt: readFirestoreDate(map['createdAt']),
      updatedAt: readFirestoreDate(map['updatedAt']),
    );
  }
}
