import 'package:flutter/material.dart';
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
                onPressed: () {
                  // TODO: Implement retry logic
                  // Common options:
                  // 1. Restart the network check
                  // 2. Go back to initial route
                  // 3. Restart the entire app flow
                },
                child: const Text('I\'ve turned off my VPN — Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
