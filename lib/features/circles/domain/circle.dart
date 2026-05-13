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
      lastMessageAt: _readNullableDate(map['lastMessageAt']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

DateTime _readDate(Object? value) {
  return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value == null) {
    return null;
  }

  final dynamic dynamicValue = value;
  final Object? date = dynamicValue.toDate();
  return date is DateTime ? date : null;
}
