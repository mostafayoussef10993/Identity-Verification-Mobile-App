import 'package:kyc/document_verification/model/verification_result_model.dart';

abstract class DocumentVerificationState {
  const DocumentVerificationState();
}

/// Default state — cubit just created, nothing started yet.
class DocumentVerificationInitial extends DocumentVerificationState {
  const DocumentVerificationInitial();
}

/// SDK is loading from local asset (db.dat) and initializing.
/// Replaces the old two-state (prepareDatabase + initialize) flow.
/// Since db.dat is local, this takes 1–3 seconds — progress may be reported.
class DocumentVerificationInitializing extends DocumentVerificationState {
  final String message;
  final double? progress;
  const DocumentVerificationInitializing({
    required this.message,
    this.progress,
  });
}

/// SDK initialized — waiting for user to tap "Start Scan".
class DocumentVerificationReady extends DocumentVerificationState {
  const DocumentVerificationReady();
}

/// Regula native scanner UI is currently open and capturing.
class DocumentVerificationScanning extends DocumentVerificationState {
  const DocumentVerificationScanning();
}

/// Scanner returned results — extracting structured data from raw output.
class DocumentVerificationProcessing extends DocumentVerificationState {
  const DocumentVerificationProcessing();
}

/// Extracted text fields are being saved to Firestore.
/// No images are uploaded — document images remain local only.
class DocumentVerificationUploading extends DocumentVerificationState {
  final double progress; // 0.0 → 1.0
  const DocumentVerificationUploading({this.progress = 0.0});
}

/// All steps complete — result is ready for display and navigation.
class DocumentVerificationSuccess extends DocumentVerificationState {
  final VerificationResultModel result;
  const DocumentVerificationSuccess(this.result);
}

/// User pressed Cancel/Back while the Regula scanner was open.
class DocumentVerificationCancelled extends DocumentVerificationState {
  const DocumentVerificationCancelled();
}

/// SDK was accessed before initialize() completed.
class DocumentVerificationNotInitialized extends DocumentVerificationState {
  const DocumentVerificationNotInitialized();
}

/// A step failed — canRetry indicates whether the user can try again.
/// canRetry = false: developer/config issue (license, missing asset)
/// canRetry = true:  user-recoverable issue (bad scan, low quality)
class DocumentVerificationError extends DocumentVerificationState {
  final String message;
  final bool canRetry;
  const DocumentVerificationError({
    required this.message,
    this.canRetry = true,
  });
}
