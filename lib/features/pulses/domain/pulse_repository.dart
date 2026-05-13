import '../../profile/domain/app_user.dart';
import 'pulse.dart';

abstract interface class PulseRepository {
  Stream<List<PulseModel>> watchTodayPulses(String circleId);

  Stream<PulseModel?> watchMyTodayPulse({
    required String circleId,
    required String userId,
  });

  Future<void> createOrUpdatePulse({
    required String circleId,
    required AppUser user,
    required String photoUrl,
    required String? caption,
    required String? mood,
  });
}
