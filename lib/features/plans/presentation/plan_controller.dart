import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
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
    _logState('plan.create', {'circleId': circleId, 'title': title.trim()});
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
    _logState('plan.respond', {
      'circleId': circleId,
      'planId': planId,
      'response': response.firestoreValue,
    });
  }

  Future<void> editPlan({
    required String circleId,
    required String planId,
    required String title,
    required String? description,
    required String? location,
    required DateTime startsAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(planRepositoryProvider)
          .editPlan(
            circleId: circleId,
            planId: planId,
            title: title,
            description: description,
            location: location,
            startsAt: startsAt,
          );
    });
    _logState('plan.edit', {'circleId': circleId, 'planId': planId});
  }

  Future<void> cancelPlan({
    required String circleId,
    required String planId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(planRepositoryProvider)
          .cancelPlan(circleId: circleId, planId: planId);
    });
    _logState('plan.cancel', {'circleId': circleId, 'planId': planId});
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

  void _logState(String event, [Map<String, Object?> details = const {}]) {
    if (state.hasError) {
      AppLogger.error(event, state.error!, details);
      return;
    }
    AppLogger.success(event, details);
  }
}
