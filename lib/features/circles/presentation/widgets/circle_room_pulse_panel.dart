import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/circlepulse_ui.dart';
import '../../../pulses/presentation/pulse_controller.dart';
import '../circle_controller.dart';

class CircleRoomPulsePanel extends ConsumerWidget {
  const CircleRoomPulsePanel({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circle = ref.watch(circleProvider(circleId));
    final pulses = ref.watch(todayPulsesProvider(circleId));
    final myPulse = ref.watch(myTodayPulseProvider(circleId));

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
          final hasPosted = myPulse.maybeWhen(
            data: (pulse) => pulse != null,
            orElse: () => false,
          );

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
              const SizedBox(height: 14),
              PrimaryGradientButton(
                label: hasPosted ? 'Update Pulse' : 'Add Pulse',
                icon: hasPosted ? Icons.edit_outlined : Icons.add_a_photo,
                onPressed: () =>
                    context.push('/circles/$circleId/pulse/create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
