/// Structured model holding everything Regula extracts from a document.
/// Maps directly to Regula's results structure from the official docs.
class VerificationResultModel {
  // ── Identity fields (from textResult) ──────────────────────
  final String? surname;
  final String? givenNames;
  final String? fullName;
  final String? nationality;
  final String? dateOfBirth;
  final String? dateOfExpiry;
  final String? documentNumber;
  final String? personalNumber; // National ID number for Egyptian IDs
  final String? address;
  final String? sex;
  final String? issuingState;
  final String? issuingAuthority;
  final String? dateOfIssue;

  // ── MRZ fields ───────────────────────────────────────────────
  final String? mrzLine1;
  final String? mrzLine2;
  final String? mrzLine3;

  // ── Document metadata ────────────────────────────────────────
  final String? documentTypeName; // e.g. "National Identity Card"
  final String? countryName; // e.g. "Egypt"
  final String? icaoCode; // e.g. "EGY"

  // ── Verification status ──────────────────────────────────────
  final VerificationStatus overallStatus;
  final bool mrzValid;
  final bool textValid;
  final bool documentExpired;
  final bool imageQualityOk;

  // ── Portrait image (base64 or bytes reference) ───────────────
  final String? portraitImageBase64;

  // ── Cloudinary URLs (set after upload) ───────────────────────
  String? documentFrontUrl;
  String? documentBackUrl;
  String? portraitCloudUrl;

  VerificationResultModel({
    this.surname,
    this.givenNames,
    this.fullName,
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
    this.portraitImageBase64,
    this.documentFrontUrl,
    this.documentBackUrl,
    this.portraitCloudUrl,
  });

  Map<String, dynamic> toMap() => {
    'surname': surname,
    'givenNames': givenNames,
    'fullName': fullName,
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
    'documentFrontUrl': documentFrontUrl,
    'documentBackUrl': documentBackUrl,
    'portraitCloudUrl': portraitCloudUrl,
  };
}

enum VerificationStatus {
  genuine, // CheckResult = OK (1)
  suspicious, // CheckResult = WAS_READ_WITH_ERRORS (2)
  needsReview, // CheckResult = NOT_DONE (0) or unknown
  failed, // Error during processing
}
