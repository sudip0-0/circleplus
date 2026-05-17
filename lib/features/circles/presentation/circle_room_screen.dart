import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../plans/presentation/plan_controller.dart';
import '../../pulses/presentation/pulse_controller.dart';
import '../domain/circle.dart';
import '../domain/circle_member.dart';
import 'circle_controller.dart';

class CircleRoomScreen extends ConsumerWidget {
  const CircleRoomScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleProvider(circleId));

    return WarmScaffold(
      body: circle.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (item) {
          if (item == null) {
            return const ErrorView(message: 'Circle was not found.');
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _CircleHeader(
                  circle: item,
                  onBack: () => context.pop(),
                  onCopyInvite: () => _copyInviteCode(context, item.inviteCode),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                sliver: SliverList.list(
                  children: [
                    if (item.description?.trim().isNotEmpty == true) ...[
                      _DescriptionPanel(description: item.description!.trim()),
                      const SizedBox(height: 10),
                    ],
                    _PulseProgressPanel(circleId: circleId),
                    const SizedBox(height: 12),
                    _QuickActions(circleId: circleId),
                    const SizedBox(height: 12),
                    _MembersPreview(circleId: circleId),
                    const SizedBox(height: 12),
                    _UpcomingPlanPanel(circleId: circleId),
                    const SizedBox(height: 12),
                    _RecentMomentsPanel(circleId: circleId),
                    const SizedBox(height: 18),
                    _OpenChatButton(circleId: circleId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _copyInviteCode(BuildContext context, String inviteCode) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite code "$inviteCode" copied!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CircleHeader extends StatelessWidget {
  const _CircleHeader({
    required this.circle,
    required this.onBack,
    required this.onCopyInvite,
  });

  final CircleModel circle;
  final VoidCallback onBack;
  final VoidCallback onCopyInvite;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  circle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CirclePulseColors.cocoa,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SoftIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onPressed: onBack,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SoftIconButton(
                    icon: Icons.more_vert,
                    tooltip: 'Copy invite code',
                    onPressed: onCopyInvite,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${circle.memberCount} members',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CirclePulseColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 2.35,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CircleCover(circle: circle),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _HeroPill(
                          icon: Icons.lock_outline,
                          label: 'Private',
                          onTap: null,
                        ),
                        const SizedBox(width: 8),
                        _HeroPill(
                          label: circle.inviteCode,
                          onTap: onCopyInvite,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCover extends StatelessWidget {
  const _CircleCover({required this.circle});

  final CircleModel circle;

  @override
  Widget build(BuildContext context) {
    if (circle.coverUrl != null && circle.coverUrl!.isNotEmpty) {
      return Image.network(
        circle.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _GeneratedCircleCover(name: circle.name),
      );
    }
    return _GeneratedCircleCover(name: circle.name);
  }
}

class _GeneratedCircleCover extends StatelessWidget {
  const _GeneratedCircleCover({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7A36D), Color(0xFFC86650), Color(0xFF6D6F46)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 34,
            right: 34,
            bottom: 32,
            child: Container(
              height: 2,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Center(
            child: Icon(
              Icons.groups_2_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: CirclePulseColors.warmSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: CirclePulseColors.cocoa),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: CirclePulseColors.cocoa,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: content,
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CirclePulseColors.cardAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: CirclePulseColors.olive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CirclePulseColors.cocoa,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseProgressPanel extends ConsumerWidget {
  const _PulseProgressPanel({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleProvider(circleId));
    final pulses = ref.watch(todayPulsesProvider(circleId));

    final memberCount = circle.asData?.value?.memberCount ?? 0;

    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: pulses.when(
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 12),
            Text("Loading today's Pulse progress..."),
          ],
        ),
        error: (error, stackTrace) => Text(
          'Could not load Pulse progress.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        data: (items) {
          final posted = items.length;
          final total = memberCount == 0 ? posted : memberCount;
          final progress = total == 0 ? 0.0 : (posted / total).clamp(0.0, 1.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Pulse progress",
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '$posted of $total posted',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: CirclePulseColors.outline,
                  color: CirclePulseColors.clay,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.96,
      children: [
        _ActionTile(
          icon: Icons.photo_library_outlined,
          label: 'Pulse Wall',
          onTap: () => context.push('/circles/$circleId/pulses'),
        ),
        _ActionTile(
          icon: Icons.people_outline,
          label: 'Members',
          onTap: () => context.push('/circles/$circleId/members'),
        ),
        _ActionTile(
          icon: Icons.calendar_month_outlined,
          label: 'New Plan',
          onTap: () => context.push('/circles/$circleId/plans/create'),
        ),
        _ActionTile(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Invite',
          onTap: () => context.push('/circles/$circleId/members'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: CirclePulseColors.card.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CirclePulseColors.outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: CirclePulseColors.clay, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: CirclePulseColors.cocoa,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersPreview extends ConsumerWidget {
  const _MembersPreview({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(circleMembersProvider(circleId));

    return WarmCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: members.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => Text(
          'Could not load members.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        data: (items) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AvatarStack(members: items.take(6).toList()),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/circles/$circleId/members'),
                child: const Text('View all'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<CircleMemberModel> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Text(
        'No members yet',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: CirclePulseColors.muted),
      );
    }

    return SizedBox(
      height: 34,
      child: Stack(
        children: [
          for (var index = 0; index < members.length; index++)
            Positioned(
              left: index * 24,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CirclePulseColors.card, width: 2),
                ),
                child: Avatar(
                  displayName: members[index].displayName,
                  photoUrl: members[index].photoUrl,
                  radius: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingPlanPanel extends ConsumerWidget {
  const _UpcomingPlanPanel({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(activePlansProvider(circleId));

    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: plans.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stackTrace) => Text(
          'Could not load upcoming Plans.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Row(
              children: [
                const _PlanIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No upcoming Plans yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.push('/circles/$circleId/plans/create'),
                  child: const Text('Create'),
                ),
              ],
            );
          }

          final plan = [...items]
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          final nextPlan = plan.first;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                context.push('/circles/$circleId/plans/${nextPlan.id}'),
            child: Row(
              children: [
                const _PlanIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Plan',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: CirclePulseColors.clay,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextPlan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _MetaIconText(
                            icon: Icons.schedule,
                            label: DateFormat.MMMEd().add_jm().format(
                              nextPlan.startsAt,
                            ),
                          ),
                          if (nextPlan.location?.isNotEmpty == true)
                            _MetaIconText(
                              icon: Icons.place_outlined,
                              label: nextPlan.location!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CirclePulseColors.cardAlt,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.calendar_month_outlined,
        color: CirclePulseColors.clay,
      ),
    );
  }
}

class _MetaIconText extends StatelessWidget {
  const _MetaIconText({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CirclePulseColors.clay),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: CirclePulseColors.muted),
        ),
      ],
    );
  }
}

class _RecentMomentsPanel extends ConsumerWidget {
  const _RecentMomentsPanel({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulses = ref.watch(todayPulsesProvider(circleId));

    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent shared moments',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          pulses.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text(
              'Could not load moments.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  'No Pulse photos yet today.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CirclePulseColors.muted,
                  ),
                );
              }

              return Row(
                children: items.take(3).map((pulse) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1.55,
                          child: Image.network(
                            pulse.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: CirclePulseColors.cardAlt,
                                  child: const Icon(Icons.image_outlined),
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OpenChatButton extends StatelessWidget {
  const _OpenChatButton({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return PrimaryGradientButton(
      label: 'Open Circle Chat',
      icon: Icons.chat_bubble_outline,
      onPressed: () => context.push('/circles/$circleId/chat'),
    );
  }
}
