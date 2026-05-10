part of 'document_upload_cubit.dart';

abstract class DocumentUploadState {}

class DocumentUploadInitial extends DocumentUploadState {}

class DocumentUploadPicking extends DocumentUploadState {}

class DocumentUploadPicked extends DocumentUploadState {
  final File image;
  final bool isFrontSide;
  DocumentUploadPicked({required this.image, required this.isFrontSide});
}

class DocumentUploading extends DocumentUploadState {
  final bool isFrontSide;
  DocumentUploading({required this.isFrontSide});
}

class DocumentUploadSuccess extends DocumentUploadState {
  final String imageUrl;
  final bool isFrontSide;
  DocumentUploadSuccess({required this.imageUrl, required this.isFrontSide});
}

class DocumentUploadError extends DocumentUploadState {
  final String message;
  DocumentUploadError(this.message);
}
