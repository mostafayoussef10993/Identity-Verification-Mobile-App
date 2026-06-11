// lib/face_verification/cubit/face_verification_state.dart
//
// Sprint 4 — Face verification cubit states.
// Captures liveness, matching, and result flow statuses for the UI.

import '../model/face_verification_result_model.dart';

abstract class FaceVerificationState {
  const FaceVerificationState();
}

class FaceVerificationInitial extends FaceVerificationState {
  const FaceVerificationInitial();
}

class FaceVerificationLoading extends FaceVerificationState {
  final String message;
  const FaceVerificationLoading(this.message);
}

class FaceVerificationReady extends FaceVerificationState {
  const FaceVerificationReady();
}

class FaceVerificationSuccess extends FaceVerificationState {
  final FaceVerificationResultModel result;
  const FaceVerificationSuccess(this.result);
}

class FaceVerificationError extends FaceVerificationState {
  final String message;
  final bool canRetry;
  const FaceVerificationError({required this.message, this.canRetry = true});
}

class FaceVerificationNotInitialized extends FaceVerificationState {
  const FaceVerificationNotInitialized();
}
