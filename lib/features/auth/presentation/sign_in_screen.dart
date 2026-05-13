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
                            onPressed: authState.isLoading ? null : () {},
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
