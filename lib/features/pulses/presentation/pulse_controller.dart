import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/app_user.dart';
import '../../profile/presentation/profile_providers.dart';
import '../../../services/storage/storage_service.dart';
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
    _logState('pulse.createOrUpdate', {'circleId': circleId});
  }

  Future<void> uploadPhotoAndCreatePulse({
    required String circleId,
    required List<int> bytes,
    required String contentType,
    required String fileExtension,
    required String? caption,
    required String? mood,
  }) async {
    final user = await _requireProfile();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final uploaded = await ref
          .read(storageServiceProvider)
          .uploadBytes(
            type: StorageUploadType.pulsePhoto,
            bytes: Uint8List.fromList(bytes),
            contentType: contentType,
            fileExtension: fileExtension,
            circleId: circleId,
          );
      await ref
          .read(pulseRepositoryProvider)
          .createOrUpdatePulse(
            circleId: circleId,
            user: user,
            photoUrl: uploaded.publicUrl,
            caption: caption,
            mood: mood,
          );
    });
    _logState('pulse.uploadAndCreate', {'circleId': circleId});
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

  void _logState(String event, [Map<String, Object?> details = const {}]) {
    if (state.hasError) {
      AppLogger.error(event, state.error!, details);
      return;
    }
    AppLogger.success(event, details);
  }
}
