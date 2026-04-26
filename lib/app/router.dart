import 'package:go_router/go_router.dart';
import '../onboarding/ui/onboarding_screen.dart';
import '../authentication/ui/phone_entry_screen.dart';
import '../authentication/ui/otp_verification_screen.dart';
import '../home/ui/home_screen.dart';
import '../device_intelligence/ui/vpn_blocked_screen.dart';

GoRouter buildRouter({
  required bool onboardingDone,
  required bool isAuthenticated,
  required bool isSuspiciousNetwork,
}) {
  return GoRouter(
    initialLocation: _getInitialRoute(
      onboardingDone: onboardingDone,
      isAuthenticated: isAuthenticated,
      isSuspiciousNetwork: isSuspiciousNetwork,
    ),
    routes: [
      GoRoute(
        path: '/vpn-blocked',
        name: 'vpnBlocked',
        builder: (context, state) => VpnBlockedScreen(
          reason: state.extra as String? ?? 'Suspicious network detected',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final verificationId = state.extra as String;
          return OtpVerificationScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}

String _getInitialRoute({
  required bool onboardingDone,
  required bool isAuthenticated,
  required bool isSuspiciousNetwork,
}) {
  if (isSuspiciousNetwork) return '/vpn-blocked';
  if (isAuthenticated) return '/home';
  if (!onboardingDone) return '/onboarding';
  return '/auth';
}
