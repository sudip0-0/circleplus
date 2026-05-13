import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_text_field.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create Plan')),
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
                    AppTextField(
                      controller: _titleController,
                      label: 'Title',
                      textInputAction: TextInputAction.next,
                      validator: _validateTitle,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _locationController,
                      label: 'Location',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        '${MaterialLocalizations.of(context).formatMediumDate(_startsAt)} at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_startsAt))}',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Plan'),
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
      context.go('/circles/${widget.circleId}/plans/${plan.id}');
    }
  }

  String? _validateTitle(String? value) {
    if ((value?.trim() ?? '').length < 2) {
      return 'Plan title must be at least 2 characters.';
    }
    return null;
  }
}
