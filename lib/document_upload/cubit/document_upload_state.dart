part of 'document_upload_cubit.dart';

abstract class DocumentUploadState {
  const DocumentUploadState();
}

// Nothing happening yet
class DocumentUploadInitial extends DocumentUploadState {
  const DocumentUploadInitial();
}

// User is picking source (camera/gallery bottom sheet showing)
class DocumentUploadSourceSelecting extends DocumentUploadState {
  const DocumentUploadSourceSelecting();
}

// Camera or gallery is opening
class DocumentUploadCapturing extends DocumentUploadState {
  final bool isFrontSide;
  const DocumentUploadCapturing({required this.isFrontSide});
}

// Image captured — showing preview, waiting for user confirmation
class DocumentUploadPreview extends DocumentUploadState {
  final File image;
  final bool isFrontSide;
  const DocumentUploadPreview({required this.image, required this.isFrontSide});
}

// Quality validation running
class DocumentUploadValidating extends DocumentUploadState {
  final File image;
  final bool isFrontSide;
  const DocumentUploadValidating({
    required this.image,
    required this.isFrontSide,
  });
}

// Quality check failed — tell user why
class DocumentUploadQualityFailed extends DocumentUploadState {
  final File image;
  final bool isFrontSide;
  final String reason; // 'too_blurry', 'too_dark', 'too_bright'
  const DocumentUploadQualityFailed({
    required this.image,
    required this.isFrontSide,
    required this.reason,
  });

  String get userMessage {
    switch (reason) {
      case 'too_blurry':
        return 'The image is too blurry. Please retake on a stable surface.';
      case 'too_dark':
        return 'The image is too dark. Please move to a brighter area.';
      case 'too_bright':
        return 'The image has too much glare. Avoid direct light.';
      default:
        return 'Image quality is too low. Please retake.';
    }
  }
}

// Uploading to Cloudinary
class DocumentUploading extends DocumentUploadState {
  final bool isFrontSide;
  final double progress; // 0.0 to 1.0
  const DocumentUploading({required this.isFrontSide, this.progress = 0.0});
}

// Successfully uploaded
class DocumentUploadSuccess extends DocumentUploadState {
  final String imageUrl;
  final File localImage;
  final bool isFrontSide;
  const DocumentUploadSuccess({
    required this.imageUrl,
    required this.localImage,
    required this.isFrontSide,
  });
}

// Permission denied
class DocumentUploadPermissionDenied extends DocumentUploadState {
  final String source; // 'camera' or 'gallery'
  const DocumentUploadPermissionDenied({required this.source});
}

// Any error
class DocumentUploadError extends DocumentUploadState {
  final String message;
  final bool isFrontSide;
  const DocumentUploadError({required this.message, required this.isFrontSide});
}
