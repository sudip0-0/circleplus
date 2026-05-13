import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> signOut();
}
