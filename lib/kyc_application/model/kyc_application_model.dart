import 'applicant_type.dart';

//This is the master data model for the entire KYC session
//Identity & Application
class KycApplicationModel {
  final String applicationId;
  final String userId;
  final ApplicantType applicantType;

  // Document images (Cloudinary URLs)
  final String? idFrontUrl;
  final String? idBackUrl; // null for passport
  final String? selfieUrl;

  // OCR extracted data => (Sprint 3)
  final String? fullName;
  final String? idNumber;
  final String? dateOfBirth;
  final String? expiryDate;
  final String? address;
  final String? nationality;

  // Egypt-specific => (Sprint 5)
  final String? motherName;
  final String? fullNameEnglish;

  // Verification scores =>(Sprints 3 & 4)
  final String?
  documentVerificationStatus; // 'genuine','suspicious','needs_review'
  final double? faceMatchScore;
  final bool? livenessPasssed;

  // FATCA => (Sprint 6)
  final bool? isUsPerson;
  final String? taxpayerType; // 'ssn', 'itin', 'ein'
  final String? taxNumber;

  // Proof documents (Sprint 7)
  final String? proofOfAddressUrl;
  final String? proofOfIncomeUrl;

  // Application status
  final String status; // 'draft','pending','approved','rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  const KycApplicationModel({
    required this.applicationId,
    required this.userId,
    required this.applicantType,
    this.idFrontUrl,
    this.idBackUrl,
    this.selfieUrl,
    this.fullName,
    this.idNumber,
    this.dateOfBirth,
    this.expiryDate,
    this.address,
    this.nationality,
    this.motherName,
    this.fullNameEnglish,
    this.documentVerificationStatus,
    this.faceMatchScore,
    this.livenessPasssed,
    this.isUsPerson,
    this.taxpayerType,
    this.taxNumber,
    this.proofOfAddressUrl,
    this.proofOfIncomeUrl,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
  });

  // copyWith
  // lets us update individual fields without recreating the whole object
  KycApplicationModel copyWith({
    String? idFrontUrl,
    String? idBackUrl,
    String? selfieUrl,
    String? fullName,
    String? idNumber,
    String? dateOfBirth,
    String? expiryDate,
    String? address,
    String? nationality,
    String? motherName,
    String? fullNameEnglish,
    String? documentVerificationStatus,
    double? faceMatchScore,
    bool? livenessPasssed,
    bool? isUsPerson,
    String? taxpayerType,
    String? taxNumber,
    String? proofOfAddressUrl,
    String? proofOfIncomeUrl,
    String? status,
  }) {
    return KycApplicationModel(
      applicationId: applicationId,
      userId: userId,
      applicantType: applicantType,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      fullName: fullName ?? this.fullName,
      idNumber: idNumber ?? this.idNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      expiryDate: expiryDate ?? this.expiryDate,
      address: address ?? this.address,
      nationality: nationality ?? this.nationality,
      motherName: motherName ?? this.motherName,
      fullNameEnglish: fullNameEnglish ?? this.fullNameEnglish,
      documentVerificationStatus:
          documentVerificationStatus ?? this.documentVerificationStatus,
      faceMatchScore: faceMatchScore ?? this.faceMatchScore,
      livenessPasssed: livenessPasssed ?? this.livenessPasssed,
      isUsPerson: isUsPerson ?? this.isUsPerson,
      taxpayerType: taxpayerType ?? this.taxpayerType,
      taxNumber: taxNumber ?? this.taxNumber,
      proofOfAddressUrl: proofOfAddressUrl ?? this.proofOfAddressUrl,
      proofOfIncomeUrl: proofOfIncomeUrl ?? this.proofOfIncomeUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
  //Serializes the model to a JSON-compatible Map for saving to Firestore

  Map<String, dynamic> toMap() => {
    'applicationId': applicationId,
    'userId': userId,
    'applicantType': applicantType.firestoreValue,
    'idFrontUrl': idFrontUrl,
    'idBackUrl': idBackUrl,
    'selfieUrl': selfieUrl,
    'fullName': fullName,
    'idNumber': idNumber,
    'dateOfBirth': dateOfBirth,
    'expiryDate': expiryDate,
    'address': address,
    'nationality': nationality,
    'motherName': motherName,
    'fullNameEnglish': fullNameEnglish,
    'documentVerificationStatus': documentVerificationStatus,
    'faceMatchScore': faceMatchScore,
    'livenessPasssed': livenessPasssed,
    'isUsPerson': isUsPerson,
    'taxpayerType': taxpayerType,
    'taxNumber': taxNumber,
    'proofOfAddressUrl': proofOfAddressUrl,
    'proofOfIncomeUrl': proofOfIncomeUrl,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  //Reverses toMap() —
  //reads a Firestore document map and reconstructs the model.
  factory KycApplicationModel.fromMap(Map<String, dynamic> map) =>
      KycApplicationModel(
        applicationId: map['applicationId'] ?? '',
        userId: map['userId'] ?? '',
        applicantType: ApplicantType.fromString(
          map['applicantType'] ?? 'egyptian',
        ),
        idFrontUrl: map['idFrontUrl'],
        idBackUrl: map['idBackUrl'],
        selfieUrl: map['selfieUrl'],
        fullName: map['fullName'],
        idNumber: map['idNumber'],
        dateOfBirth: map['dateOfBirth'],
        expiryDate: map['expiryDate'],
        address: map['address'],
        nationality: map['nationality'],
        motherName: map['motherName'],
        fullNameEnglish: map['fullNameEnglish'],
        documentVerificationStatus: map['documentVerificationStatus'],
        faceMatchScore: map['faceMatchScore']?.toDouble(),
        livenessPasssed: map['livenessPasssed'],
        isUsPerson: map['isUsPerson'],
        taxpayerType: map['taxpayerType'],
        taxNumber: map['taxNumber'],
        proofOfAddressUrl: map['proofOfAddressUrl'],
        proofOfIncomeUrl: map['proofOfIncomeUrl'],
        status: map['status'] ?? 'draft',
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
      );
}
