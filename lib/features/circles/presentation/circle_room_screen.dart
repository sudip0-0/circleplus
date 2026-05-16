import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
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

    return WarmScaffold(
      appBar: WarmAppBar(
        title: 'Circle',
        subtitle: 'Private space',
        leading: SoftIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        actions: [
          SoftIconButton(
            tooltip: 'Create Plan',
            onPressed: () => context.push('/circles/$circleId/plans/create'),
            icon: Icons.event_available_outlined,
          ),
          SoftIconButton(
            tooltip: 'Members',
            onPressed: () => context.push('/circles/$circleId/members'),
            icon: Icons.people_outline,
          ),
          const SizedBox(width: 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  children: [
                    WarmCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Avatar(displayName: item.name, radius: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '${item.memberCount} members',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: CirclePulseColors.muted,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy invite code',
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: item.inviteCode),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invite code "${item.inviteCode}" copied!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TodayPulseCard(circleId: circleId),
                    const SizedBox(height: 12),
                    _PlansPreview(circleId: circleId),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Messages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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

    return WarmCard(
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    );
  }
}
