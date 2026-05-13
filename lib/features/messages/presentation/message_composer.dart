import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/media_type.dart';
import 'message_controller.dart';

class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageControllerProvider);

    ref.listen(messageControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Add photo',
              onPressed: state.isLoading ? null : _pickAndSendPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Message this Circle',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: state.isLoading ? null : _send,
              icon: state.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    await ref
        .read(messageControllerProvider.notifier)
        .sendTextMessage(circleId: widget.circleId, text: text);
    if (!ref.read(messageControllerProvider).hasError) {
      _controller.clear();
    }
  }

  Future<void> _pickAndSendPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    await ref
        .read(messageControllerProvider.notifier)
        .uploadPhotoMessage(
          circleId: widget.circleId,
          bytes: bytes,
          contentType: imageContentTypeForName(image.name),
          fileExtension: fileExtensionForName(image.name),
          text: _controller.text,
        );
    if (!ref.read(messageControllerProvider).hasError) {
      _controller.clear();
    }
  }
}
