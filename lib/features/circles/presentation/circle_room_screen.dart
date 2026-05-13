import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
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
            onPressed: () => context.go('/circles/$circleId/members'),
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
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (item.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(item.description!),
                  ],
                  const SizedBox(height: 16),
                  SelectableText('Invite code: ${item.inviteCode}'),
                  const SizedBox(height: 24),
                  const Text(
                    'Messages, Pulses, and Plans will live here in the next MVP phases.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
