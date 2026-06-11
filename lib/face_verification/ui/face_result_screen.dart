// lib/face_verification/ui/face_result_screen.dart
//
// Sprint 4 — Face verification result UI.
// Displays the Regula face matching score and liveness status.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';

class FaceResultScreen extends StatelessWidget {
  final double matchScore;
  final String livenessStatus;
  final String applicationId;

  const FaceResultScreen({
    super.key,
    required this.matchScore,
    required this.livenessStatus,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    const passThreshold = 75.0;
    final passed = matchScore >= passThreshold && livenessStatus == 'PASSED';
    final badgeColor = passed ? AppColors.success : AppColors.warning;
    final badgeIcon = passed
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;
    final statusText = passed
        ? 'Face verification passed'
        : 'Face verification needs review';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Verification result', showClose: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badgeIcon, size: 80, color: badgeColor),
              const SizedBox(height: 24),
              Text(
                statusText,
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Match score: ${matchScore.toStringAsFixed(1)}%\n'
                'Liveness: $livenessStatus\n'
                'Application: $applicationId',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.goNamed('home'),
                child: const Text('Done', style: AppTextStyles.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
