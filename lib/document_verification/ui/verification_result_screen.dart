// lib/document_verification/ui/verification_result_screen.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// VERIFICATION RESULT SCREEN — Updated for Arabic/Egyptian ID fields
// ══════════════════════════════════════════════════════════════════════════════
//
// Changes:
//   + Displays Arabic name section when hasArabicName == true
//   + Displays Egypt back-side fields (profession, religion, marital status)
//   + Continue button passes portraitBytes + applicationId to face liveness
//   + RTL text direction applied to Arabic content
//
// ══════════════════════════════════════════════════════════════════════════════

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../../kyc_application/cubit/kyc_application_cubit.dart';
import '../../kyc_application/cubit/kyc_application_state.dart';
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
                    _StatusBadge(status: result.overallStatus),
                    const SizedBox(height: 24),

                    // ── Document type ──────────────────────────────────────
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

                    // ── Arabic identity (Egyptian ID only) ─────────────────
                    if (result.hasArabicName)
                      _InfoSection(
                        title: 'الهوية (Arabic)',
                        titleIsArabic: true,
                        children: [
                          if (result.fullNameArabic != null)
                            _InfoRow(
                              'الاسم الكامل',
                              result.fullNameArabic!,
                              isRtl: true,
                            ),
                          if (result.addressArabic != null)
                            _InfoRow(
                              'العنوان',
                              result.addressArabic!,
                              isRtl: true,
                            ),
                          if (result.mothersName != null)
                            _InfoRow(
                              'اسم الأم',
                              result.mothersName!,
                              isRtl: true,
                            ),
                        ],
                      ),

                    if (result.hasArabicName) const SizedBox(height: 16),

                    // ── Latin identity ─────────────────────────────────────
                    _InfoSection(
                      title: 'Identity',
                      children: [
                        if (result.fullNameLatin != null)
                          _InfoRow('Full name (Latin)', result.fullNameLatin!),
                        if (result.dateOfBirth != null)
                          _InfoRow('Date of birth', result.dateOfBirth!),
                        if (result.sex != null) _InfoRow('Sex', result.sex!),
                        if (result.nationality != null)
                          _InfoRow('Nationality', result.nationality!),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Document details ───────────────────────────────────
                    _InfoSection(
                      title: 'Document details',
                      children: [
                        if (result.documentNumber != null)
                          _InfoRow('Document number', result.documentNumber!),
                        if (result.personalNumber != null)
                          _InfoRow(
                            'National ID number',
                            result.personalNumber!,
                          ),
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

                    // ── Egypt back-side data ───────────────────────────────
                    if (result.hasEgyptBackSideData) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Additional details',
                        children: [
                          if (result.profession != null)
                            _InfoRow('Profession', result.profession!),
                          if (result.maritalStatus != null)
                            _InfoRow('Marital status', result.maritalStatus!),
                          if (result.religion != null)
                            _InfoRow('Religion', result.religion!),
                        ],
                      ),
                    ],

                    if (result.address != null) ...[
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Address',
                        children: [_InfoRow('Address', result.address!)],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Validation checks ──────────────────────────────────
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

            // ── Continue to face verification ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  BlocBuilder<KycApplicationCubit, KycApplicationState>(
                    builder: (context, state) {
                      final applicationId = state is KycApplicationActive
                          ? state.application.applicationId
                          : '';
                      final userId = state is KycApplicationActive
                          ? state.application.userId
                          : '';

                      return ElevatedButton(
                        onPressed: () => context.goNamed(
                          'faceLiveness',
                          extra: {
                            'portraitBytes': result.portraitBytes,
                            'applicationId': applicationId,
                            'userId': userId,
                          },
                        ),
                        child: const Text(
                          'Continue to face scan',
                          style: AppTextStyles.buttonText,
                        ),
                      );
                    },
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

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final VerificationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      VerificationStatus.genuine => (
        AppColors.success,
        Icons.check_circle_rounded,
        'Document verified',
      ),
      VerificationStatus.suspicious => (
        AppColors.warning,
        Icons.warning_amber_rounded,
        'Needs manual review',
      ),
      VerificationStatus.needsReview => (
        AppColors.info,
        Icons.info_outline_rounded,
        'Partially verified',
      ),
      VerificationStatus.failed => (
        AppColors.error,
        Icons.cancel_rounded,
        'Verification failed',
      ),
    };

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
  final bool titleIsArabic;

  const _InfoSection({
    required this.title,
    required this.children,
    this.titleIsArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    final nonEmpty = children.isNotEmpty;
    if (!nonEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label,
            textDirection: titleIsArabic ? TextDirection.rtl : null,
          ),
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
  final bool isRtl;
  const _InfoRow(this.label, this.value, {this.isRtl = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
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
