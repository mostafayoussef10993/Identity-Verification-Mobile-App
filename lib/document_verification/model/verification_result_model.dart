// lib/document_verification/model/verification_result_model.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// VERIFICATION RESULT MODEL — Updated for Arabic/Egyptian ID support
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

class VerificationResultModel {
  // ── Latin identity fields (all document types) ────────────────────────────
  final String? surname;
  final String? givenNames;

  /// Primary display name.
  /// Egyptian: Arabic Unicode (ft_Name_Local) if available, else Latin.
  /// Passport: Latin only.
  final String? fullName;

  /// Always Latin — for backend/AML matching.
  final String? fullNameLatin;

  // ── Arabic identity fields (Egyptian National ID only) ───────────────────
  /// Arabic name from ft_Name_Local (field type 1268).
  /// Proper Arabic Unicode — NOT garbled Latin transliteration.
  final String? fullNameArabic;
  final String? surnameArabic;
  final String? givenNamesArabic;

  /// Arabic address — from Egyptian ID back side.
  final String? addressArabic;

  // ── Egyptian-specific back-side fields ───────────────────────────────────
  final String? mothersName; // Egypt KYC requirement
  final String? maritalStatus; // Egyptian ID back side
  final String? religion; // Egyptian ID back side
  final String? profession; // Egyptian ID back side

  // ── Common fields ─────────────────────────────────────────────────────────
  final String? nationality;
  final String? dateOfBirth;
  final String? dateOfExpiry;
  final String? documentNumber;
  final String? personalNumber;
  final String? address;
  final String? sex;
  final String? issuingState;
  final String? issuingAuthority;
  final String? dateOfIssue;

  // ── MRZ ───────────────────────────────────────────────────────────────────
  final String? mrzLine1;
  final String? mrzLine2;
  final String? mrzLine3;

  // ── Document metadata ─────────────────────────────────────────────────────
  final String? documentTypeName;
  final String? countryName;
  final String? icaoCode;

  // ── Verification status ───────────────────────────────────────────────────
  final VerificationStatus overallStatus;
  final bool mrzValid;
  final bool textValid;
  final bool documentExpired;
  final bool imageQualityOk;

  // ── Biometric ─────────────────────────────────────────────────────────────
  final Uint8List? portraitBytes;

  // ── Image storage policy ──────────────────────────────────────────────────
  // Document images (front/back) are NOT uploaded anywhere.
  // They stay on-device only. Portrait bytes are kept in memory
  // exclusively for Face SDK matching during the same session.

  VerificationResultModel({
    this.surname,
    this.givenNames,
    this.fullName,
    this.fullNameLatin,
    this.fullNameArabic,
    this.surnameArabic,
    this.givenNamesArabic,
    this.addressArabic,
    this.mothersName,
    this.maritalStatus,
    this.religion,
    this.profession,
    this.nationality,
    this.dateOfBirth,
    this.dateOfExpiry,
    this.documentNumber,
    this.personalNumber,
    this.address,
    this.sex,
    this.issuingState,
    this.issuingAuthority,
    this.dateOfIssue,
    this.mrzLine1,
    this.mrzLine2,
    this.mrzLine3,
    this.documentTypeName,
    this.countryName,
    this.icaoCode,
    required this.overallStatus,
    this.mrzValid = false,
    this.textValid = false,
    this.documentExpired = false,
    this.imageQualityOk = true,
    this.portraitBytes,
  });

  bool get hasArabicName =>
      fullNameArabic != null && fullNameArabic!.isNotEmpty;
  bool get hasEgyptBackSideData =>
      maritalStatus != null || religion != null || profession != null;

  Map<String, dynamic> toMap() => {
    'surname': surname,
    'givenNames': givenNames,
    'fullName': fullName,
    'fullNameLatin': fullNameLatin,
    'fullNameArabic': fullNameArabic,
    'surnameArabic': surnameArabic,
    'givenNamesArabic': givenNamesArabic,
    'addressArabic': addressArabic,
    'mothersName': mothersName,
    'maritalStatus': maritalStatus,
    'religion': religion,
    'profession': profession,
    'nationality': nationality,
    'dateOfBirth': dateOfBirth,
    'dateOfExpiry': dateOfExpiry,
    'documentNumber': documentNumber,
    'personalNumber': personalNumber,
    'address': address,
    'sex': sex,
    'issuingState': issuingState,
    'issuingAuthority': issuingAuthority,
    'dateOfIssue': dateOfIssue,
    'mrzLine1': mrzLine1,
    'mrzLine2': mrzLine2,
    'mrzLine3': mrzLine3,
    'documentTypeName': documentTypeName,
    'countryName': countryName,
    'icaoCode': icaoCode,
    'overallStatus': overallStatus.name,
    'mrzValid': mrzValid,
    'textValid': textValid,
    'documentExpired': documentExpired,
    'imageQualityOk': imageQualityOk,
    // Note: no image URLs — document images stay on device only
  };
}

enum VerificationStatus {
  genuine, // CheckResult.OK
  suspicious, // CheckResult error
  needsReview, // CheckResult.WAS_NOT_DONE
  failed, // Processing exception
}
