import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../core/utils/date_key.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../pulses/presentation/pulse_controller.dart';
import '../domain/circle.dart';
import 'circle_controller.dart';

int _todayPulsePostedCount(CircleModel circle) {
  final today = pulseDateKey(DateTime.now());
  if (circle.todayPulseDateKey == today) {
    return circle.todayPulseCount;
  }
  return 0;
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(userCirclesProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return WarmScaffold(
      appBar: WarmAppBar(
        title: 'CirclePulse',
        actions: [
          SoftIconButton(
            tooltip: 'Edit profile',
            onPressed: () => context.push('/profile/edit'),
            icon: Icons.person_outline,
          ),
          SoftIconButton(
            tooltip: 'Sign out',
            onPressed: authState.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            icon: Icons.logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: circles.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userCirclesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No Circles yet',
              message:
                  'Create your first Circle and invite the people who matter.',
              actions: _homeActions(context),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final horizontal = wide ? 48.0 : 20.0;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 112),
                    children: [
                      Text(
                        _greeting(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: CirclePulseColors.cocoa,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "So glad you're here.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CirclePulseColors.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _OverallPulseProgress(circles: items),
                      const SizedBox(height: 24),
                      Text(
                        'My Circles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...items.map(
                        (circle) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CircleCard(circle: circle),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: PrimaryGradientButton(
            label: 'Create or Join a Circle',
            icon: Icons.add,
            onPressed: () => _showCircleActions(context),
          ),
        ),
      ),
    );
  }

  void _showCircleActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _homeActions(context),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _homeActions(BuildContext context) {
    return [
      FilledButton.icon(
        onPressed: () => context.push('/circles/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Circle'),
      ),
      OutlinedButton.icon(
        onPressed: () => context.push('/circles/join'),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Join with Code'),
      ),
    ];
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class CircleCard extends StatelessWidget {
  const CircleCard({required this.circle, super.key});

  final CircleModel circle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open Circle ${circle.name}',
      child: WarmCard(
        onTap: () => context.push('/circles/${circle.id}'),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _CircleCover(circle: circle, size: 58),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          circle.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: CirclePulseColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${circle.memberCount} member${circle.memberCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CirclePulseColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    circle.lastMessageText?.isNotEmpty == true
                        ? circle.lastMessageText!
                        : (circle.description?.isNotEmpty == true
                              ? circle.description!
                              : 'No messages yet'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HomePulseProgress(circle: circle),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right,
                  color: CirclePulseColors.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleCover extends StatelessWidget {
  const _CircleCover({required this.circle, this.size = 48});

  final CircleModel circle;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (circle.coverUrl?.isNotEmpty == true) {
      return ClipOval(
        child: Image.network(
          circle.coverUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _FallbackCircleCover(circle: circle, size: size),
        ),
      );
    }
    return _FallbackCircleCover(circle: circle, size: size);
  }
}

class _FallbackCircleCover extends StatelessWidget {
  const _FallbackCircleCover({required this.circle, required this.size});

  final CircleModel circle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFD9C3), Color(0xFFEAA071)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        circle.name.trim().isEmpty
            ? '?'
            : circle.name.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OverallPulseProgress extends ConsumerWidget {
  const _OverallPulseProgress({required this.circles});

  final List<CircleModel> circles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = circles.fold<int>(
      0,
      (sum, circle) => sum + circle.memberCount,
    );
    final total = members == 0 ? circles.length : members;
    final posted = circles.fold<int>(
      0,
      (sum, circle) => sum + _todayPulsePostedCount(circle),
    );

    final progress = total == 0 ? 0.0 : posted / total;

    return WarmCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Pulse progress",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$posted of $total members posted'),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: CirclePulseColors.outline,
                    color: CirclePulseColors.clay,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Icon(
            Icons.local_fire_department,
            color: CirclePulseColors.clay,
          ),
        ],
      ),
    );
  }
}

class _HomePulseProgress extends ConsumerWidget {
  const _HomePulseProgress({required this.circle});

  final CircleModel circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPulse = ref.watch(myTodayPulseProvider(circle.id));
    final postedCount = _todayPulsePostedCount(circle);
    final total = circle.memberCount <= 0 ? postedCount : circle.memberCount;
    final posted = myPulse.maybeWhen(
      data: (pulse) => pulse != null,
      orElse: () => false,
    );
    final status = posted ? Icons.favorite : Icons.add_a_photo_outlined;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status, size: 16, color: CirclePulseColors.clay),
        const SizedBox(width: 3),
        Text(
          '$postedCount/$total',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: CirclePulseColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
