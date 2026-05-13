import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_view.dart';
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
          loading: () => const _PulseLoadingState(),
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
                      onPressed: () =>
                          context.push('/circles/$circleId/pulses'),
                      child: const Text('View'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text('No one has posted yet today.')
                else ...[
                  Text('${items.length} posted today.'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final pulse = items[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            pulse.photoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 56,
                                  height: 56,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 24,
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/circles/$circleId/pulse/create'),
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

class _PulseLoadingState extends StatelessWidget {
  const _PulseLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(),
        SizedBox(height: 12),
        Text("Loading today's Pulses..."),
      ],
    );
  }
}
