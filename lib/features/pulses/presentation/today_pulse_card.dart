import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'pulse_controller.dart';

class TodayPulseCard extends ConsumerWidget {
  const TodayPulseCard({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulses = ref.watch(todayPulsesProvider(circleId));
    final myPulse = ref.watch(myTodayPulseProvider(circleId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: pulses.when(
          loading: () => const SizedBox(height: 72, child: LoadingView()),
          error: (error, stackTrace) => ErrorView(message: error.toString()),
          data: (items) {
            final posted = myPulse.maybeWhen(
              data: (pulse) => pulse != null,
              orElse: () => false,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Today's Pulses",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/circles/$circleId/pulses'),
                      child: const Text('View'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  items.isEmpty
                      ? 'No one has posted yet today.'
                      : '${items.length} posted today.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/circles/$circleId/pulse/create'),
                  icon: Icon(posted ? Icons.edit_outlined : Icons.add_a_photo),
                  label: Text(posted ? 'Update Pulse' : 'Post Pulse'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
