import '../../profile/domain/app_user.dart';
import 'plan.dart';
import 'plan_response.dart';

abstract interface class PlanRepository {
  Stream<List<PlanModel>> watchActivePlans(String circleId);

  Stream<PlanModel?> watchPlan({
    required String circleId,
    required String planId,
  });

  Future<PlanModel> createPlan({
    required String circleId,
    required AppUser creator,
    required String title,
    required String? description,
    required String? location,
    required DateTime startsAt,
  });

  Stream<List<PlanResponseModel>> watchPlanResponses({
    required String circleId,
    required String planId,
  });

  Future<void> respondToPlan({
    required String circleId,
    required String planId,
    required AppUser user,
    required PlanResponseValue response,
    required String? comment,
  });
}
