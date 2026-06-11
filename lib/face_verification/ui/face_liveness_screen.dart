// lib/face_verification/ui/face_liveness_screen.dart
//
// Sprint 4 — Face verification UI.
// Uses FaceVerificationCubit and Regula Face SDK to perform passive liveness
// and face matching, then routes to the result screen.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../cubit/face_verification_cubit.dart';
import '../cubit/face_verification_state.dart';

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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: BlocConsumer<FaceVerificationCubit, FaceVerificationState>(
                  listener: (context, state) {
                    if (state is FaceVerificationSuccess) {
                      context.goNamed(
                        'faceResult',
                        extra: {
                          'matchScore': state.result.matchScore,
                          'livenessStatus': state.result.livenessStatus,
                          'applicationId': state.result.applicationId,
                        },
                      );
                    }
                  },
                  builder: (context, state) {
                    final hasPortrait =
                        documentPortraitBytes != null &&
                        documentPortraitBytes!.isNotEmpty;
                    final errorMessage = state is FaceVerificationError
                        ? state.message
                        : null;
                    final isLoading = state is FaceVerificationLoading;
                    final loadingMessage = state is FaceVerificationLoading
                        ? state.message
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
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
                        const SizedBox(height: 28),
                        Text(
                          'Face verification',
                          style: AppTextStyles.heading1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasPortrait
                              ? 'Follow the on-screen instructions to capture a selfie. We will compare it to your document portrait.'
                              : 'Document portrait is missing. Face verification cannot proceed without a captured portrait.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Expanded(
                          child: Center(
                            child: isLoading
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        loadingMessage ?? 'Working...',
                                        style: AppTextStyles.body,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.camera_front_rounded,
                                        size: 64,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'Ready for selfie capture',
                                        style: AppTextStyles.label,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap continue when you are in a well-lit area and your face is centered on the screen.',
                                        style: AppTextStyles.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ElevatedButton(
                            onPressed: hasPortrait && !isLoading
                                ? () => context
                                      .read<FaceVerificationCubit>()
                                      .startFaceVerification(
                                        documentPortraitBytes:
                                            documentPortraitBytes!,
                                        applicationId: applicationId,
                                        userId: userId,
                                      )
                                : null,
                            child: Text(
                              hasPortrait ? 'Start face scan' : 'Cannot start',
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
