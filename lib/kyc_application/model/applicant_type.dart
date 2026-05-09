// that models three categories of applicants
enum ApplicantType {
  egyptian,
  resident,
  foreigner;

  String get displayName {
    switch (this) {
      case ApplicantType.egyptian:
        return 'Egyptian';
      case ApplicantType.resident:
        return 'Resident';
      case ApplicantType.foreigner:
        return 'Foreigner';
    }
  }
  //Returns the identity document each type uses

  String get documentType {
    switch (this) {
      case ApplicantType.egyptian:
        return 'National ID';
      case ApplicantType.resident:
      case ApplicantType.foreigner:
        return 'Passport';
    }
  }

  // Egyptians need front + back, others just one page
  //Only Egyptians need the back side of their ID scanned
  bool get requiresBackSide => this == ApplicantType.egyptian;

  String get firestoreValue => name; // 'egyptian', 'resident', 'foreigner'

  //Reconstructs an ApplicantType from a stored string.
  //If the value doesn't match any known type,
  //it defaults to ApplicantType.egyptian.
  static ApplicantType fromString(String value) {
    return ApplicantType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApplicantType.egyptian,
    );
  }
}
