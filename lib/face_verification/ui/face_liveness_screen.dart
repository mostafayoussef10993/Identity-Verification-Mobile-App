// lib/face_verification/ui/face_liveness_screen.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// FACE LIVENESS SCREEN — Fixed
// ══════════════════════════════════════════════════════════════════════════════
//
// FIX: Added StatefulWidget + initState to call initializeSdk() on screen load.
// Old version was StatelessWidget — SDK init only happened on button tap,
// causing a loading delay. Now warms up immediately when screen opens.
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../cubit/face_verification_cubit.dart';
import '../cubit/face_verification_state.dart';

class FaceLivenessScreen extends StatefulWidget {
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
  State<FaceLivenessScreen> createState() => _FaceLivenessScreenState();
}

class _FaceLivenessScreenState extends State<FaceLivenessScreen> {
  @override
  void initState() {
    super.initState();
    // FIX: Warm up SDK on screen load — not on button tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaceVerificationCubit>().initializeSdk();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(
        title: 'Face verification',
        showClose: false,
      ),
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
                        widget.documentPortraitBytes != null &&
                        widget.documentPortraitBytes!.isNotEmpty;

                    final isLoading = state is FaceVerificationLoading;
                    final isError = state is FaceVerificationError;
                    final isReady = state is FaceVerificationReady;

                    final loadingMessage = isLoading ? state.message : null;
                    final errorMessage = isError ? state.message : null;
                    final canRetry = isError ? state.canRetry : false;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),

                        // ── Icon ─────────────────────────────────────────
                        Center(
                          child: Container(
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
                        ),

                        const SizedBox(height: 28),

                        // ── Title ─────────────────────────────────────────
                        Text(
                          'Face verification',
                          style: AppTextStyles.heading1,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // ── Subtitle ──────────────────────────────────────
                        Text(
                          hasPortrait
                              ? 'Follow the on-screen instructions to capture '
                                'a selfie. We will compare it to your document portrait.'
                              : 'Document portrait is missing. '
                                'Face verification cannot proceed without a captured portrait.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // ── Error message ─────────────────────────────────
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Content area ──────────────────────────────────
                        Expanded(
                          child: Center(
                            child: isLoading
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
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
                                      Icon(
                                        isReady
                                            ? Icons.camera_front_rounded
                                            : Icons.hourglass_empty_rounded,
                                        size: 48,
                                        color: isReady
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isReady
                                            ? 'Ready for selfie capture'
                                            : 'Preparing...',
                                        style: AppTextStyles.label,
                                        textAlign: TextAlign.center,
                                      ),
                                      if (isReady) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap the button below when you are in '
                                          'a well-lit area with your face centered '
                                          'on the screen.',
                                          style: AppTextStyles.bodySmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),

                        // ── Action buttons ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: hasPortrait && isReady
                                    ? () => context
                                        .read<FaceVerificationCubit>()
                                        .startFaceVerification(
                                          documentPortraitBytes:
                                              widget.documentPortraitBytes!,
                                          applicationId: widget.applicationId,
                                          userId: widget.userId,
                                        )
                                    : null,
                                child: Text(
                                  hasPortrait ? 'Start face scan' : 'Cannot start',
                                  style: AppTextStyles.buttonText,
                                ),
                              ),
                              if (canRetry) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () =>
                                      context.read<FaceVerificationCubit>().retry(),
                                  child: const Text('Try again'),
                                ),
                              ],
                            ],
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
