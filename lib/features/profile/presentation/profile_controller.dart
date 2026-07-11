import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../services/storage/storage_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/app_user.dart';

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
    Uint8List? avatarBytes,
    String? avatarContentType,
    String? avatarFileExtension,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final photoUrl = await _uploadAvatarIfNeeded(
        avatarBytes: avatarBytes,
        contentType: avatarContentType,
        fileExtension: avatarFileExtension,
      );
      final updated = AppUser(
        id: currentProfile.id,
        displayName: displayName.trim(),
        email: currentProfile.email,
        photoUrl: photoUrl ?? currentProfile.photoUrl,
        bio: _blankToNull(bio),
        createdAt: currentProfile.createdAt,
        updatedAt: DateTime.now(),
      );
      await ref.read(profileRepositoryProvider).updateProfile(updated);
    });
  }

  Future<void> createProfile({
    required String displayName,
    required String? bio,
    Uint8List? avatarBytes,
    String? avatarContentType,
    String? avatarFileExtension,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw StateError('You must be signed in.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      final photoUrl = await _uploadAvatarIfNeeded(
        avatarBytes: avatarBytes,
        contentType: avatarContentType,
        fileExtension: avatarFileExtension,
      );
      await ref
          .read(profileRepositoryProvider)
          .createProfile(
            AppUser(
              id: user.id,
              displayName: displayName.trim(),
              email: user.email ?? '',
              photoUrl: photoUrl ?? user.photoUrl,
              bio: _blankToNull(bio),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  Future<String?> _uploadAvatarIfNeeded({
    required Uint8List? avatarBytes,
    required String? contentType,
    required String? fileExtension,
  }) async {
    if (avatarBytes == null) {
      return null;
    }
    return ref
        .read(storageServiceProvider)
        .uploadBytes(
          type: StorageUploadType.avatar,
          bytes: avatarBytes,
          contentType: contentType ?? 'image/jpeg',
          fileExtension: fileExtension ?? 'jpg',
        )
        .then((uploaded) => uploaded.objectKey);
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
