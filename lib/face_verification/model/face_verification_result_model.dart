// lib/face_verification/model/face_verification_result_model.dart
//
// Sprint 4 — Face verification result model.
// This model encapsulates the Regula face liveness and match response
// data needed for UI, persistence, and the final face result screen.

class FaceVerificationResultModel {
  final bool livenessPassed;
  final String livenessStatus;
  final double matchScore;
  final String applicationId;
  final String userId;
  final String? errorMessage;

  const FaceVerificationResultModel({
    required this.livenessPassed,
    required this.livenessStatus,
    required this.matchScore,
    required this.applicationId,
    required this.userId,
    this.errorMessage,
  });

  bool get isPassed => livenessPassed && matchScore >= 75.0;

  Map<String, dynamic> toMap() => {
    'livenessPassed': livenessPassed,
    'livenessStatus': livenessStatus,
    'faceMatchScore': matchScore,
    'applicationId': applicationId,
    'userId': userId,
    'errorMessage': errorMessage,
  };
}
