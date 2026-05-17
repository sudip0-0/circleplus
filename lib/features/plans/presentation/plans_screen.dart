import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/plan.dart';
import 'plan_card.dart';
import 'plan_controller.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(allPlansProvider(circleId));

    return WarmScaffold(
      appBar: WarmAppBar(
        title: 'Plans',
        subtitle: 'Every meetup idea for this Circle',
        actions: [
          SoftIconButton(
            icon: Icons.add,
            tooltip: 'Create Plan',
            onPressed: () => context.push('/circles/$circleId/plans/create'),
          ),
        ],
      ),
      body: plans.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) =>
            ErrorView(message: 'Could not load Plans: $error'),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No Plans yet',
              message: 'Create the first Plan when your Circle is ready.',
              actions: [
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/circles/$circleId/plans/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Plan'),
                ),
              ],
            );
          }

          final now = DateTime.now();
          final upcoming =
              items
                  .where(
                    (plan) =>
                        plan.status == PlanStatus.active &&
                        !plan.startsAt.isBefore(now),
                  )
                  .toList()
                ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          final previous =
              items
                  .where(
                    (plan) =>
                        plan.status != PlanStatus.active ||
                        plan.startsAt.isBefore(now),
                  )
                  .toList()
                ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _SectionHeader(title: 'Upcoming'),
                const SizedBox(height: 10),
                for (final plan in upcoming) PlanCard(plan: plan),
              ],
              if (previous.isNotEmpty) ...[
                if (upcoming.isNotEmpty) const SizedBox(height: 12),
                const _SectionHeader(title: 'Earlier'),
                const SizedBox(height: 10),
                for (final plan in previous) PlanCard(plan: plan),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/circles/$circleId/plans/create'),
        icon: const Icon(Icons.add),
        label: const Text('Plan'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: CirclePulseColors.cocoa,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
