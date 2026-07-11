import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import 'plan_controller.dart';

class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({required this.circleId, super.key});

  final String circleId;

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _startsAt = DateTime.now().add(const Duration(days: 1));

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
    });

    return WarmScaffold(
      appBar: WarmAppBar(
        leading: SoftIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Plan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plan something great together.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CirclePulseColors.muted,
                      ),
                    ),
                    const SizedBox(height: 30),
                    WarmCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _titleController,
                            label: 'Title',
                            hintText: 'Sunset picnic',
                            prefixIcon: Icons.wb_twilight_outlined,
                            textInputAction: TextInputAction.next,
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 14),
                          _PickerTile(
                            icon: Icons.calendar_month_outlined,
                            label: 'Date',
                            value: MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(_startsAt),
                            onTap: _pickDateTime,
                          ),
                          const SizedBox(height: 14),
                          _PickerTile(
                            icon: Icons.schedule_outlined,
                            label: 'Time',
                            value: MaterialLocalizations.of(context)
                                .formatTimeOfDay(
                                  TimeOfDay.fromDateTime(_startsAt),
                                ),
                            onTap: _pickDateTime,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _locationController,
                            label: 'Location',
                            hintText: 'Riverside Park',
                            prefixIcon: Icons.place_outlined,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _descriptionController,
                            label: 'Note (optional)',
                            hintText: "Let's bring snacks and good vibes!",
                            prefixIcon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryGradientButton(
                      label: 'Create Plan',
                      icon: Icons.event_available_outlined,
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
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
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) {
      return;
    }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final plan = await ref
        .read(planControllerProvider.notifier)
        .createPlan(
          circleId: widget.circleId,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          startsAt: _startsAt,
        );
    if (mounted && !ref.read(planControllerProvider).hasError) {
      context.pushReplacement('/circles/${widget.circleId}/plans/${plan.id}');
    }
  }

  String? _validateTitle(String? value) {
    if ((value?.trim() ?? '').length < 2) {
      return 'Plan title must be at least 2 characters.';
    }
    return null;
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
