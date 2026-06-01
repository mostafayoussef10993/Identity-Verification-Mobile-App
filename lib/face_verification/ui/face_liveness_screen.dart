// lib/face_verification/ui/face_liveness_screen.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// FACE LIVENESS SCREEN — Sprint 4 Stub
// ══════════════════════════════════════════════════════════════════════════════
//
// This is a STUB to unblock routing. Sprint 4 will replace this with the
// full Regula Face SDK integration (passive liveness + face matching).
//
// Place at: lib/face_verification/ui/face_liveness_screen.dart
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';

class FaceLivenessScreen extends StatelessWidget {
  final Uint8List? documentPortraitBytes;
  final String applicationId;
  final String userId;

  const FaceLivenessScreen({
    super.key,
    this.documentPortraitBytes,
    required this.applicationId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Face verification', showClose: false),
      body: SafeArea(
        child: Column(
          children: [
            const SegmentedProgressBar(current: 4, total: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Face Verification',
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sprint 4 — Coming soon.\n\n'
                      'This screen will launch the Regula Face SDK for '
                      'passive liveness detection and face matching against '
                      'your document portrait.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Debug info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Application ID: $applicationId\n'
                        'Portrait: ${documentPortraitBytes != null ? "${documentPortraitBytes!.length} bytes" : "None"}',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: ElevatedButton(
                onPressed: () => context.goNamed('home'),
                child: const Text(
                  'Continue (stub)',
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
