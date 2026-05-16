// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../model/verification_result_model.dart';

class VerificationResultScreen extends StatelessWidget {
  final VerificationResultModel result;
  const VerificationResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Verification result', showClose: false),
      body: SafeArea(
        child: Column(
          children: [
            const SegmentedProgressBar(current: 4, total: 4),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    _StatusBadge(status: result.overallStatus),

                    const SizedBox(height: 24),

                    // Document type
                    if (result.documentTypeName != null)
                      _InfoSection(
                        title: 'Document',
                        children: [
                          _InfoRow('Type', result.documentTypeName!),
                          if (result.countryName != null)
                            _InfoRow('Country', result.countryName!),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Identity fields
                    _InfoSection(
                      title: 'Identity',
                      children: [
                        if (result.fullName != null)
                          _InfoRow('Full name', result.fullName!),
                        if (result.dateOfBirth != null)
                          _InfoRow('Date of birth', result.dateOfBirth!),
                        if (result.sex != null) _InfoRow('Sex', result.sex!),
                        if (result.nationality != null)
                          _InfoRow('Nationality', result.nationality!),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Document details
                    _InfoSection(
                      title: 'Document details',
                      children: [
                        if (result.documentNumber != null)
                          _InfoRow('Document number', result.documentNumber!),
                        if (result.personalNumber != null)
                          _InfoRow('Personal number', result.personalNumber!),
                        if (result.dateOfExpiry != null)
                          _InfoRow('Expiry date', result.dateOfExpiry!),
                        if (result.dateOfIssue != null)
                          _InfoRow('Issue date', result.dateOfIssue!),
                        if (result.issuingAuthority != null)
                          _InfoRow(
                            'Issuing authority',
                            result.issuingAuthority!,
                          ),
                      ],
                    ),

                    if (result.address != null) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Address',
                        children: [_InfoRow('Address', result.address!)],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Validation checks
                    _InfoSection(
                      title: 'Validation checks',
                      children: [
                        _CheckRow('MRZ valid', result.mrzValid),
                        _CheckRow('Text valid', result.textValid),
                        _CheckRow('Image quality', result.imageQualityOk),
                        _CheckRow('Not expired', !result.documentExpired),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.goNamed('faceLiveness'),
                    child: const Text(
                      'Continue to face scan',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                  if (result.overallStatus ==
                      VerificationStatus.suspicious) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Rescan document'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final VerificationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case VerificationStatus.genuine:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Document verified';
        break;
      case VerificationStatus.suspicious:
        color = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        label = 'Needs manual review';
        break;
      case VerificationStatus.needsReview:
        color = AppColors.info;
        icon = Icons.info_outline_rounded;
        label = 'Partially verified';
        break;
      case VerificationStatus.failed:
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        label = 'Verification failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool passed;
  const _CheckRow(this.label, this.passed);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: passed ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
