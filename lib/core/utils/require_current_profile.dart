import '../../features/profile/domain/app_user.dart';
import '../../features/profile/domain/profile_repository.dart';

/// Loads the signed-in user's profile or throws a consistent error.
Future<AppUser> requireCurrentProfile({
  required ProfileRepository profileRepository,
  required String userId,
}) async {
  final profile = await profileRepository.getProfile(userId);
  if (profile == null) {
    throw StateError('Complete your profile before continuing.');
  }
  return profile;
}
