// lib/face_verification/cubit/face_verification_cubit.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// FACE VERIFICATION CUBIT — Fixed
// ══════════════════════════════════════════════════════════════════════════════
//
// FIX: startLiveness() call updated — no longer passes LivenessConfig
// with unverified parameters. Config is now built inside RegulaFaceService
// with only confirmed-safe properties for flutter_face_api ^8.2.1092.
//
// FIX: SDK initialization now also triggered on screen load via initializeSdk()
// which is called from FaceLivenessScreen.initState — not only on button tap.
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_api/flutter_face_api.dart';

import '../../core/utils/logger.dart';
import '../model/face_verification_result_model.dart';
import '../repository/face_verification_repository.dart';
import '../service/regula_face_service.dart';
import 'face_verification_state.dart';

class FaceVerificationCubit extends Cubit<FaceVerificationState> {
  final RegulaFaceService _faceService;
  final FaceVerificationRepository _repository;

  FaceVerificationCubit({
    RegulaFaceService? faceService,
    FaceVerificationRepository? repository,
  }) : _faceService = faceService ?? RegulaFaceService(),
       _repository = repository ?? FaceVerificationRepository(),
       super(const FaceVerificationInitial());

  // ── Initialize SDK on screen load ─────────────────────────────────────────
  // Called from FaceLivenessScreen initState so the SDK warms up before
  // the user taps the button — avoids loading delay on tap.
  Future<void> initializeSdk() async {
    if (_faceService.isInitialized) {
      emit(const FaceVerificationReady());
      return;
    }

    emit(const FaceVerificationLoading('Initializing face engine...'));

    final initialized = await _faceService.initialize();

    if (initialized) {
      emit(const FaceVerificationReady());
    } else {
      emit(
        const FaceVerificationError(
          message:
              'Face verification engine failed to initialize.\n\n'
              'Please ensure your device is supported and try again.',
          canRetry: true,
        ),
      );
    }
  }

  // ── Full face verification flow ───────────────────────────────────────────
  Future<void> startFaceVerification({
    required Uint8List documentPortraitBytes,
    required String applicationId,
    required String userId,
  }) async {
    // Guard: portrait must exist
    if (documentPortraitBytes.isEmpty) {
      emit(
        const FaceVerificationError(
          message:
              'Document portrait is missing.\n'
              'Please go back and rescan your document.',
          canRetry: false,
        ),
      );
      return;
    }

    // Initialize if not already done
    if (!_faceService.isInitialized) {
      emit(const FaceVerificationLoading('Loading face engine...'));

      final initialized = await _faceService.initialize();
      if (!initialized) {
        emit(
          const FaceVerificationError(
            message:
                'Face verification engine failed to initialize.\n'
                'Please try again.',
            canRetry: true,
          ),
        );
        return;
      }
    }

    // ── Step 1: Passive liveness ───────────────────────────────────────────
    emit(const FaceVerificationLoading('Starting liveness check...'));

    try {
      // FIX: No LivenessConfig params passed here — moved into service
      // to avoid compile errors from unverified parameter names
      final livenessResponse = await _faceService.startLiveness();

      if (livenessResponse.liveness != LivenessStatus.PASSED) {
        emit(
          const FaceVerificationError(
            message:
                'Liveness check did not pass.\n\n'
                'Please retry in good lighting with your face '
                'centered on the screen.',
            canRetry: true,
          ),
        );
        return;
      }

      if (livenessResponse.image == null) {
        emit(
          const FaceVerificationError(
            message:
                'Could not capture a valid selfie.\n'
                'Please try again in good lighting.',
            canRetry: true,
          ),
        );
        return;
      }

      // ── Step 2: Face matching ──────────────────────────────────────────
      emit(
        const FaceVerificationLoading('Matching face to document portrait...'),
      );

      final matchScore = await _faceService.matchFaces(
        liveImage: livenessResponse.image!,
        documentPortrait: documentPortraitBytes,
      );

      if (matchScore == null) {
        emit(
          const FaceVerificationError(
            message:
                'Face matching failed.\n'
                'Please ensure your face is clearly visible and try again.',
            canRetry: true,
          ),
        );
        return;
      }

      // ── Step 3: Build result & save ────────────────────────────────────
      final result = FaceVerificationResultModel(
        livenessPassed: livenessResponse.liveness == LivenessStatus.PASSED,
        livenessStatus: livenessResponse.liveness.name,
        matchScore: matchScore,
        applicationId: applicationId,
        userId: userId,
      );

      await _repository.saveFaceResult(
        applicationId: applicationId,
        result: result,
      );

      emit(FaceVerificationSuccess(result));
    } catch (e) {
      AppLogger.error('Face verification failed', e);
      emit(
        FaceVerificationError(
          message: 'Face verification failed: ${e.toString()}',
          canRetry: true,
        ),
      );
    }
  }

  void retry() => emit(const FaceVerificationInitial());
}
