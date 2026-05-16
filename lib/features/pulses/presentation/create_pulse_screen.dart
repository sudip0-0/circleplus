import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_compression.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
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
  // Compressed bytes ready for upload; also used as the preview source.
  Uint8List? _compressedBytes;

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

    return WarmScaffold(
      appBar: WarmAppBar(
        leading: SoftIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Pulse',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share one moment from your day.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CirclePulseColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AspectRatio(
                    aspectRatio: 1.08,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: CirclePulseColors.cardAlt,
                              border: Border.all(
                                color: CirclePulseColors.outline,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: _compressedBytes == null
                                ? const Center(
                                    child: Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 58,
                                      color: CirclePulseColors.clay,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.memory(
                                      _compressedBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 18,
                          bottom: 18,
                          child: IconButton.filled(
                            tooltip: 'Choose photo',
                            onPressed: state.isLoading ? null : _pickImage,
                            icon: const Icon(Icons.photo_camera_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: CirclePulseColors.clay,
                              foregroundColor: Colors.white,
                              fixedSize: const Size.square(58),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppTextField(
                    controller: _captionController,
                    label: 'Add a caption (optional)',
                    hintText: 'Slow morning, warm coffee...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _moodController,
                    label: 'Mood (optional)',
                    hintText: 'cozy, grateful, excited',
                    prefixIcon: Icons.auto_awesome,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  const SoftInfoPanel(
                    icon: Icons.eco_outlined,
                    title: 'Visible to your Circle',
                    message: 'Your Pulse helps keep everyone connected today.',
                  ),
                  const SizedBox(height: 18),
                  PrimaryGradientButton(
                    label: 'Post Pulse',
                    icon: Icons.cloud_upload_outlined,
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : _submit,
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
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    final raw = await image.readAsBytes();
    // Compress off the UI thread before storing; the same bytes are used for
    // the preview and the upload so we never compress twice.
    final compressed = await compressImageBytes(raw);
    setState(() {
      _compressedBytes = compressed;
    });
  }

  Future<void> _submit() async {
    final bytes = _compressedBytes;
    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a photo first.')));
      return;
    }

    await ref
        .read(pulseControllerProvider.notifier)
        .uploadPhotoAndCreatePulse(
          circleId: widget.circleId,
          bytes: bytes,
          contentType: 'image/png',
          fileExtension: 'png',
          caption: _captionController.text,
          mood: _moodController.text,
        );

    if (mounted && !ref.read(pulseControllerProvider).hasError) {
      context.pushReplacement('/circles/${widget.circleId}/pulses');
    }
  }
}
