enum PlanResponseValue {
  in_,
  maybe,
  cant;

  String get firestoreValue {
    return switch (this) {
      PlanResponseValue.in_ => 'in',
      PlanResponseValue.maybe => 'maybe',
      PlanResponseValue.cant => 'cant',
    };
  }

  static PlanResponseValue fromName(String? value) {
    return switch (value) {
      'in' => PlanResponseValue.in_,
      'maybe' => PlanResponseValue.maybe,
      'cant' => PlanResponseValue.cant,
      _ => PlanResponseValue.maybe,
    };
  }
}

class PlanResponseModel {
  const PlanResponseModel({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.response,
    required this.comment,
    required this.updatedAt,
  });

  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final PlanResponseValue response;
  final String? comment;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'response': response.firestoreValue,
      'comment': comment,
      'updatedAt': updatedAt,
    };
  }

  factory PlanResponseModel.fromMap(Map<String, Object?> map) {
    return PlanResponseModel(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      response: PlanResponseValue.fromName(map['response'] as String?),
      comment: map['comment'] as String?,
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

Map<String, int> planResponseCountDelta({
  PlanResponseValue? previous,
  required PlanResponseValue next,
}) {
  final delta = {'inCount': 0, 'maybeCount': 0, 'cantCount': 0};
  if (previous == next) {
    return delta;
  }
  if (previous != null) {
    delta[_countField(previous)] = delta[_countField(previous)]! - 1;
  }
  delta[_countField(next)] = delta[_countField(next)]! + 1;
  return delta;
}

String _countField(PlanResponseValue value) {
  return switch (value) {
    PlanResponseValue.in_ => 'inCount',
    PlanResponseValue.maybe => 'maybeCount',
    PlanResponseValue.cant => 'cantCount',
  };
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
