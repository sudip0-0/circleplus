import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/circlepulse_ui.dart';
import '../../../pulses/presentation/pulse_controller.dart';

class CircleRoomMomentsPanel extends ConsumerWidget {
  const CircleRoomMomentsPanel({required this.circleId, super.key});

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
                          child: Semantics(
                            image: true,
                            label: 'Recent Pulse from ${pulse.userName}',
                            child: CachedNetworkImage(
                              imageUrl: pulse.photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: CirclePulseColors.cardAlt,
                                child: const Icon(Icons.image_outlined),
                              ),
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
