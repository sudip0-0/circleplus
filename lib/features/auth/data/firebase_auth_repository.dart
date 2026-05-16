import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/domain/app_user.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/auth_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    required ProfileRepository profileRepository,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _profileRepository = profileRepository;

  final FirebaseAuth _firebaseAuth;
  final ProfileRepository _profileRepository;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<AuthUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Sign up completed without an authenticated user.');
    }

    await user.updateDisplayName(displayName.trim());
    final authUser = _mapUser(_firebaseAuth.currentUser) ?? _mapUser(user);
    if (authUser == null) {
      throw StateError('Unable to read signed-in user.');
    }

    final now = DateTime.now();
    await _profileRepository.createProfile(
      AppUser(
        id: authUser.id,
        displayName: displayName.trim(),
        email: authUser.email ?? email.trim(),
        photoUrl: authUser.photoUrl,
        bio: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return authUser;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Sign in completed without an authenticated user.');
    }
    return user;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
