import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/invite_code_generator.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import 'circle_controller.dart';

class JoinCircleScreen extends ConsumerStatefulWidget {
  const JoinCircleScreen({super.key});

  @override
  ConsumerState<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends ConsumerState<JoinCircleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join a Circle',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Got an invite code? Enter it below to join your people.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CirclePulseColors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Align(
                      child: Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CirclePulseColors.cardAlt,
                          border: Border.all(
                            color: CirclePulseColors.outline,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.weekend_outlined,
                          color: CirclePulseColors.clay,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    WarmCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _codeController,
                            label: 'Invite code',
                            hintText: 'ABC123',
                            prefixIcon: Icons.vpn_key_outlined,
                            textInputAction: TextInputAction.done,
                            validator: _validateCode,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Codes are usually 6 characters, letters and numbers.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: CirclePulseColors.muted),
                          ),
                          const SizedBox(height: 22),
                          PrimaryGradientButton(
                            label: 'Join Circle',
                            icon: Icons.group_add_outlined,
                            isLoading: state.isLoading,
                            onPressed: state.isLoading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SoftInfoPanel(
                      icon: Icons.groups_outlined,
                      title: 'A friend must share the code',
                      message: 'Each Circle is private and invite-only.',
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
        .joinCircleByInviteCode(_codeController.text);
    if (mounted && !ref.read(circleControllerProvider).hasError) {
      context.pushReplacement('/circles/${circle.id}');
    }
  }

  String? _validateCode(String? value) {
    if (!isValidInviteCode((value ?? '').trim().toUpperCase())) {
      return 'Enter a valid 6-character invite code.';
    }
    return null;
  }
}
