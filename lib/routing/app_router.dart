import 'package:flutter/material.dart';

import '../features/auth/presentation/sign_in_screen.dart';

class AppRouter {
  const AppRouter._();

  static Widget get initialScreen => const SignInScreen();
}
