import 'app_user.dart';

abstract interface class ProfileRepository {
  Stream<AppUser?> watchProfile(String userId);

  Future<AppUser?> getProfile(String userId);

  Future<void> createProfile(AppUser user);

  Future<void> updateProfile(AppUser user);
}
