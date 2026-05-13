import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'pulse_controller.dart';

class PulseWallScreen extends ConsumerWidget {
  const PulseWallScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulses = ref.watch(todayPulsesProvider(circleId));

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Pulses")),
      body: pulses.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Quiet so far',
              message: 'When friends post today, their Pulses will show here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pulse = items[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        pulse.photoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: pulse.userPhotoUrl != null
                                ? NetworkImage(pulse.userPhotoUrl!)
                                : null,
                            child: pulse.userPhotoUrl == null
                                ? Text(
                                    pulse.userName.isEmpty
                                        ? '?'
                                        : pulse.userName.characters.first
                                              .toUpperCase(),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pulse.userName,
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                                if (pulse.caption?.isNotEmpty == true)
                                  Text(
                                    pulse.caption!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                          if (pulse.mood?.isNotEmpty == true)
                            Chip(
                              label: Text(pulse.mood!),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
