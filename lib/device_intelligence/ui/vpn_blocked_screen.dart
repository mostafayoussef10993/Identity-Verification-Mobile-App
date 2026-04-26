import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/authentication/repository/auth_repository.dart';
import 'package:kyc/device_intelligence/repository/device_intelligence_repository.dart';
import 'package:kyc/onboarding/cubit/onboarding_cubit.dart';
import '../../core/theme/app_theme.dart';

/// Screen displayed when a suspicious network (VPN, Proxy, TOR, or Datacenter IP)
/// is detected.
///
/// This screen blocks the user from proceeding with onboarding or registration

class VpnBlockedScreen extends StatelessWidget {
  /// The reason why the user was blocked (comes from NetworkSecurityModel.suspicionReason)
  final String reason;
  const VpnBlockedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 80,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              const Text(
                'Secure Connection Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Detailed explanation with dynamic reason
              Text(
                'We detected $reason on your network.\n\n'
                'For security and compliance reasons, identity verification '
                'must be completed on a direct internet connection.\n\n'
                'Please turn off your VPN or proxy and try again.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  // Re-run the VPN check
                  final result = await DeviceIntelligenceRepository()
                      .runCheck();
                  if (!result.isSuspicious && context.mounted) {
                    final onboardingDone =
                        await OnboardingCubit.isOnboardingDone();
                    final isAuth = AuthRepository().currentFirebaseUser != null;
                    if (!isAuth && !onboardingDone) {
                      context.goNamed('onboarding');
                    } else if (!isAuth) {
                      context.goNamed('auth');
                    } else {
                      context.goNamed('home');
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'VPN still detected. Please turn it off and try again.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("I've turned off my VPN — Try Again"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
