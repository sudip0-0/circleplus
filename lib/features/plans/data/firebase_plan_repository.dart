import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/domain/app_user.dart';
import '../domain/plan.dart';
import '../domain/plan_response.dart';
import '../domain/plan_repository.dart';

class FirebasePlanRepository implements PlanRepository {
  FirebasePlanRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _circles =>
      _firestore.collection('circles');

  @override
  Stream<List<PlanModel>> watchActivePlans(String circleId) {
    return _circles
        .doc(circleId)
        .collection('plans')
        .where('status', isEqualTo: PlanStatus.active.name)
        .where('startsAt', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('startsAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlanModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Stream<PlanModel?> watchPlan({
    required String circleId,
    required String planId,
  }) {
    return _circles
        .doc(circleId)
        .collection('plans')
        .doc(planId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            return null;
          }
          return PlanModel.fromMap(data);
        });
  }

  @override
  Future<PlanModel> createPlan({
    required String circleId,
    required AppUser creator,
    required String title,
    required String? description,
    required String? location,
    required DateTime startsAt,
  }) async {
    final planRef = _circles.doc(circleId).collection('plans').doc();
    final now = DateTime.now();
    final plan = PlanModel(
      id: planRef.id,
      circleId: circleId,
      createdBy: creator.id,
      createdByName: creator.displayName,
      title: title.trim(),
      description: _blankToNull(description),
      location: _blankToNull(location),
      startsAt: startsAt,
      status: PlanStatus.active,
      inCount: 0,
      maybeCount: 0,
      cantCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await planRef.set(plan.toMap());
    return plan;
  }

  @override
  Stream<List<PlanResponseModel>> watchPlanResponses({
    required String circleId,
    required String planId,
  }) {
    return _circles
        .doc(circleId)
        .collection('plans')
        .doc(planId)
        .collection('responses')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlanResponseModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> respondToPlan({
    required String circleId,
    required String planId,
    required AppUser user,
    required PlanResponseValue response,
    required String? comment,
  }) async {
    final planRef = _circles.doc(circleId).collection('plans').doc(planId);
    final responseRef = planRef.collection('responses').doc(user.id);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(responseRef);
      final previous = existing.exists
          ? PlanResponseModel.fromMap(
              existing.data() ?? <String, Object?>{},
            ).response
          : null;
      final delta = planResponseCountDelta(previous: previous, next: response);
      final now = DateTime.now();

      transaction.set(
        responseRef,
        PlanResponseModel(
          userId: user.id,
          userName: user.displayName,
          userPhotoUrl: user.photoUrl,
          response: response,
          comment: _blankToNull(comment),
          updatedAt: now,
        ).toMap(),
      );
      transaction.update(planRef, {
        'inCount': FieldValue.increment(delta['inCount']!),
        'maybeCount': FieldValue.increment(delta['maybeCount']!),
        'cantCount': FieldValue.increment(delta['cantCount']!),
        'updatedAt': now,
      });
    });
  }

  @override
  Future<void> editPlan({
    required String circleId,
    required String planId,
    required String title,
    required String? description,
    required String? location,
    required DateTime startsAt,
  }) async {
    final planRef = _circles.doc(circleId).collection('plans').doc(planId);
    await planRef.update({
      'title': title.trim(),
      'description': _blankToNull(description),
      'location': _blankToNull(location),
      'startsAt': startsAt,
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Future<void> cancelPlan({
    required String circleId,
    required String planId,
  }) async {
    final planRef = _circles.doc(circleId).collection('plans').doc(planId);
    await planRef.update({
      'status': PlanStatus.cancelled.name,
      'updatedAt': DateTime.now(),
    });
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
