import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/core/widgets/kyc_app_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../authentication/cubit/auth_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KycAppBar(
        title: 'Your Application',
        showBack: false,
        onClose: () => context.read<AuthCubit>().signOut(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                // Hero illustration area
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text("Let's get started", style: AppTextStyles.heading1),
                const SizedBox(height: 8),
                Text(
                  "Here's what you'll need to complete your identity verification — don't worry, it shouldn't take long.",
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 20),

                // Info card —
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        title: 'About you',
                        description:
                            "We'll ask a few questions about you and your details.",
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        title: 'Confirm your identity',
                        description:
                            "We'll need to see your national ID or passport.",
                      ),
                      const Divider(height: 20, color: AppColors.divider),
                      _InfoRow(
                        icon: Icons.face_outlined,
                        title: 'Face verification',
                        description:
                            "We'll take a quick selfie to match against your ID.",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: () => context.goNamed('applicantType'),
          child: const Text('Continue', style: AppTextStyles.buttonText),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
