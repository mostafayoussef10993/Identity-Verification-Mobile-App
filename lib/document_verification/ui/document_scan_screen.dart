// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/document_verification/cubit/document_verification_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../../kyc_application/cubit/kyc_application_cubit.dart';
import '../../kyc_application/model/kyc_application_model.dart';
import '../cubit/document_verification_cubit.dart';

class DocumentScanScreen extends StatefulWidget {
  final KycApplicationModel application;
  const DocumentScanScreen({super.key, required this.application});

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize SDK as soon as screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentVerificationCubit>().initializeSdk();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(title: 'Verify your document'),
      body: BlocConsumer<DocumentVerificationCubit, DocumentVerificationState>(
        listener: (context, state) {
          if (state is DocumentVerificationSuccess) {
            // Update KYC application with extracted data
            context.read<KycApplicationCubit>().updateApplication(
              (app) => app.copyWith(
                fullName: state.result.fullName,
                idNumber:
                    state.result.documentNumber ?? state.result.personalNumber,
                dateOfBirth: state.result.dateOfBirth,
                expiryDate: state.result.dateOfExpiry,
                nationality: state.result.nationality,
                documentVerificationStatus: state.result.overallStatus.name,
              ),
            );
            // Navigate to verification result screen
            context.goNamed('verificationResult', extra: state.result);
          }

          if (state is DocumentVerificationCancelled) {
            // User backed out of scanner — go back to readiness screen
            context.pop();
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                const SegmentedProgressBar(current: 3, total: 4),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DocumentVerificationState state) {
    if (state is DocumentVerificationInitializing) {
      return _InitializingView(
        message: state.message,
        progress: state.progress,
      );
    }

    if (state is DocumentVerificationReady) {
      return _ReadyView(
        application: widget.application,
        onStartScan: () => context.read<DocumentVerificationCubit>().startScan(
          applicantType: widget.application.applicantType,
          userId: widget.application.userId,
          applicationId: widget.application.applicationId,
        ),
      );
    }

    if (state is DocumentVerificationScanning) {
      return const _ScanningView();
    }

    if (state is DocumentVerificationProcessing ||
        state is DocumentVerificationUploading) {
      final progress = state is DocumentVerificationUploading
          ? state.progress
          : null;
      return _ProcessingView(progress: progress);
    }

    if (state is DocumentVerificationError) {
      return _ErrorView(
        message: state.message,
        canRetry: state.canRetry,
        onRetry: () => context.read<DocumentVerificationCubit>().retry(),
        onRetryInit: () =>
            context.read<DocumentVerificationCubit>().initializeSdk(),
      );
    }

    if (state is DocumentVerificationNotInitialized) {
      return _ErrorView(
        message: 'Verification engine not ready. Please wait.',
        canRetry: true,
        onRetry: () =>
            context.read<DocumentVerificationCubit>().initializeSdk(),
        onRetryInit: () =>
            context.read<DocumentVerificationCubit>().initializeSdk(),
      );
    }

    // Initial state
    return _InitializingView(message: 'Getting ready...', progress: null);
  }
}

// ── Initializing view ─────────────────────────────────────────
class _InitializingView extends StatelessWidget {
  final String message;
  final double? progress;
  const _InitializingView({required this.message, this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.surfaceGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Preparing verification',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (progress != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            )
          else
            const CircularProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }
}

// ── Ready view — user initiates scan ─────────────────────────
class _ReadyView extends StatelessWidget {
  final KycApplicationModel application;
  final VoidCallback onStartScan;
  const _ReadyView({required this.application, required this.onStartScan});

  @override
  Widget build(BuildContext context) {
    final isEgyptian = application.applicantType.requiresBackSide;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        children: [
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.backgroundMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            isEgyptian ? 'Scan your National ID' : 'Scan your Passport',
            style: AppTextStyles.heading1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isEgyptian
                ? 'Position the front of your National ID in the frame. The app will automatically scan both sides.'
                : 'Position the photo page of your passport in the frame.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Instructions card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _Instruction(
                  icon: Icons.light_mode_outlined,
                  text: 'Use in good lighting — avoid glare',
                ),
                const SizedBox(height: 12),
                _Instruction(
                  icon: Icons.crop_free_rounded,
                  text: 'Keep all four corners visible in the frame',
                ),
                const SizedBox(height: 12),
                _Instruction(
                  icon: Icons.pan_tool_alt_outlined,
                  text: 'Hold steady — do not move during scanning',
                ),
                if (isEgyptian) ...[
                  const SizedBox(height: 12),
                  _Instruction(
                    icon: Icons.flip_rounded,
                    text: 'You will be asked to flip the card to scan the back',
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Start scan button
          ElevatedButton.icon(
            onPressed: onStartScan,
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
            label: const Text(
              'Start scanning',
              style: AppTextStyles.buttonText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Instruction({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}

// ── Scanning view — Regula native UI is open ─────────────────
class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Scanner is open...', style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// ── Processing view ───────────────────────────────────────────
class _ProcessingView extends StatelessWidget {
  final double? progress;
  const _ProcessingView({this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            progress != null
                ? 'Saving results ${(progress! * 100).toInt()}%'
                : 'Reading your document...',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onRetryInit;
  const _ErrorView({
    required this.message,
    required this.canRetry,
    required this.onRetry,
    required this.onRetryInit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
          const Spacer(),
          if (canRetry)
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again', style: AppTextStyles.buttonText),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}
