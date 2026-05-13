import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/app_user.dart';
import 'profile_providers.dart';

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<AppUser?>.value(null);
  }
  return ref.watch(profileRepositoryProvider).watchProfile(user.id);
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updateProfile({
    required AppUser currentProfile,
    required String displayName,
    required String? bio,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updated = currentProfile.copyWith(
        displayName: displayName.trim(),
        bio: _blankToNull(bio),
        updatedAt: DateTime.now(),
      );
      await ref.read(profileRepositoryProvider).updateProfile(updated);
    });
  }

  Future<void> createProfile({
    required String displayName,
    required String? bio,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      await ref
          .read(profileRepositoryProvider)
          .createProfile(
            AppUser(
              id: user.id,
              displayName: displayName.trim(),
              email: user.email ?? '',
              photoUrl: user.photoUrl,
              bio: _blankToNull(bio),
              createdAt: now,
              updatedAt: now,
            ),
          );
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
