import 'package:kyc/document_verification/model/verification_result_model.dart';

abstract class DocumentVerificationState {
  const DocumentVerificationState();
}

class DocumentVerificationInitial extends DocumentVerificationState {
  const DocumentVerificationInitial();
}

// SDK is downloading database / initializing
class DocumentVerificationInitializing extends DocumentVerificationState {
  final String message;
  final double? progress;
  const DocumentVerificationInitializing({
    required this.message,
    this.progress,
  });
}

// SDK ready — waiting for user to start scan
class DocumentVerificationReady extends DocumentVerificationState {
  const DocumentVerificationReady();
}

// Native Regula scanner is open
class DocumentVerificationScanning extends DocumentVerificationState {
  const DocumentVerificationScanning();
}

// Regula returned results — extracting structured data
class DocumentVerificationProcessing extends DocumentVerificationState {
  const DocumentVerificationProcessing();
}

// Uploading extracted images to Cloudinary
class DocumentVerificationUploading extends DocumentVerificationState {
  final double progress;
  const DocumentVerificationUploading({this.progress = 0.0});
}

// Everything done — results ready
class DocumentVerificationSuccess extends DocumentVerificationState {
  final VerificationResultModel result;
  const DocumentVerificationSuccess(this.result);
}

// User cancelled the Regula scanner
class DocumentVerificationCancelled extends DocumentVerificationState {
  const DocumentVerificationCancelled();
}

// SDK not initialized — show error
class DocumentVerificationNotInitialized extends DocumentVerificationState {
  const DocumentVerificationNotInitialized();
}

// Any failure
class DocumentVerificationError extends DocumentVerificationState {
  final String message;
  final bool canRetry;
  const DocumentVerificationError({
    required this.message,
    this.canRetry = true,
  });
}
