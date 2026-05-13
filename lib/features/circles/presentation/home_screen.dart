import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/circle.dart';
import 'circle_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circles = ref.watch(userCirclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CirclePulse'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: circles.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No Circles yet',
              message:
                  'Create your first Circle and invite the people who matter.',
              actions: _homeActions(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _CircleCard(circle: items[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/circles/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Circle'),
      ),
    );
  }

  List<Widget> _homeActions(BuildContext context) {
    return [
      FilledButton.icon(
        onPressed: () => context.push('/circles/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Circle'),
      ),
      OutlinedButton.icon(
        onPressed: () => context.push('/circles/join'),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Join with Code'),
      ),
    ];
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});

  final CircleModel circle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/circles/${circle.id}'),
        title: Text(circle.name),
        subtitle: Text(
          circle.description?.isNotEmpty == true
              ? circle.description!
              : '${circle.memberCount} member${circle.memberCount == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
