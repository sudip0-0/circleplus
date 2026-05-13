import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_text_field.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
              isLoading: controllerState.isLoading,
              onSave: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                await ref
                    .read(profileControllerProvider.notifier)
                    .createProfile(
                      displayName: _displayNameController.text,
                      bio: _bioController.text,
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
            isLoading: controllerState.isLoading,
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
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.displayNameController,
    required this.bioController,
    required this.isLoading,
    required this.onSave,
    required this.validateDisplayName,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final bool isLoading;
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
                  AppTextField(
                    controller: displayNameController,
                    label: 'Display name',
                    textInputAction: TextInputAction.next,
                    validator: validateDisplayName,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: bioController,
                    label: 'Bio',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : onSave,
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Profile'),
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
