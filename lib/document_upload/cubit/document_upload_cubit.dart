import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/document_upload_repository.dart';
import '../../core/utils/logger.dart';

part 'document_upload_state.dart';

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  final DocumentUploadRepository _repository;
  final ImagePicker _picker = ImagePicker();

  DocumentUploadCubit({DocumentUploadRepository? repository})
    : _repository = repository ?? DocumentUploadRepository(),
      super(DocumentUploadInitial());

  // Pick from camera
  Future<void> pickFromCamera({required bool isFrontSide}) async {
    emit(DocumentUploadPicking());
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // compress slightly for faster uploads
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked != null) {
        emit(
          DocumentUploadPicked(
            image: File(picked.path),
            isFrontSide: isFrontSide,
          ),
        );
      } else {
        emit(DocumentUploadInitial()); // user cancelled
      }
    } catch (e) {
      AppLogger.error('Camera pick failed', e);
      emit(
        DocumentUploadError(
          'Could not access camera. Please check permissions.',
        ),
      );
    }
  }

  // Pick from gallery
  Future<void> pickFromGallery({required bool isFrontSide}) async {
    emit(DocumentUploadPicking());
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        emit(
          DocumentUploadPicked(
            image: File(picked.path),
            isFrontSide: isFrontSide,
          ),
        );
      } else {
        emit(DocumentUploadInitial());
      }
    } catch (e) {
      AppLogger.error('Gallery pick failed', e);
      emit(
        DocumentUploadError(
          'Could not access gallery. Please check permissions.',
        ),
      );
    }
  }

  // Upload the picked image to Cloudinary
  Future<void> uploadImage({
    required File image,
    required String userId,
    required String applicationId,
    required bool isFrontSide,
    required String documentType, // 'national_id' or 'passport'
  }) async {
    emit(DocumentUploading(isFrontSide: isFrontSide));
    try {
      final side = isFrontSide ? 'front' : 'back';
      final folder = 'kyc/$userId/$documentType';
      final publicId = '${applicationId}_${documentType}_$side';

      final url = await _repository.uploadDocument(
        image: image,
        folder: folder,
        publicId: publicId,
      );

      AppLogger.success('Document uploaded: $url');
      emit(DocumentUploadSuccess(imageUrl: url, isFrontSide: isFrontSide));
    } catch (e) {
      AppLogger.error('Upload failed', e);
      emit(DocumentUploadError('Upload failed. Please try again.'));
    }
  }

  void reset() => emit(DocumentUploadInitial());
}
