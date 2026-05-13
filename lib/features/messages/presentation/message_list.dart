import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/message.dart';
import 'message_controller.dart';

class MessageList extends ConsumerWidget {
  const MessageList({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(circleMessagesProvider(circleId));
    final currentUser = ref.watch(currentUserProvider);

    return messages.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => ErrorView(message: error.toString()),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            title: 'No messages yet',
            message: 'Start the conversation inside this Circle.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final message = items[index];
            return _MessageBubble(
              message: message,
              isMine: message.senderId == currentUser?.id,
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              Avatar(
                displayName: message.senderName,
                photoUrl: message.senderPhotoUrl,
                radius: 14,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? CirclePulseColors.cardAlt
                      : CirclePulseColors.warmSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                  border: Border.all(color: CirclePulseColors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMine) ...[
                        Text(
                          message.senderName,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (message.mediaUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.mediaUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) {
                                return child;
                              }
                              return const SizedBox(
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 160,
                                child: Center(child: Icon(Icons.broken_image)),
                              );
                            },
                          ),
                        ),
                        if (message.text?.isNotEmpty == true)
                          const SizedBox(height: 8),
                      ],
                      if (message.text?.isNotEmpty == true) Text(message.text!),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          time.format(context),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: CirclePulseColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
