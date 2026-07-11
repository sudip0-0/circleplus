import 'package:flutter_test/flutter_test.dart';

/// Mirrors [appRouterProvider] redirect decisions without Firebase/GoRouter.
String? resolveAuthRedirect({
  required bool signedIn,
  required bool signingInRoute,
  required bool profileLoading,
  required bool hasProfile,
  required bool onProfileEdit,
}) {
  if (!signedIn) {
    return signingInRoute ? null : '/sign-in';
  }
  if (profileLoading) {
    return null;
  }
  if (!hasProfile && !onProfileEdit) {
    return '/profile/edit';
  }
  if (signingInRoute) {
    return '/home';
  }
  return null;
}

void main() {
  group('auth redirect decisions', () {
    test('signed-out users are sent to sign-in', () {
      expect(
        resolveAuthRedirect(
          signedIn: false,
          signingInRoute: false,
          profileLoading: false,
          hasProfile: false,
          onProfileEdit: false,
        ),
        '/sign-in',
      );
    });

    test('signed-out users may stay on auth screens', () {
      expect(
        resolveAuthRedirect(
          signedIn: false,
          signingInRoute: true,
          profileLoading: false,
          hasProfile: false,
          onProfileEdit: false,
        ),
        isNull,
      );
    });

    test('signed-in users without a profile go to profile edit', () {
      expect(
        resolveAuthRedirect(
          signedIn: true,
          signingInRoute: false,
          profileLoading: false,
          hasProfile: false,
          onProfileEdit: false,
        ),
        '/profile/edit',
      );
    });

    test('profile loading does not redirect', () {
      expect(
        resolveAuthRedirect(
          signedIn: true,
          signingInRoute: false,
          profileLoading: true,
          hasProfile: false,
          onProfileEdit: false,
        ),
        isNull,
      );
    });

    test('signed-in users on auth screens go home', () {
      expect(
        resolveAuthRedirect(
          signedIn: true,
          signingInRoute: true,
          profileLoading: false,
          hasProfile: true,
          onProfileEdit: false,
        ),
        '/home',
      );
    });
  });
}
