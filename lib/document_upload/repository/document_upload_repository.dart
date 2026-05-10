import 'dart:io';
import '../service/cloudinary_service.dart';

class DocumentUploadRepository {
  final CloudinaryService _cloudinary = CloudinaryService();

  Future<String> uploadDocument({
    required File image,
    required String folder,
    required String publicId,
  }) async {
    return await _cloudinary.uploadImage(
      imageFile: image,
      folder: folder,
      publicId: publicId,
    );
  }
}
