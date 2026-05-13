class PulseModel {
  const PulseModel({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.photoUrl,
    required this.caption,
    required this.mood,
    required this.dateKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String circleId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String photoUrl;
  final String? caption;
  final String? mood;
  final String dateKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'circleId': circleId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'photoUrl': photoUrl,
      'caption': caption,
      'mood': mood,
      'dateKey': dateKey,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PulseModel.fromMap(Map<String, Object?> map) {
    return PulseModel(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      photoUrl: map['photoUrl'] as String? ?? '',
      caption: map['caption'] as String?,
      mood: map['mood'] as String?,
      dateKey: map['dateKey'] as String? ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

String pulseDocumentId({required String dateKey, required String userId}) {
  return '${dateKey}_$userId';
}

DateTime _readDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  final dynamic dynamicValue = value;
  final Object? date = dynamicValue.toDate();
  return date is DateTime ? date : DateTime.fromMillisecondsSinceEpoch(0);
}
