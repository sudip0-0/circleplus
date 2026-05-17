import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_compression.dart';
import '../../../core/utils/media_type.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _avatarBytes;
  String? _avatarFileName;
  bool _seeded = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    ref.listen(profileControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return WarmScaffold(
      appBar: WarmAppBar(
        leading: SoftIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (user) {
          if (user == null) {
            final authUser = ref.watch(currentUserProvider);
            if (authUser == null) {
              return const ErrorView(message: 'You must be signed in.');
            }
            if (!_seeded) {
              _displayNameController.text = authUser.displayName ?? '';
              _seeded = true;
            }
            return _ProfileForm(
              formKey: _formKey,
              displayNameController: _displayNameController,
              bioController: _bioController,
              avatarBytes: _avatarBytes,
              photoUrl: authUser.photoUrl,
              isLoading: controllerState.isLoading,
              onPickAvatar: _pickAvatar,
              onSave: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                await ref
                    .read(profileControllerProvider.notifier)
                    .createProfile(
                      displayName: _displayNameController.text,
                      bio: _bioController.text,
                      avatarBytes: _avatarBytes,
                      avatarContentType: imageContentTypeForName(
                        _avatarFileName,
                      ),
                      avatarFileExtension: fileExtensionForName(
                        _avatarFileName,
                      ),
                    );
                if (context.mounted &&
                    !ref.read(profileControllerProvider).hasError) {
                  context.go('/home');
                }
              },
              validateDisplayName: _validateDisplayName,
            );
          }
          if (!_seeded) {
            _displayNameController.text = user.displayName;
            _bioController.text = user.bio ?? '';
            _seeded = true;
          }

          return _ProfileForm(
            formKey: _formKey,
            displayNameController: _displayNameController,
            bioController: _bioController,
            avatarBytes: _avatarBytes,
            photoUrl: user.photoUrl,
            isLoading: controllerState.isLoading,
            onPickAvatar: _pickAvatar,
            onSave: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }
              await ref
                  .read(profileControllerProvider.notifier)
                  .updateProfile(
                    currentProfile: user,
                    displayName: _displayNameController.text,
                    bio: _bioController.text,
                    avatarBytes: _avatarBytes,
                    avatarContentType: imageContentTypeForName(_avatarFileName),
                    avatarFileExtension: fileExtensionForName(_avatarFileName),
                  );
              if (context.mounted &&
                  !ref.read(profileControllerProvider).hasError) {
                context.go('/home');
              }
            },
            validateDisplayName: _validateDisplayName,
          );
        },
      ),
    );
  }

  String? _validateDisplayName(String? value) {
    if ((value?.trim() ?? '').length < 2) {
      return 'Display name must be at least 2 characters.';
    }
    return null;
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final raw = await image.readAsBytes();
    final compressed = await compressImageBytes(raw);
    setState(() {
      _avatarBytes = compressed;
      _avatarFileName = 'avatar.jpg';
    });
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.displayNameController,
    required this.bioController,
    required this.avatarBytes,
    required this.photoUrl,
    required this.isLoading,
    required this.onPickAvatar,
    required this.onSave,
    required this.validateDisplayName,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final Uint8List? avatarBytes;
  final String? photoUrl;
  final bool isLoading;
  final VoidCallback onPickAvatar;
  final Future<void> Function() onSave;
  final String? Function(String?) validateDisplayName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Make your profile feel like you',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: CirclePulseColors.cocoa,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps your circle get to know you better.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CirclePulseColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (avatarBytes != null)
                          CircleAvatar(
                            radius: 58,
                            backgroundImage: MemoryImage(avatarBytes!),
                          )
                        else
                          Avatar(
                            displayName: displayNameController.text,
                            photoUrl: photoUrl,
                            radius: 58,
                          ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: IconButton.filled(
                            tooltip: 'Choose avatar',
                            onPressed: isLoading ? null : onPickAvatar,
                            icon: const Icon(Icons.photo_camera_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  WarmCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: displayNameController,
                          label: 'Display name',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: validateDisplayName,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: bioController,
                          label: 'Bio',
                          prefixIcon: Icons.chat_bubble_outline,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: 'Email address',
                          enabled: false,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline),
                            suffixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryGradientButton(
                          label: 'Save Profile',
                          icon: Icons.check,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : onSave,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
