// lib/document_upload/ui/readiness_confirmation_screen.dart
//
// FIXED: Added null guard for currentApplication to prevent crash when
// KycApplicationCubit is not in KycApplicationActive state.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../../kyc_application/cubit/kyc_application_cubit.dart';
import '../../kyc_application/cubit/kyc_application_state.dart';
import '../../kyc_application/model/kyc_application_model.dart';

class ReadinessConfirmationScreen extends StatelessWidget {
  const ReadinessConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Confirm your identity', showClose: false),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final bottomPadding = 24 + media.viewPadding.bottom;
            final contentSpacing = media.size.height < 650 ? 20.0 : 32.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 32, 24, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SegmentedProgressBar(current: 3, total: 4),
                  SizedBox(height: contentSpacing),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: contentSpacing),
                  Text(
                    "Great, we got\nyour document!",
                    style: AppTextStyles.heading1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We'll now verify your document and check its authenticity.",
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: contentSpacing),
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
                  SizedBox(height: contentSpacing),
                  BlocBuilder<KycApplicationCubit, KycApplicationState>(
                    builder: (context, state) {
                      final KycApplicationModel? application =
                          state is KycApplicationActive
                          ? state.application
                          : null;

                      if (application == null) {
                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Session expired. Please go back and start again.',
                                style: TextStyle(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => context.goNamed('applicantType'),
                              child: const Text('Go back'),
                            ),
                          ],
                        );
                      }

                      return ElevatedButton(
                        onPressed: () =>
                            context.goNamed('documentScan', extra: application),
                        child: const Text(
                          'Start verification',
                          style: AppTextStyles.buttonText,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
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
