// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../../kyc_application/cubit/kyc_application_cubit.dart';
import '../../kyc_application/model/kyc_application_model.dart';
import '../../kyc_application/model/applicant_type.dart';
import '../cubit/document_upload_cubit.dart';

class IdUploadScreen extends StatefulWidget {
  final KycApplicationModel application;
  const IdUploadScreen({super.key, required this.application});

  @override
  State<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends State<IdUploadScreen> {
  // Track uploaded state locally for UI
  File? _frontImage;
  File? _backImage;
  String? _frontUrl;
  String? _backUrl;

  bool get _isEgyptian =>
      widget.application.applicantType == ApplicantType.egyptian;

  bool get _canContinue =>
      _isEgyptian ? _frontUrl != null && _backUrl != null : _frontUrl != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocumentUploadCubit(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: const KycAppBar(title: 'Confirm your identity'),
          body: BlocListener<DocumentUploadCubit, DocumentUploadState>(
            listener: (context, state) {
              // When image is captured → navigate to preview screen
              if (state is DocumentUploadPreview) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<DocumentUploadCubit>(),
                      child: DocumentPreviewScreen(
                        image: state.image,
                        isFrontSide: state.isFrontSide,
                        application: widget.application,
                      ),
                    ),
                  ),
                );
              }

              // After quality check + upload confirmed
              if (state is DocumentUploadSuccess) {
                // Pop preview screen back to upload screen
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                // Update local state + KYC application
                if (state.isFrontSide) {
                  setState(() {
                    _frontImage = state.localImage;
                    _frontUrl = state.imageUrl;
                  });
                  context.read<KycApplicationCubit>().updateApplication(
                    (app) => app.copyWith(idFrontUrl: state.imageUrl),
                  );
                } else {
                  setState(() {
                    _backImage = state.localImage;
                    _backUrl = state.imageUrl;
                  });
                  context.read<KycApplicationCubit>().updateApplication(
                    (app) => app.copyWith(idBackUrl: state.imageUrl),
                  );
                }
              }

              // Permission denied
              if (state is DocumentUploadPermissionDenied) {
                _showPermissionDialog(context, state.source);
              }

              // Error
              if (state is DocumentUploadError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  const SegmentedProgressBar(current: 2, total: 4),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEgyptian
                                ? 'Upload your\nNational ID'
                                : 'Upload your\nPassport',
                            style: AppTextStyles.heading1,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEgyptian
                                ? 'We need both sides of your National ID. Use your camera for the best result.'
                                : 'Upload the photo page of your passport. Use your camera for the best result.',
                            style: AppTextStyles.body,
                          ),

                          const SizedBox(height: 28),

                          // Front side
                          _DocumentSideCard(
                            label: _isEgyptian ? 'Front side' : 'Photo page',
                            icon: Icons.credit_card_rounded,
                            uploadedImage: _frontImage,
                            isUploaded: _frontUrl != null,
                            onCapture: () => context
                                .read<DocumentUploadCubit>()
                                .captureFromCamera(isFrontSide: true),
                            onGallery: () => context
                                .read<DocumentUploadCubit>()
                                .pickFromGallery(isFrontSide: true),
                            onRetake: () {
                              setState(() {
                                _frontImage = null;
                                _frontUrl = null;
                              });
                              context
                                  .read<DocumentUploadCubit>()
                                  .captureFromCamera(isFrontSide: true);
                            },
                          ),

                          // Back side — Egyptian only
                          if (_isEgyptian) ...[
                            const SizedBox(height: 20),
                            _DocumentSideCard(
                              label: 'Back side',
                              icon: Icons.credit_card_outlined,
                              uploadedImage: _backImage,
                              isUploaded: _backUrl != null,
                              onCapture: () => context
                                  .read<DocumentUploadCubit>()
                                  .captureFromCamera(isFrontSide: false),
                              onGallery: () => context
                                  .read<DocumentUploadCubit>()
                                  .pickFromGallery(isFrontSide: false),
                              onRetake: () {
                                setState(() {
                                  _backImage = null;
                                  _backUrl = null;
                                });
                                context
                                    .read<DocumentUploadCubit>()
                                    .captureFromCamera(isFrontSide: false);
                              },
                            ),
                          ],

                          const SizedBox(height: 24),
                          _TipsCard(isEgyptian: _isEgyptian),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: ElevatedButton(
                      onPressed: _canContinue
                          ? () => context.goNamed('readiness')
                          : null,
                      child: const Text(
                        'Continue',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context, String source) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          source == 'camera'
              ? 'Camera Permission Required'
              : 'Gallery Permission Required',
          style: AppTextStyles.heading2,
        ),
        content: Text(
          source == 'camera'
              ? 'Please allow camera access in your device settings to capture your document.'
              : 'Please allow gallery access in your device settings to select your document.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open app settings
              // openAppSettings(); — add app_settings package if needed
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

// ── Document side card ────────────────────────────────────────
class _DocumentSideCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? uploadedImage;
  final bool isUploaded;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onRetake;

  const _DocumentSideCard({
    required this.label,
    required this.icon,
    required this.uploadedImage,
    required this.isUploaded,
    required this.onCapture,
    required this.onGallery,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(label, style: AppTextStyles.label),
            const SizedBox(width: 8),
            if (isUploaded)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.success,
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (uploadedImage != null) ...[
          // Uploaded image preview with retake overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  uploadedImage!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
              // Retake button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onRetake,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Retake',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Uploaded badge
              if (isUploaded)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Uploaded',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ] else ...[
          // Camera capture button — PRIMARY
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Take a photo',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended for best quality',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Gallery fallback — secondary
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onGallery,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Choose from gallery instead',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tips card ─────────────────────────────────────────────────
class _TipsCard extends StatelessWidget {
  final bool isEgyptian;
  const _TipsCard({required this.isEgyptian});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tips for a good photo', style: AppTextStyles.label),
          const SizedBox(height: 10),
          ...[
            'Place on a flat, dark surface',
            'All four corners must be visible',
            'Avoid glare, shadows, and reflections',
            'All text must be sharply readable',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
