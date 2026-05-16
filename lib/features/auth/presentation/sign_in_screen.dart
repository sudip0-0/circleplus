import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/circlepulse_ui.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return WarmScaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CirclePulseLogo(size: 76, showWordmark: false),
                    ),
                    const SizedBox(height: 14),
                    const Center(child: CirclePulseLogo(size: 34)),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Your circle. Your moments.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: CirclePulseColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    WarmCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _emailController,
                            label: 'Email address',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: const Icon(Icons.visibility_outlined),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 22),
                          PrimaryGradientButton(
                            label: 'Sign In',
                            icon: Icons.login,
                            isLoading: authState.isLoading,
                            onPressed: authState.isLoading ? null : _submit,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () => _showForgotPasswordSheet(context),
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : () => context.go('/sign-up'),
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
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

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ForgotPasswordSheet(
        prefillEmail: _emailController.text.trim(),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}

// ── Forgot Password bottom sheet ──────────────────────────────────────────────

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({required this.prefillEmail});

  final String prefillEmail;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Padding(
      // Push the sheet up when the keyboard appears.
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        decoration: BoxDecoration(
          color: CirclePulseColors.warmSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: CirclePulseColors.outline),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SafeArea(
          top: false,
          child: _sent ? _SuccessContent(onClose: () => Navigator.pop(context)) : _FormContent(
            formKey: _formKey,
            emailController: _emailController,
            isLoading: authState.isLoading,
            onSend: _send,
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authControllerProvider).error.toString()),
        ),
      );
      return;
    }
    setState(() => _sent = true);
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CirclePulseColors.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reset your password',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: CirclePulseColors.cocoa,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter your email and we'll send you a link to create a new password.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CirclePulseColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: emailController,
            label: 'Email address',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (!text.contains('@') || !text.contains('.')) {
                return 'Enter a valid email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          PrimaryGradientButton(
            label: 'Send Reset Link',
            icon: Icons.send_outlined,
            isLoading: isLoading,
            onPressed: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CirclePulseColors.outline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 52,
          color: CirclePulseColors.clay,
        ),
        const SizedBox(height: 14),
        Text(
          'Check your inbox',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: CirclePulseColors.cocoa,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "If that email is registered, you'll receive a password reset link shortly.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CirclePulseColors.muted,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryGradientButton(
          label: 'Done',
          onPressed: onClose,
        ),
      ],
    );
  }
}
