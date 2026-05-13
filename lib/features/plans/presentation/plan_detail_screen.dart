import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
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

    return WarmScaffold(
      appBar: WarmAppBar(
        title: 'Plan Details',
        leading: SoftIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          SoftIconButton(
            icon: Icons.more_horiz,
            tooltip: 'Plan options',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: plan.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(message: error.toString()),
        data: (item) {
          if (item == null) {
            return const ErrorView(message: 'Plan was not found.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              WarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 190,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB987), Color(0xFF74513A)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.local_florist_outlined,
                              color: Colors.white70,
                              size: 70,
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: _DateBadge(date: item.startsAt),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          _PlanMetaRow(
                            icon: Icons.calendar_month_outlined,
                            label: DateFormat.yMMMd().format(item.startsAt),
                          ),
                          _PlanMetaRow(
                            icon: Icons.schedule_outlined,
                            label: DateFormat.jm().format(item.startsAt),
                          ),
                          if (item.location?.isNotEmpty == true)
                            _PlanMetaRow(
                              icon: Icons.place_outlined,
                              label: item.location!,
                            ),
                          _PlanMetaRow(
                            icon: Icons.person_outline,
                            label: 'Hosted by ${item.createdByName}',
                          ),
                          if (item.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Text(item.description!),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ResponseButton(
                                  label: 'In',
                                  count: item.inCount,
                                  icon: Icons.check_circle_outline,
                                  selected: true,
                                  onTap: controllerState.isLoading
                                      ? null
                                      : () => _respond(
                                          ref,
                                          PlanResponseValue.in_,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ResponseButton(
                                  label: 'Maybe',
                                  count: item.maybeCount,
                                  icon: Icons.help_outline,
                                  onTap: controllerState.isLoading
                                      ? null
                                      : () => _respond(
                                          ref,
                                          PlanResponseValue.maybe,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ResponseButton(
                                  label: "Can't",
                                  count: item.cantCount,
                                  icon: Icons.close,
                                  onTap: controllerState.isLoading
                                      ? null
                                      : () => _respond(
                                          ref,
                                          PlanResponseValue.cant,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WarmCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Avatar(
                                displayName: response.userName,
                                photoUrl: response.userPhotoUrl,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(response.userName)),
                              Chip(
                                label: Text(response.response.firestoreValue),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
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

  void _respond(WidgetRef ref, PlanResponseValue response) {
    ref
        .read(planControllerProvider.notifier)
        .respondToPlan(
          circleId: circleId,
          planId: planId,
          response: response,
          comment: null,
        );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CirclePulseColors.warmSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            DateFormat.MMM().format(date).toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CirclePulseColors.clay,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            DateFormat.d().format(date),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PlanMetaRow extends StatelessWidget {
  const _PlanMetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CirclePulseColors.clay),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  const _ResponseButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? CirclePulseColors.clay : CirclePulseColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CirclePulseColors.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : CirclePulseColors.clay),
            const SizedBox(height: 4),
            Text(
              '$label\n$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : CirclePulseColors.cocoa,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
