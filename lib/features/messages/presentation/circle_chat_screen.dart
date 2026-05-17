import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../circles/presentation/circle_controller.dart';
import 'message_composer.dart';
import 'message_list.dart';

class CircleChatScreen extends ConsumerWidget {
  const CircleChatScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleProvider(circleId));

    return WarmScaffold(
      resizeToAvoidBottomInset: true,
      body: circle.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (item) {
          if (item == null) {
            return const ErrorView(message: 'Circle was not found.');
          }

          return Column(
            children: [
              _ChatHeader(
                title: item.name,
                subtitle: '${item.memberCount} members',
                coverUrl: item.coverUrl,
                onBack: () => context.pop(),
                onMembers: () => context.push('/circles/$circleId/members'),
              ),
              Expanded(
                child: MessageList(
                  circleId: circleId,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  showDayPill: true,
                ),
              ),
              MessageComposer(circleId: circleId),
            ],
          );
        },
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onMembers,
    this.coverUrl,
  });

  final String title;
  final String subtitle;
  final String? coverUrl;
  final VoidCallback onBack;
  final VoidCallback onMembers;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topPadding + 10, 12, 12),
      decoration: BoxDecoration(
        color: CirclePulseColors.cream.withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: CirclePulseColors.outline),
        ),
      ),
      child: Row(
        children: [
          SoftIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: 6),
          Avatar(displayName: title, photoUrl: coverUrl, radius: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CirclePulseColors.cocoa,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4C9F5A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CirclePulseColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Members',
            onPressed: onMembers,
            icon: const Icon(Icons.people_outline),
          ),
        ],
      ),
    );
  }
}
