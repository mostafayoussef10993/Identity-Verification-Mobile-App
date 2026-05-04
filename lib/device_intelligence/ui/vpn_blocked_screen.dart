// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../device_intelligence/repository/device_intelligence_repository.dart';
import '../../authentication/repository/auth_repository.dart';
import '../../onboarding/cubit/onboarding_cubit.dart';

class VpnBlockedScreen extends StatelessWidget {
  final String reason;
  const VpnBlockedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Icon illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Secure connection\nrequired',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'We detected $reason on your network.\n\n'
                'For security and compliance reasons, identity '
                'verification must be completed on a direct '
                'internet connection.\n\n'
                'Please turn off your VPN or proxy and try again.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Primary button
              ElevatedButton(
                onPressed: () async {
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
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text(
                  "I've turned off my VPN — Try Again",
                  style: AppTextStyles.buttonText,
                ),
              ),

              const SizedBox(height: 16),

              // Outline secondary info text
              Text(
                'This check is required for compliance and security.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
