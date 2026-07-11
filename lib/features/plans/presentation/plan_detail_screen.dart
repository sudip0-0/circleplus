import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/plan.dart';
import '../domain/plan_response.dart';
import 'plan_controller.dart';
import 'widgets/plan_cancelled_banner.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({
    required this.circleId,
    required this.planId,
    super.key,
  });

  final String circleId;
  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  PlanResponseValue? _optimisticResponse;

  @override
  void didUpdateWidget(covariant PlanDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circleId != widget.circleId ||
        oldWidget.planId != widget.planId) {
      _optimisticResponse = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = (circleId: widget.circleId, planId: widget.planId);
    final plan = ref.watch(planProvider(args));
    final responses = ref.watch(planResponsesProvider(args));
    final controllerState = ref.watch(planControllerProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserResponse = responses.maybeWhen(
      data: (items) {
        for (final response in items) {
          if (response.userId == currentUser?.id) {
            return response.response;
          }
        }
        return null;
      },
      orElse: () => null,
    );
    final selectedResponse = _optimisticResponse ?? currentUserResponse;

    ref.listen(planControllerProvider, (previous, next) {
      if (next.hasError) {
        if (mounted) {
          setState(() => _optimisticResponse = null);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });
    ref.listen(planResponsesProvider(args), (previous, next) {
      final confirmedResponse = next.maybeWhen(
        data: (items) {
          for (final response in items) {
            if (response.userId == currentUser?.id) {
              return response.response;
            }
          }
          return null;
        },
        orElse: () => null,
      );
      if (_optimisticResponse != null &&
          confirmedResponse == _optimisticResponse &&
          mounted) {
        setState(() => _optimisticResponse = null);
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
          plan.maybeWhen(
            data: (item) {
              final isCreator =
                  item != null && item.createdBy == currentUser?.id;
              final isActive = item?.status == PlanStatus.active;
              if (!isCreator || !isActive) return const SizedBox.shrink();
              return SoftIconButton(
                icon: Icons.more_horiz,
                tooltip: 'Plan options',
                onPressed: () => _showCreatorOptions(context, ref, item),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: plan.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(planProvider(args)),
        ),
        data: (item) {
          if (item == null) {
            return ErrorView(
              message: 'Plan was not found.',
              onRetry: () => ref.invalidate(planProvider(args)),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (item.status == PlanStatus.cancelled)
                const PlanCancelledBanner(),
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
                                  selected:
                                      selectedResponse == PlanResponseValue.in_,
                                  onTap:
                                      (controllerState.isLoading ||
                                          item.status != PlanStatus.active)
                                      ? null
                                      : () => _respond(PlanResponseValue.in_),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ResponseButton(
                                  label: 'Maybe',
                                  count: item.maybeCount,
                                  icon: Icons.help_outline,
                                  selected:
                                      selectedResponse ==
                                      PlanResponseValue.maybe,
                                  onTap:
                                      (controllerState.isLoading ||
                                          item.status != PlanStatus.active)
                                      ? null
                                      : () => _respond(PlanResponseValue.maybe),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ResponseButton(
                                  label: "Can't",
                                  count: item.cantCount,
                                  icon: Icons.close,
                                  selected:
                                      selectedResponse ==
                                      PlanResponseValue.cant,
                                  onTap:
                                      (controllerState.isLoading ||
                                          item.status != PlanStatus.active)
                                      ? null
                                      : () => _respond(PlanResponseValue.cant),
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
                error: (error, stackTrace) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(planResponsesProvider(args)),
                ),
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

  void _respond(PlanResponseValue response) {
    setState(() => _optimisticResponse = response);
    ref
        .read(planControllerProvider.notifier)
        .respondToPlan(
          circleId: widget.circleId,
          planId: widget.planId,
          response: response,
          comment: null,
        );
  }

  void _showCreatorOptions(
    BuildContext context,
    WidgetRef ref,
    PlanModel plan,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Plan'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditSheet(context, ref, plan);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: Colors.red.shade700),
              title: Text(
                'Cancel Plan',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmCancel(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, PlanModel plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditPlanSheet(circleId: widget.circleId, plan: plan),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this plan?'),
        content: const Text(
          'All members will see it as cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref
        .read(planControllerProvider.notifier)
        .cancelPlan(circleId: widget.circleId, planId: widget.planId);
  }
}

// ── Edit Plan Sheet ───────────────────────────────────────────────────────────

class _EditPlanSheet extends ConsumerStatefulWidget {
  const _EditPlanSheet({required this.circleId, required this.plan});

  final String circleId;
  final PlanModel plan;

  @override
  ConsumerState<_EditPlanSheet> createState() => _EditPlanSheetState();
}

class _EditPlanSheetState extends ConsumerState<_EditPlanSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late DateTime _startsAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan.title);
    _descriptionController = TextEditingController(
      text: widget.plan.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.plan.location ?? '',
    );
    _startsAt = widget.plan.startsAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planControllerProvider);

    ref.listen(planControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
      if (!next.isLoading && !next.hasError && previous?.isLoading == true) {
        Navigator.of(context).pop();
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Plan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                prefixIcon: Icons.wb_twilight_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if ((v?.trim() ?? '').length < 2) {
                    return 'Title must be at least 2 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PickerTile(
                icon: Icons.calendar_month_outlined,
                label: 'Date',
                value: MaterialLocalizations.of(
                  context,
                ).formatMediumDate(_startsAt),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
              _PickerTile(
                icon: Icons.schedule_outlined,
                label: 'Time',
                value: MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(TimeOfDay.fromDateTime(_startsAt)),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _locationController,
                label: 'Location',
                prefixIcon: Icons.place_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _descriptionController,
                label: 'Note (optional)',
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              PrimaryGradientButton(
                label: 'Save Changes',
                icon: Icons.check_outlined,
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(planControllerProvider.notifier)
        .editPlan(
          circleId: widget.circleId,
          planId: widget.plan.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startsAt: _startsAt,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        child: Text(value),
      ),
    );
  }
}
