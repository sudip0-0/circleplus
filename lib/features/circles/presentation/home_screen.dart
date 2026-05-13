import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../pulses/presentation/pulse_controller.dart';
import '../domain/circle.dart';
import 'circle_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _requestedNotifications = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedNotifications) {
      return;
    }
    _requestedNotifications = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(notificationControllerProvider.notifier)
          .requestPermissionAndSyncToken();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              return CircleCard(circle: items[index]);
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

class CircleCard extends StatelessWidget {
  const CircleCard({required this.circle, super.key});

  final CircleModel circle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/circles/${circle.id}'),
        title: Text(circle.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              circle.description?.isNotEmpty == true
                  ? circle.description!
                  : '${circle.memberCount} member${circle.memberCount == 1 ? '' : 's'}',
            ),
            const SizedBox(height: 4),
            _HomePulseProgress(circle: circle),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _HomePulseProgress extends ConsumerWidget {
  const _HomePulseProgress({required this.circle});

  final CircleModel circle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulses = ref.watch(todayPulsesProvider(circle.id));
    final myPulse = ref.watch(myTodayPulseProvider(circle.id));

    return pulses.when(
      loading: () => const Text('Checking today\'s Pulses...'),
      error: (error, stackTrace) => Text(
        'Pulse status unavailable',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (items) {
        final posted = myPulse.maybeWhen(
          data: (pulse) => pulse != null,
          orElse: () => false,
        );
        final total = circle.memberCount <= 0
            ? items.length
            : circle.memberCount;
        final status = posted ? 'You posted' : 'Post yours';
        return Text('Pulses today: ${items.length}/$total - $status');
      },
    );
  }
}
