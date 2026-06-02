// lib/document_verification/repository/document_verification_repository.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// DOCUMENT VERIFICATION REPOSITORY — Cloudinary Stripped
// ══════════════════════════════════════════════════════════════════════════════
//
// SECURITY DECISION: Document images (front, back, portrait) are intentionally
// NOT uploaded to any external service. They remain in device memory only for
// the duration of the KYC session and are used locally for face matching.
//
// What IS stored (Firestore — text fields only):
//   • Extracted identity fields (name, DOB, nationality, etc.)
//   • Arabic fields (fullNameArabic, addressArabic, mothersName)
//   • Egyptian back-side fields (profession, religion, maritalStatus)
//   • Verification status flags (mrzValid, textValid, etc.)
//
// What is NOT stored anywhere external:
//   • Document front/back images
//   • Portrait/biometric images
//   • Any binary image data
//
// Portrait bytes stay in VerificationResultModel.portraitBytes (in memory)
// and are passed directly to the Face SDK for local matching in Sprint 4.
//
// ══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/verification_result_model.dart';
import '../../core/utils/logger.dart';

class DocumentVerificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Save verification results to Firestore (text fields only) ─────────────
  Future<VerificationResultModel> saveVerificationResults({
    required VerificationResultModel result,
    required String userId,
    required String applicationId,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.2);

      // ── Write detailed result to sub-collection ───────────────────────────
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .collection('verification_results')
          .doc('document_scan')
          .set({
            // Identity — Latin
            'surname': result.surname,
            'givenNames': result.givenNames,
            'fullName': result.fullName,
            'fullNameLatin': result.fullNameLatin,

            // Identity — Arabic (Egyptian ID only)
            'fullNameArabic': result.fullNameArabic,
            'surnameArabic': result.surnameArabic,
            'givenNamesArabic': result.givenNamesArabic,
            'addressArabic': result.addressArabic,

            // Egypt-specific back-side fields
            'mothersName': result.mothersName,
            'maritalStatus': result.maritalStatus,
            'religion': result.religion,
            'profession': result.profession,

            // Common fields
            'nationality': result.nationality,
            'dateOfBirth': result.dateOfBirth,
            'dateOfExpiry': result.dateOfExpiry,
            'documentNumber': result.documentNumber,
            'personalNumber': result.personalNumber,
            'address': result.address,
            'sex': result.sex,
            'issuingState': result.issuingState,
            'issuingAuthority': result.issuingAuthority,
            'dateOfIssue': result.dateOfIssue,

            // MRZ
            'mrzLine1': result.mrzLine1,
            'mrzLine2': result.mrzLine2,

            // Document metadata
            'documentTypeName': result.documentTypeName,
            'countryName': result.countryName,
            'icaoCode': result.icaoCode,

            // Verification flags
            'overallStatus': result.overallStatus.name,
            'mrzValid': result.mrzValid,
            'textValid': result.textValid,
            'documentExpired': result.documentExpired,
            'imageQualityOk': result.imageQualityOk,

            // No image URLs — images are local only
            'imagesStoredLocally': true,

            // Audit
            'scannedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          });

      onProgress?.call(0.6);

      // ── Update top-level KYC application document ─────────────────────────
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .update({
            'documentVerificationStatus': result.overallStatus.name,
            'fullName': result.fullName,
            'fullNameLatin': result.fullNameLatin,
            'fullNameArabic': result.fullNameArabic,
            'dateOfBirth': result.dateOfBirth,
            'documentNumber': result.documentNumber,
            'personalNumber': result.personalNumber,
            'nationality': result.nationality,
            'mothersName': result.mothersName,
            'updatedAt': DateTime.now().toIso8601String(),
          });

      onProgress?.call(1.0);

      AppLogger.success(
        'Verification results saved — '
        'applicationId: $applicationId | '
        'status: ${result.overallStatus.name}',
      );

      return result;
    } catch (e) {
      AppLogger.error('saveVerificationResults failed', e);
      // Return result as-is — don't block the KYC flow on a write failure
      return result;
    }
  }
}
