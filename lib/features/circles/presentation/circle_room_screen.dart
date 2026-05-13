import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../messages/presentation/message_composer.dart';
import '../../messages/presentation/message_list.dart';
import '../../plans/presentation/plan_card.dart';
import '../../plans/presentation/plan_controller.dart';
import '../../pulses/presentation/today_pulse_card.dart';
import 'circle_controller.dart';

class CircleRoomScreen extends ConsumerWidget {
  const CircleRoomScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleProvider(circleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle'),
        actions: [
          IconButton(
            tooltip: 'Members',
            onPressed: () => context.push('/circles/$circleId/members'),
            icon: const Icon(Icons.people_outline),
          ),
        ],
      ),
      body: circle.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (item) {
          if (item == null) {
            return const ErrorView(message: 'Circle was not found.');
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (item.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(item.description!),
                    ],
                    const SizedBox(height: 8),
                    SelectableText('Invite code: ${item.inviteCode}'),
                    const SizedBox(height: 12),
                    TodayPulseCard(circleId: circleId),
                    const SizedBox(height: 12),
                    _PlansPreview(circleId: circleId),
                    const SizedBox(height: 12),
                    Text(
                      'Messages',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(
                      height: 360,
                      child: MessageList(circleId: circleId),
                    ),
                  ],
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

class _PlansPreview extends ConsumerWidget {
  const _PlansPreview({required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(activePlansProvider(circleId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Plans',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      context.push('/circles/$circleId/plans/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            plans.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(
                'Could not load plans. Please try again later.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No active Plans yet.');
                }
                return Column(
                  children: items.take(2).map((plan) {
                    return PlanCard(plan: plan);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
