import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/circles/presentation/circle_members_screen.dart';
import '../features/circles/presentation/circle_room_screen.dart';
import '../features/circles/presentation/create_circle_screen.dart';
import '../features/circles/presentation/home_screen.dart';
import '../features/circles/presentation/join_circle_screen.dart';
import '../features/messages/presentation/circle_chat_screen.dart';
import '../features/plans/presentation/create_plan_screen.dart';
import '../features/plans/presentation/plan_detail_screen.dart';
import '../features/plans/presentation/plans_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_controller.dart';
import '../features/pulses/presentation/create_pulse_screen.dart';
import '../features/pulses/presentation/pulse_wall_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const profileEdit = '/profile/edit';
  static const home = '/home';
  static const createCircle = '/circles/create';
  static const joinCircle = '/circles/join';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  // Combine auth state changes + profile stream changes so the router
  // re-evaluates when either changes (no extra Firestore read needed).
  final refreshStream = StreamController<void>.broadcast();
  ref.listen(currentUserProfileProvider, (previous, current) {
    if (!refreshStream.isClosed) refreshStream.add(null);
  });
  ref.onDispose(refreshStream.close);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(
      StreamGroup.merge([
        authRepository.authStateChanges(),
        refreshStream.stream,
      ]),
    ),
    redirect: (context, state) {
      final user = authRepository.currentUser;
      final location = state.uri.path;
      final signingIn =
          location == AppRoutes.signIn || location == AppRoutes.signUp;

      if (user == null) {
        return signingIn ? null : AppRoutes.signIn;
      }

      // Read the already-cached stream value — no extra Firestore read.
      final profileAsync = ref.read(currentUserProfileProvider);
      if (profileAsync.isLoading) {
        // Still loading — stay put and wait for the next refresh.
        return null;
      }
      final profile = profileAsync.asData?.value;
      if (profile == null && location != AppRoutes.profileEdit) {
        return AppRoutes.profileEdit;
      }

      if (signingIn) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.createCircle,
        builder: (context, state) => const CreateCircleScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinCircle,
        builder: (context, state) => const JoinCircleScreen(),
      ),
      GoRoute(
        path: '/circles/:circleId',
        builder: (context, state) =>
            CircleRoomScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/chat',
        builder: (context, state) =>
            CircleChatScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/members',
        builder: (context, state) =>
            CircleMembersScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/pulse/create',
        builder: (context, state) =>
            CreatePulseScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/pulses',
        builder: (context, state) =>
            PulseWallScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/plans',
        builder: (context, state) =>
            PlansScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/plans/create',
        builder: (context, state) =>
            CreatePlanScreen(circleId: state.pathParameters['circleId']!),
      ),
      GoRoute(
        path: '/circles/:circleId/plans/:planId',
        builder: (context, state) => PlanDetailScreen(
          circleId: state.pathParameters['circleId']!,
          planId: state.pathParameters['planId']!,
        ),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
