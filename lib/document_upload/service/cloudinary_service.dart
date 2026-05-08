import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/utils/logger.dart';

class CloudinaryService {
  // Replace these with your actual Cloudinary credentials
  static const String _cloudName = 'drfhlsnqv';
  static const String _apiKey = '661996192694877';
  static const String _apiSecret = '7lPMmHYLnHaRf64e4IHM5FpYLNI';
  static const String _uploadPreset =
      'kyc_documents'; // we'll create this below

  final Dio _dio = Dio();

  /// Uploads an image file to Cloudinary and returns the secure URL.
  /// [folder] organizes files e.g. 'kyc/national_id/front'
  Future<String> uploadImage({
    required File imageFile,
    required String folder,
    required String publicId, // unique filename e.g. 'user123_front'
  }) async {
    try {
      AppLogger.info('Uploading to Cloudinary: $folder/$publicId');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: '$publicId.jpg',
        ),
        'upload_preset': _uploadPreset,
        'folder': folder,
        'public_id': publicId,
        'api_key': _apiKey,
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String;
        AppLogger.success('Upload successful: $secureUrl');
        return secureUrl;
      }

      throw Exception('Upload failed with status: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('Cloudinary upload failed', e);
      throw Exception('Failed to upload image. Please check your connection.');
    } catch (e) {
      AppLogger.error('Unexpected upload error', e);
      rethrow;
    }
  }
}
