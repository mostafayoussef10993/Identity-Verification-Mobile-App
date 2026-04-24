class UserModel {
  final String uid; // Firebase user ID
  final String phoneNumber;
  final DateTime createdAt;
  final bool kycCompleted;

  const UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.createdAt,
    this.kycCompleted = false,
  });

  // Convert to Map for Firestore storage
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
    'kycCompleted': kycCompleted,
  };

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    phoneNumber: map['phoneNumber'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
    kycCompleted: map['kycCompleted'] ?? false,
  );
}
