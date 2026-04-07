// This class defines custom exception types so
//the app gives meaningful errors

class AppException implements Exception {
  final String message;
  final String? code;
  const AppException({required this.message, this.code});
  @override
  String toString() => 'AppException :$message (code:$code)';
}

// Network API Failures
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network Error,please check your connection',
    super.code,
  });
}

// Firebase-specific failures
class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

class FirestoreException extends AppException {
  const FirestoreException({required super.message, super.code});
}

// Document/scanning failures
class ScanException extends AppException {
  const ScanException({required super.message, super.code});
}

// Generic unexpected failure
class UnexpectedException extends AppException {
  const UnexpectedException({
    super.message = 'An unexpected error occurred.',
    super.code,
  });
}
