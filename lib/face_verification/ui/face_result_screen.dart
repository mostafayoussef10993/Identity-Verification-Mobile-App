// lib/face_verification/ui/face_result_screen.dart
//
// Sprint 4 Stub — Replace with full Regula Face SDK result screen.
// Place at: lib/face_verification/ui/face_result_screen.dart

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Verification complete', showClose: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: AppColors.success,
              ),
              const SizedBox(height: 24),
              Text('Face Result (Stub)', style: AppTextStyles.heading1),
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
