import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/document_upload_repository.dart';
import '../service/image_quality_validator.dart';
import '../../core/utils/logger.dart';

part 'document_upload_state.dart';

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  final DocumentUploadRepository _repository;
  final ImageQualityValidator _validator;
  final ImagePicker _picker;

  DocumentUploadCubit({
    DocumentUploadRepository? repository,
    ImageQualityValidator? validator,
    ImagePicker? picker,
  }) : _repository = repository ?? DocumentUploadRepository(),
       _validator = validator ?? ImageQualityValidator(),
       _picker = picker ?? ImagePicker(),
       super(const DocumentUploadInitial());

  // ── CAMERA — primary method ───────────────────────────────────
  Future<void> captureFromCamera({required bool isFrontSide}) async {
    emit(DocumentUploadCapturing(isFrontSide: isFrontSide));
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90, // high quality for document scanning
        preferredCameraDevice: CameraDevice.rear,
      );

      if (picked == null) {
        // User cancelled — go back to initial
        emit(const DocumentUploadInitial());
        return;
      }

      final file = File(picked.path);

      // Show preview before validating
      emit(DocumentUploadPreview(image: file, isFrontSide: isFrontSide));
    } catch (e) {
      AppLogger.error('Camera capture failed', e);

      final isPermissionError =
          e.toString().toLowerCase().contains('permission') ||
          e.toString().toLowerCase().contains('denied');

      if (isPermissionError) {
        emit(const DocumentUploadPermissionDenied(source: 'camera'));
      } else {
        emit(
          DocumentUploadError(
            message: 'Could not access camera. Please try again.',
            isFrontSide: isFrontSide,
          ),
        );
      }
    }
  }

  // ── GALLERY — fallback method ─────────────────────────────────
  Future<void> pickFromGallery({required bool isFrontSide}) async {
    emit(DocumentUploadCapturing(isFrontSide: isFrontSide));
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) {
        emit(const DocumentUploadInitial());
        return;
      }

      final file = File(picked.path);
      emit(DocumentUploadPreview(image: file, isFrontSide: isFrontSide));
    } catch (e) {
      AppLogger.error('Gallery pick failed', e);

      final isPermissionError =
          e.toString().toLowerCase().contains('permission') ||
          e.toString().toLowerCase().contains('denied');

      if (isPermissionError) {
        emit(const DocumentUploadPermissionDenied(source: 'gallery'));
      } else {
        emit(
          DocumentUploadError(
            message: 'Could not access gallery. Please try again.',
            isFrontSide: isFrontSide,
          ),
        );
      }
    }
  }

  // ── CONFIRM — user accepts the preview ───────────────────────
  // Called when user taps "Use this photo" on preview screen
  Future<void> confirmAndValidate({
    required File image,
    required bool isFrontSide,
  }) async {
    emit(DocumentUploadValidating(image: image, isFrontSide: isFrontSide));

    final result = await _validator.validate(image);

    if (!result.passed) {
      AppLogger.warning('Quality check failed: ${result.failureReason}');
      emit(
        DocumentUploadQualityFailed(
          image: image,
          isFrontSide: isFrontSide,
          reason: result.failureReason ?? 'unknown',
        ),
      );
      return;
    }

    // Quality passed — proceed to upload
    await _uploadFile(image: image, isFrontSide: isFrontSide);
  }

  // ── RETAKE — user rejects the preview ────────────────────────
  void retake({required bool isFrontSide}) {
    AppLogger.info('User retaking photo — side: $isFrontSide');
    emit(const DocumentUploadInitial());
  }

  // ── INTERNAL UPLOAD ───────────────────────────────────────────
  Future<void> _uploadFile({
    required File image,
    required bool isFrontSide,
    required String userId,
    required String applicationId,
    required String documentType,
  }) async {
    emit(DocumentUploading(isFrontSide: isFrontSide, progress: 0.0));

    try {
      final side = isFrontSide ? 'front' : 'back';
      final folder = 'kyc/$userId/$documentType';
      final publicId = '${applicationId}_${documentType}_$side';

      final url = await _repository.uploadDocument(
        image: image,
        folder: folder,
        publicId: publicId,
        onProgress: (progress) {
          // Re-emit with updated progress
          emit(DocumentUploading(isFrontSide: isFrontSide, progress: progress));
        },
      );

      emit(
        DocumentUploadSuccess(
          imageUrl: url,
          localImage: image,
          isFrontSide: isFrontSide,
        ),
      );
    } catch (e) {
      AppLogger.error('Upload failed', e);
      emit(
        DocumentUploadError(
          message: 'Upload failed. Please try again.',
          isFrontSide: isFrontSide,
        ),
      );
    }
  }

  // Public upload trigger called after confirmation
  Future<void> uploadConfirmedImage({
    required File image,
    required bool isFrontSide,
    required String userId,
    required String applicationId,
    required String documentType,
  }) async {
    await _uploadFile(
      image: image,
      isFrontSide: isFrontSide,
      userId: userId,
      applicationId: applicationId,
      documentType: documentType,
    );
  }

  void reset() => emit(const DocumentUploadInitial());
}
