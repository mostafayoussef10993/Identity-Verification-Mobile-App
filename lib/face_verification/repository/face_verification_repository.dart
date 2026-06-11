// lib/face_verification/repository/face_verification_repository.dart
//
// Sprint 4 — Face verification persistence repository.
// Saves the face match score and liveness pass state to Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/face_verification_result_model.dart';
import '../../core/utils/logger.dart';

class FaceVerificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FaceVerificationResultModel> saveFaceResult({
    required String applicationId,
    required FaceVerificationResultModel result,
  }) async {
    try {
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .update({
            'faceMatchScore': result.matchScore,
            'livenessPasssed': result.livenessPassed,
            'updatedAt': DateTime.now().toIso8601String(),
          });

      AppLogger.success('Face verification saved: $applicationId');
    } catch (e) {
      AppLogger.error('Failed to save face verification result', e);
    }

    return result;
  }
}
