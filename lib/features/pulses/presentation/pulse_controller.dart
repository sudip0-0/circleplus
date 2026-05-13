import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/firebase_pulse_repository.dart';
import '../domain/pulse.dart';
import '../domain/pulse_repository.dart';

final pulseRepositoryProvider = Provider<PulseRepository>((ref) {
  return FirebasePulseRepository();
});

final todayPulsesProvider = StreamProvider.family<List<PulseModel>, String>((
  ref,
  circleId,
) {
  return ref.watch(pulseRepositoryProvider).watchTodayPulses(circleId);
});

final myTodayPulseProvider = StreamProvider.family<PulseModel?, String>((
  ref,
  circleId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<PulseModel?>.value(null);
  }
  return ref
      .watch(pulseRepositoryProvider)
      .watchMyTodayPulse(circleId: circleId, userId: user.id);
});

final pulseControllerProvider = AsyncNotifierProvider<PulseController, void>(
  PulseController.new,
);

class PulseController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createOrUpdatePulse({
    required String circleId,
    required String photoUrl,
    required String? caption,
    required String? mood,
  }) async {
    final user = await _requireProfile();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(pulseRepositoryProvider)
          .createOrUpdatePulse(
            circleId: circleId,
            user: user,
            photoUrl: photoUrl,
            caption: caption,
            mood: mood,
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
      throw StateError('Create your profile before posting a Pulse.');
    }
    return profile;
  }
}
