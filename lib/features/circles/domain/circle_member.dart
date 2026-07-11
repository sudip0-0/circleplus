import '../../../core/utils/firestore_date.dart';

enum CircleMemberRole {
  creator,
  member;

  static CircleMemberRole fromName(String? value) {
    return CircleMemberRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => CircleMemberRole.member,
    );
  }
}

class CircleMemberModel {
  const CircleMemberModel({
    required this.userId,
    required this.circleId,
    required this.role,
    required this.displayName,
    required this.photoUrl,
    required this.joinedAt,
    this.inviteCodeUsed,
  });

  final String userId;
  final String circleId;
  final CircleMemberRole role;
  final String displayName;
  final String? photoUrl;
  final DateTime joinedAt;
  final String? inviteCodeUsed;

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'circleId': circleId,
      'role': role.name,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'joinedAt': joinedAt,
      if (inviteCodeUsed != null) 'inviteCodeUsed': inviteCodeUsed,
    };
  }

  factory CircleMemberModel.fromMap(Map<String, Object?> map) {
    return CircleMemberModel(
      userId: map['userId'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      role: CircleMemberRole.fromName(map['role'] as String?),
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      joinedAt: readFirestoreDate(map['joinedAt']),
      inviteCodeUsed: map['inviteCodeUsed'] as String?,
    );
  }
}
