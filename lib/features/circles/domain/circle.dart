import '../../../core/utils/firestore_date.dart';

/// Lifecycle for a Circle document. Soft-delete uses [deleted]; missing
/// Firestore values are treated as [active] for legacy documents.
enum CircleStatus { active, deleted }

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
    this.status = CircleStatus.active,
    this.todayPulseDateKey,
    this.todayPulseCount = 0,
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
  final CircleStatus status;

  /// Local-device date key (`yyyyMMdd`) for which [todayPulseCount] applies.
  final String? todayPulseDateKey;
  final int todayPulseCount;

  bool get isDeleted => status == CircleStatus.deleted;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverUrl': coverUrl,
      'createdBy': createdBy,
      'inviteCode': inviteCode,
      'memberCount': memberCount,
      'status': status.name,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (todayPulseDateKey != null) 'todayPulseDateKey': todayPulseDateKey,
      'todayPulseCount': todayPulseCount,
    };
  }

  factory CircleModel.fromMap(Map<String, Object?> map) {
    final statusRaw = map['status'] as String?;
    return CircleModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      coverUrl: map['coverUrl'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      memberCount: map['memberCount'] as int? ?? 0,
      status: statusRaw == CircleStatus.deleted.name
          ? CircleStatus.deleted
          : CircleStatus.active,
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageAt: readNullableFirestoreDate(map['lastMessageAt']),
      createdAt: readFirestoreDate(map['createdAt']),
      updatedAt: readFirestoreDate(map['updatedAt']),
      todayPulseDateKey: map['todayPulseDateKey'] as String?,
      todayPulseCount: map['todayPulseCount'] as int? ?? 0,
    );
  }
}
