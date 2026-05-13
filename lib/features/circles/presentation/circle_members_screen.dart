import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'circle_controller.dart';

class CircleMembersScreen extends ConsumerWidget {
  const CircleMembersScreen({required this.circleId, super.key});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(circleMembersProvider(circleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: members.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No members yet',
              message: 'Invite people into this private Circle.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    member.displayName.isEmpty
                        ? '?'
                        : member.displayName.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(member.role.name),
              );
            },
          );
        },
      ),
    );
  }
}
