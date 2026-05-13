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
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pulse = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      pulse.userName.isEmpty
                          ? '?'
                          : pulse.userName.characters.first.toUpperCase(),
                    ),
                  ),
                  title: Text(pulse.userName),
                  subtitle: Text(
                    [
                      if (pulse.caption?.isNotEmpty == true) pulse.caption!,
                      if (pulse.mood?.isNotEmpty == true) pulse.mood!,
                    ].join('\n'),
                  ),
                  trailing: const Icon(Icons.image_outlined),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
