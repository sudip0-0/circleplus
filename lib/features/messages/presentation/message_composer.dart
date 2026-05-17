import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_compression.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        decoration: BoxDecoration(
          color: CirclePulseColors.cream.withValues(alpha: 0.88),
          border: const Border(
            top: BorderSide(color: CirclePulseColors.outline),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CirclePulseColors.warmSurface,
                shape: BoxShape.circle,
                border: Border.all(color: CirclePulseColors.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: 'Add photo',
                onPressed: state.isLoading ? null : _pickAndSendPhoto,
                icon: const Icon(Icons.photo_outlined),
                color: CirclePulseColors.cocoa,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CirclePulseColors.warmSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CirclePulseColors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CirclePulseColors.clay, CirclePulseColors.clayDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CirclePulseColors.clay.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SizedBox(
                width: 52,
                height: 52,
                child: IconButton(
                  tooltip: 'Send message',
                  color: Colors.white,
                  onPressed: state.isLoading ? null : _send,
                  icon: state.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
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
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final raw = await image.readAsBytes();
    final bytes = await compressImageBytes(raw);
    await ref
        .read(messageControllerProvider.notifier)
        .uploadPhotoMessage(
          circleId: widget.circleId,
          bytes: bytes,
          contentType: 'image/png',
          fileExtension: 'png',
          text: _controller.text,
        );
    if (!ref.read(messageControllerProvider).hasError) {
      _controller.clear();
    }
  }
}
