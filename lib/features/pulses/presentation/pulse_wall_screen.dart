import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/resolved_network_image.dart';
import 'pulse_controller.dart';

class PulseWallScreen extends ConsumerWidget {
  const PulseWallScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulses = ref.watch(todayPulsesProvider(circleId));

    return WarmScaffold(
      appBar: const WarmAppBar(
        title: "Today's Pulses",
        subtitle: "See what's happening in your Circle",
      ),
      body: pulses.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(todayPulsesProvider(circleId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Quiet so far',
              message: 'When friends post today, their Pulses will show here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final pulse = items[index];
              return WarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: ResolvedNetworkImage(
                          storageRef: pulse.photoUrl,
                          circleId: circleId,
                          fit: BoxFit.cover,
                          semanticLabel: pulse.caption?.isNotEmpty == true
                              ? 'Pulse photo from ${pulse.userName}: ${pulse.caption}'
                              : 'Pulse photo from ${pulse.userName}',
                          placeholder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (_) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          ),
                        ),
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
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (pulse.caption?.isNotEmpty == true)
                                  Text(
                                    pulse.caption!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
