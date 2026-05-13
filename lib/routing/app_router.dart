import 'package:go_router/go_router.dart';

import '../features/auth/presentation/sign_in_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const signIn = '/sign-in';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.signIn,
  routes: [
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
  ],
);
