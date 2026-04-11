import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/device_intelligence/model/network_security_model.dart';
import 'package:kyc/device_intelligence/ui/vpn_blocked_screen.dart';
//Define the app routes using GoRouter
/// Builds and configures the main app router using GoRouter.
/// This router intelligently decides the **initial route** based on the
/// result of the network security check:
/// - If suspicious network  is detected → go to `/vpn-blocked`
/// - Otherwise → go to normal onboarding flow.

GoRouter buildRouter(NetworkSecurityModel networkCheck) {
  return GoRouter(
    // Dynamically set the first screen based on network security check
    initialLocation: networkCheck.isSuspicious ? '/vpn-blocked' : '/onboarding',
    routes: [
      GoRoute(
        // Blocked screen for suspicious networks
        path: '/vpn-blocked',
        name: 'vpnBlocked',
        builder: (context, state) => VpnBlockedScreen(
          // Pass the reason from extra data or use default message
          reason: state.extra as String? ?? 'Suspicious network detected',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Onboarding'),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Authentication'),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const PlaceholderScreen(title: 'Home'),
      ),
    ],
  );
}

//Temporary Placeholder class
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title screen - coming soon')),
    );
  }
}
