import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/circle_member.dart';
import 'circle_controller.dart';

class CircleMembersScreen extends ConsumerWidget {
  const CircleMembersScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(circleMembersProvider(circleId));
    final circle = ref.watch(circleProvider(circleId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return WarmScaffold(
      appBar: WarmAppBar(
        title: 'Circle Members',
        subtitle: 'Private invite list',
        leading: SoftIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          SoftIconButton(
            icon: Icons.person_add_alt_1_outlined,
            tooltip: 'Invite member',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: members.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No members yet',
              message: 'Invite people into this private Circle.',
            );
          }

          // Find the current user's membership record.
          final myMember = currentUserId == null
              ? null
              : items.where((m) => m.userId == currentUserId).firstOrNull;
          final isCreator = myMember?.role == CircleMemberRole.creator;
          final isLastMember = items.length == 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              circle.maybeWhen(
                data: (item) => item == null
                    ? const SizedBox.shrink()
                    : _InviteCard(
                        circleName: item.name,
                        inviteCode: item.inviteCode,
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              ...items.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WarmCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Avatar(
                          displayName: member.displayName,
                          photoUrl: member.photoUrl,
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.displayName,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                member.role.name == 'creator'
                                    ? 'Admin'
                                    : 'Member',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: member.role.name == 'creator'
                                          ? CirclePulseColors.clay
                                          : CirclePulseColors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (member.role.name == 'creator')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CirclePulseColors.cardAlt,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                color: CirclePulseColors.clay,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Member options',
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (myMember != null) ...[
                const SizedBox(height: 8),
                _LeaveCircleButton(
                  circleId: circleId,
                  isCreator: isCreator,
                  isLastMember: isLastMember,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Leave Circle button + dialogs ─────────────────────────────────────────────

class _LeaveCircleButton extends ConsumerWidget {
  const _LeaveCircleButton({
    required this.circleId,
    required this.isCreator,
    required this.isLastMember,
  });

  final String circleId;
  final bool isCreator;
  final bool isLastMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(circleControllerProvider);

    ref.listen(circleControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: controllerState.isLoading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.exit_to_app_outlined),
        label: Text(
          isCreator && isLastMember ? 'Delete Circle' : 'Leave Circle',
        ),
        onPressed: controllerState.isLoading
            ? null
            : () => _onTap(context, ref),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    if (isCreator && !isLastMember) {
      // Creator with other members: blocked, explain why.
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot leave yet'),
          content: const Text(
            "You created this Circle. You can't leave while other members are here.\n\n"
            'You can delete the Circle once everyone else has left, or ask another member to take over hosting in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    if (isCreator && isLastMember) {
      // Creator is the last member: offer to delete the Circle.
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Circle?'),
          content: const Text(
            "You're the only member left. Deleting will permanently remove this Circle and all its content.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(circleControllerProvider.notifier)
                    .deleteCircle(circleId);
                if (context.mounted &&
                    !ref.read(circleControllerProvider).hasError) {
                  context.go('/home');
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      return;
    }

    // Regular member: confirm leave.
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Circle?'),
        content: const Text(
          "You'll lose access to this Circle's messages, Pulses, and Plans.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(circleControllerProvider.notifier)
                  .leaveCircle(circleId);
              if (context.mounted &&
                  !ref.read(circleControllerProvider).hasError) {
                context.go('/home');
              }
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ── Invite code card ──────────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.circleName, required this.inviteCode});

  final String circleName;
  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invite to $circleName',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Share this code with others to invite them to your Circle.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: CirclePulseColors.muted),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CirclePulseColors.warmSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CirclePulseColors.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    inviteCode,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  onPressed: () {},
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Anyone with the code can join',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: CirclePulseColors.muted),
          ),
        ],
      ),
    );
  }
}
