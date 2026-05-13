import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref
          .watch(authStateProvider)
          .maybeWhen(data: (user) => user, orElse: () => null) ??
      ref.watch(authRepositoryProvider).currentUser;
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(authRepositoryProvider)
          .signUp(displayName: displayName, email: email, password: password);
    });
    _logState('auth.signUp');
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
    });
    _logState('auth.signIn');
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(authRepositoryProvider).signOut);
    _logState('auth.signOut');
  }

  void _logState(String event) {
    if (state.hasError) {
      AppLogger.error(event, state.error!);
      return;
    }
    AppLogger.success(event);
  }
}
