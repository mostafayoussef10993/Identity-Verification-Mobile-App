// lib/face_verification/cubit/face_verification_cubit.dart
//
// Sprint 4 — Face verification cubit.
// Manages Regula Face SDK initialization, liveness flow, face matching,
// and persistence of face verification results.

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
              'Face verification engine failed to initialize. Please restart the app.',
          canRetry: true,
        ),
      );
    }
  }

  Future<void> startFaceVerification({
    required Uint8List documentPortraitBytes,
    required String applicationId,
    required String userId,
  }) async {
    if (!_faceService.isInitialized) {
      emit(const FaceVerificationLoading('Loading face engine...'));
      final initialized = await _faceService.initialize();
      if (!initialized) {
        emit(
          const FaceVerificationError(
            message:
                'Face verification engine failed to initialize. Please try again.',
            canRetry: true,
          ),
        );
        return;
      }
    }

    if (documentPortraitBytes.isEmpty) {
      emit(
        const FaceVerificationError(
          message:
              'Document portrait is missing. Cannot continue face verification.',
          canRetry: false,
        ),
      );
      return;
    }

    emit(const FaceVerificationLoading('Starting liveness check...'));

    try {
      final livenessResponse = await _faceService.startLiveness(
        config: LivenessConfig(
          livenessType: LivenessType.PASSIVE,
          cameraSwitchEnabled: true,
          torchButtonEnabled: true,
          attemptsCount: 3,
          preventScreenRecording: true,
          closeButtonEnabled: false,
        ),
      );

      if (livenessResponse.liveness != LivenessStatus.PASSED) {
        emit(
          const FaceVerificationError(
            message:
                'Liveness check did not pass. Please retry and follow the on-screen instructions.',
            canRetry: true,
          ),
        );
        return;
      }

      if (livenessResponse.image == null) {
        emit(
          const FaceVerificationError(
            message:
                'Could not capture a valid selfie. Please try again in good lighting.',
            canRetry: true,
          ),
        );
        return;
      }

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
                'Face matching failed. Please make sure your face is clearly visible and try again.',
            canRetry: true,
          ),
        );
        return;
      }

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
          message: 'Face verification failed. ${e.toString()}',
          canRetry: true,
        ),
      );
    }
  }

  void retry() => emit(const FaceVerificationInitial());
}
