import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import 'circle_controller.dart';

class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(circleControllerProvider);

    ref.listen(circleControllerProvider, (previous, next) {
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
                      'Create Circle',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build a private space for your people.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CirclePulseColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      child: Container(
                        width: 94,
                        height: 94,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFC09C), CirclePulseColors.clay],
                          ),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    WarmCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Circle name',
                            hintText: 'e.g. Weekend Crew',
                            prefixIcon: Icons.group_outlined,
                            textInputAction: TextInputAction.next,
                            validator: _validateName,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _descriptionController,
                            label: 'Short description (optional)',
                            hintText: "What's this Circle about?",
                            prefixIcon: Icons.chat_bubble_outline,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SoftInfoPanel(
                      icon: Icons.lock_outline,
                      title: 'Circles are private',
                      message: "Only invited members can see what's inside.",
                    ),
                    const SizedBox(height: 18),
                    PrimaryGradientButton(
                      label: 'Create Circle',
                      icon: Icons.add,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final circle = await ref
        .read(circleControllerProvider.notifier)
        .createCircle(
          name: _nameController.text,
          description: _descriptionController.text,
        );
    if (mounted && !ref.read(circleControllerProvider).hasError) {
      context.pushReplacement('/circles/${circle.id}');
    }
  }

  String? _validateName(String? value) {
    if ((value?.trim() ?? '').length < 2) {
      return 'Circle name must be at least 2 characters.';
    }
    return null;
  }
}
