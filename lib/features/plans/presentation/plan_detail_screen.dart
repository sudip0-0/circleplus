import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/plan_response.dart';
import 'plan_controller.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({
    required this.circleId,
    required this.planId,
    super.key,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (circleId: circleId, planId: planId);
    final plan = ref.watch(planProvider(args));
    final responses = ref.watch(planResponsesProvider(args));
    final controllerState = ref.watch(planControllerProvider);

    ref.listen(planControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: plan.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (item) {
          if (item == null) {
            return const ErrorView(message: 'Plan was not found.');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(DateFormat.yMMMd().add_jm().format(item.startsAt)),
              if (item.location?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(item.location!),
              ],
              if (item.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(item.description!),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('${item.inCount} in')),
                  Chip(label: Text('${item.maybeCount} maybe')),
                  Chip(label: Text("${item.cantCount} can't")),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<PlanResponseValue>(
                segments: const [
                  ButtonSegment(
                    value: PlanResponseValue.in_,
                    label: Text('In'),
                    icon: Icon(Icons.check),
                  ),
                  ButtonSegment(
                    value: PlanResponseValue.maybe,
                    label: Text('Maybe'),
                    icon: Icon(Icons.help_outline),
                  ),
                  ButtonSegment(
                    value: PlanResponseValue.cant,
                    label: Text("Can't"),
                    icon: Icon(Icons.close),
                  ),
                ],
                selected: const <PlanResponseValue>{},
                emptySelectionAllowed: true,
                onSelectionChanged: controllerState.isLoading
                    ? null
                    : (selected) {
                        if (selected.isEmpty) {
                          return;
                        }
                        ref
                            .read(planControllerProvider.notifier)
                            .respondToPlan(
                              circleId: circleId,
                              planId: planId,
                              response: selected.first,
                              comment: null,
                            );
                      },
              ),
              const SizedBox(height: 24),
              Text('Responses', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              responses.when(
                loading: () => const SizedBox(height: 96, child: LoadingView()),
                error: (error, stackTrace) =>
                    ErrorView(message: error.toString()),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'No responses yet',
                      message: 'Responses from Circle members will show here.',
                    );
                  }
                  return Column(
                    children: items.map((response) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            response.userName.isEmpty
                                ? '?'
                                : response.userName.characters.first
                                      .toUpperCase(),
                          ),
                        ),
                        title: Text(response.userName),
                        subtitle: Text(response.response.firestoreValue),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
