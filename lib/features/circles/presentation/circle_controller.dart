import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/firebase_circle_repository.dart';
import '../domain/circle.dart';
import '../domain/circle_member.dart';
import '../domain/circle_repository.dart';

final circleRepositoryProvider = Provider<CircleRepository>((ref) {
  return FirebaseCircleRepository();
});

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
    return result.requireValue;
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
      throw StateError('Create your profile before using Circles.');
    }
    return profile;
  }
}
