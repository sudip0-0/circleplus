import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/require_current_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../domain/circle.dart';
import '../domain/circle_member.dart';

final userCirclesProvider = StreamProvider<List<CircleModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<CircleModel>>.value(const []);
  }
  return ref.watch(circleRepositoryProvider).watchUserCircles(user.id);
});

final circleProvider = StreamProvider.family<CircleModel?, String>((
  ref,
  circleId,
) {
  return ref.watch(circleRepositoryProvider).watchCircle(circleId);
});

final circleMembersProvider =
    StreamProvider.family<List<CircleMemberModel>, String>((ref, circleId) {
      return ref.watch(circleRepositoryProvider).watchCircleMembers(circleId);
    });

final circleControllerProvider = AsyncNotifierProvider<CircleController, void>(
  CircleController.new,
);

class CircleController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CircleModel> createCircle({
    required String name,
    required String? description,
  }) async {
    final profile = await _requireProfile();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref
          .read(circleRepositoryProvider)
          .createCircle(name: name, description: description, creator: profile);
    });
    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError<void>.new,
      loading: () => const AsyncLoading(),
    );
    _logState('circle.create', {'name': name.trim()});
    return result.requireValue;
  }

  Future<CircleModel> joinCircleByInviteCode(String inviteCode) async {
    final profile = await _requireProfile();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref
          .read(circleRepositoryProvider)
          .joinCircleByInviteCode(inviteCode: inviteCode, user: profile);
    });
    state = result.when(
      data: (_) => const AsyncData(null),
      error: AsyncError<void>.new,
      loading: () => const AsyncLoading(),
    );
    _logState('circle.join', {'inviteCode': inviteCode.trim().toUpperCase()});
    return result.requireValue;
  }

  /// Leaves a Circle. If the caller is the creator and the last member,
  /// the Circle is deleted entirely instead.
  Future<void> leaveCircle(String circleId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(circleRepositoryProvider)
          .leaveCircle(circleId: circleId, userId: user.id);
    });
    _logState('circle.leave', {'circleId': circleId});
  }

  /// Deletes a Circle (creator-only, last-member-only).
  Future<void> deleteCircle(String circleId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(circleRepositoryProvider)
          .deleteCircle(circleId: circleId, creatorId: user.id);
    });
    _logState('circle.delete', {'circleId': circleId});
  }

  Future<AppUser> _requireProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }
    return requireCurrentProfile(
      profileRepository: ref.read(profileRepositoryProvider),
      userId: user.id,
    );
  }

  void _logState(String event, [Map<String, Object?> details = const {}]) {
    if (state.hasError) {
      AppLogger.error(event, state.error!, details);
      return;
    }
    AppLogger.success(event, details);
  }
}
