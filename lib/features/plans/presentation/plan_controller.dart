import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/firebase_plan_repository.dart';
import '../domain/plan.dart';
import '../domain/plan_repository.dart';
import '../domain/plan_response.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirebasePlanRepository();
});

final activePlansProvider = StreamProvider.family<List<PlanModel>, String>((
  ref,
  circleId,
) {
  return ref.watch(planRepositoryProvider).watchActivePlans(circleId);
});

final planProvider =
    StreamProvider.family<PlanModel?, ({String circleId, String planId})>((
      ref,
      args,
    ) {
      return ref
          .watch(planRepositoryProvider)
          .watchPlan(circleId: args.circleId, planId: args.planId);
    });

final planResponsesProvider =
    StreamProvider.family<
      List<PlanResponseModel>,
      ({String circleId, String planId})
    >((ref, args) {
      return ref
          .watch(planRepositoryProvider)
          .watchPlanResponses(circleId: args.circleId, planId: args.planId);
    });

final planControllerProvider = AsyncNotifierProvider<PlanController, void>(
  PlanController.new,
);

class PlanController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PlanModel> createPlan({
    required String circleId,
    required String title,
    required String? description,
    required String? location,
    required DateTime startsAt,
  }) async {
    final creator = await _requireProfile();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref
          .read(planRepositoryProvider)
          .createPlan(
            circleId: circleId,
            creator: creator,
            title: title,
            description: description,
            location: location,
            startsAt: startsAt,
          );
    });
    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError<void>.new,
      loading: () => const AsyncLoading(),
    );
    return result.requireValue;
  }

  Future<void> respondToPlan({
    required String circleId,
    required String planId,
    required PlanResponseValue response,
    required String? comment,
  }) async {
    final user = await _requireProfile();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(planRepositoryProvider)
          .respondToPlan(
            circleId: circleId,
            planId: planId,
            user: user,
            response: response,
            comment: comment,
          );
    });
  }

  Future<AppUser> _requireProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(user.id);
    if (profile == null) {
      throw StateError('Create your profile before using Plans.');
    }
    return profile;
  }
}
