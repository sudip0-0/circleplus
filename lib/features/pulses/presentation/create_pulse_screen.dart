import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/media_type.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'pulse_controller.dart';

class CreatePulseScreen extends ConsumerStatefulWidget {
  const CreatePulseScreen({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<CreatePulseScreen> createState() => _CreatePulseScreenState();
}

class _CreatePulseScreenState extends ConsumerState<CreatePulseScreen> {
  final _captionController = TextEditingController();
  final _moodController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _previewBytes;

  @override
  void dispose() {
    _captionController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pulseControllerProvider);

    ref.listen(pulseControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Post Pulse')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _previewBytes == null
                          ? const Center(
                              child: Icon(Icons.add_a_photo_outlined, size: 48),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _previewBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: state.isLoading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Photo'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _captionController,
                    label: 'Caption',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _moodController,
                    label: 'Mood',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: state.isLoading ? null : _submit,
                    icon: state.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Post Pulse'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = image;
      _previewBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final image = _selectedImage;
    if (image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a photo first.')));
      return;
    }

    final bytes = await image.readAsBytes();
    await ref
        .read(pulseControllerProvider.notifier)
        .uploadPhotoAndCreatePulse(
          circleId: widget.circleId,
          bytes: bytes,
          contentType: imageContentTypeForName(image.name),
          fileExtension: fileExtensionForName(image.name),
          caption: _captionController.text,
          mood: _moodController.text,
        );

    if (mounted && !ref.read(pulseControllerProvider).hasError) {
      context.pushReplacement('/circles/${widget.circleId}/pulses');
    }
  }
}
