import '../../../core/utils/firestore_date.dart';

enum PlanStatus {
  active,
  cancelled,
  completed;

  static PlanStatus fromName(String? value) {
    return PlanStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PlanStatus.active,
    );
  }
}

class PlanModel {
  const PlanModel({
    required this.id,
    required this.circleId,
    required this.createdBy,
    required this.createdByName,
    required this.title,
    required this.description,
    required this.location,
    required this.startsAt,
    required this.status,
    required this.inCount,
    required this.maybeCount,
    required this.cantCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String circleId;
  final String createdBy;
  final String createdByName;
  final String title;
  final String? description;
  final String? location;
  final DateTime startsAt;
  final PlanStatus status;
  final int inCount;
  final int maybeCount;
  final int cantCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'circleId': circleId,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'title': title,
      'description': description,
      'location': location,
      'startsAt': startsAt,
      'status': status.name,
      'inCount': inCount,
      'maybeCount': maybeCount,
      'cantCount': cantCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PlanModel.fromMap(Map<String, Object?> map) {
    return PlanModel(
      id: map['id'] as String? ?? '',
      circleId: map['circleId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      location: map['location'] as String?,
      startsAt: readFirestoreDate(map['startsAt']),
      status: PlanStatus.fromName(map['status'] as String?),
      inCount: map['inCount'] as int? ?? 0,
      maybeCount: map['maybeCount'] as int? ?? 0,
      cantCount: map['cantCount'] as int? ?? 0,
      createdAt: readFirestoreDate(map['createdAt']),
      updatedAt: readFirestoreDate(map['updatedAt']),
    );
  }
}
