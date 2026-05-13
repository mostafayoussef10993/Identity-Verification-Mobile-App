import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';

class ReadinessConfirmationScreen extends StatelessWidget {
  const ReadinessConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Confirm your identity', showClose: false),
      body: SafeArea(
        child: Column(
          children: [
            const SegmentedProgressBar(current: 3, total: 4),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                child: Column(
                  children: [
                    // Illustration
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      "Great, we got\nyour document!",
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We'll now verify your document and check its authenticity. This should only take a moment.",
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // What happens next info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          _NextStep(
                            icon: Icons.document_scanner_rounded,
                            title: 'Document verification',
                            description:
                                'We check your ID is genuine and extract your details.',
                          ),
                          Divider(height: 20, color: AppColors.divider),
                          _NextStep(
                            icon: Icons.face_rounded,
                            title: 'Face verification',
                            description:
                                'We take a quick selfie to match against your ID photo.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Sprint 3 — navigate to Regula document scan
                  context.goNamed('documentScan');
                },
                child: const Text(
                  'Start verification',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _NextStep({
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
