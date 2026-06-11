// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../../kyc_application/model/kyc_application_model.dart';
import '../../kyc_application/model/applicant_type.dart';

/// Simplified — now only shows applicant type confirmation
/// before navigating to readiness screen.
/// Actual document capture is done by Regula in DocumentScanScreen.
class IdUploadScreen extends StatelessWidget {
  final KycApplicationModel application;
  const IdUploadScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final isEgyptian = application.applicantType == ApplicantType.egyptian;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Confirm your identity'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final bottomPadding = 24 + media.viewPadding.bottom;
            final contentSpacing = media.size.height < 650 ? 18.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 30, 24, bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SegmentedProgressBar(current: 2, total: 4),
                  SizedBox(height: contentSpacing),
                  Text(
                    isEgyptian
                        ? 'We\'ll scan your\nNational ID'
                        : 'We\'ll scan your\nPassport',
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isEgyptian
                        ? 'On the next step, our scanner will guide you through capturing both sides of your National ID.'
                        : 'On the next step, our scanner will guide you through capturing the photo page of your passport.',
                    style: AppTextStyles.body,
                  ),
                  SizedBox(height: contentSpacing),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _FeatureRow(
                          icon: Icons.crop_free_rounded,
                          text: 'Automatic document detection',
                        ),
                        const Divider(height: 20, color: AppColors.divider),
                        _FeatureRow(
                          icon: Icons.text_fields_rounded,
                          text: 'Automatic text extraction (OCR)',
                        ),
                        const Divider(height: 20, color: AppColors.divider),
                        _FeatureRow(
                          icon: Icons.verified_rounded,
                          text: 'Document authenticity verification',
                        ),
                        if (isEgyptian) ...[
                          const Divider(height: 20, color: AppColors.divider),
                          _FeatureRow(
                            icon: Icons.flip_rounded,
                            text: 'Both sides scanned automatically',
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: contentSpacing),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(51),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.light_mode_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Make sure you\'re in a well-lit area before starting.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () => context.goNamed('readiness'),
                    child: const Text(
                      'Continue',
                      style: AppTextStyles.buttonText,
                    ),
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}
