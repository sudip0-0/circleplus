import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/circles/data/firebase_circle_repository.dart';
import '../features/circles/domain/circle_repository.dart';
import '../features/messages/data/firebase_message_repository.dart';
import '../features/messages/domain/message_repository.dart';
import '../features/plans/data/firebase_plan_repository.dart';
import '../features/plans/domain/plan_repository.dart';
import '../features/profile/data/firebase_profile_repository.dart';
import '../features/profile/domain/profile_repository.dart';
import '../features/pulses/data/firebase_pulse_repository.dart';
import '../features/pulses/domain/pulse_repository.dart';
import '../services/storage/storage_service.dart';

/// Concrete repository wiring. Presentation code should depend on the
/// domain interfaces exposed by these providers, not on Firebase classes.

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});

final circleRepositoryProvider = Provider<CircleRepository>((ref) {
  return FirebaseCircleRepository();
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FirebaseMessageRepository();
});

final pulseRepositoryProvider = Provider<PulseRepository>((ref) {
  return FirebasePulseRepository();
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirebasePlanRepository();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return R2PresignedUrlStorageService();
});
