import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/verification_result_model.dart';
import '../../document_upload/service/cloudinary_service.dart';
import '../../core/utils/logger.dart';

class DocumentVerificationRepository {
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads portrait image to Cloudinary and saves results to Firestore.
  Future<VerificationResultModel> uploadVerificationAssets({
    required VerificationResultModel result,
    required String userId,
    required String applicationId,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload portrait if available
      if (result.portraitImageBase64 != null) {
        onProgress?.call(0.2);
        AppLogger.info('Uploading portrait to Cloudinary...');

        final portraitUrl = await _uploadBase64Image(
          base64Data: result.portraitImageBase64!,
          folder: 'kyc/$userId/portrait',
          publicId: '${applicationId}_portrait',
        );
        result.portraitCloudUrl = portraitUrl;
        onProgress?.call(0.7);
      }

      onProgress?.call(0.85);

      // Save full verification results to Firestore
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .collection('verification_results')
          .doc('document_scan')
          .set({
            ...result.toMap(),
            'scannedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          });

      // Also update the parent application document
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .update({
            'documentVerificationStatus': result.overallStatus.name,
            'fullName': result.fullName,
            'dateOfBirth': result.dateOfBirth,
            'documentNumber': result.documentNumber,
            'personalNumber': result.personalNumber,
            'nationality': result.nationality,
            'portraitCloudUrl': result.portraitCloudUrl,
            'updatedAt': DateTime.now().toIso8601String(),
          });

      onProgress?.call(1.0);
      AppLogger.success('Verification assets saved to Firestore');

      return result;
    } catch (e) {
      AppLogger.error('uploadVerificationAssets failed', e);
      // Return result even if upload fails — data still extracted
      return result;
    }
  }

  Future<String> _uploadBase64Image({
    required String base64Data,
    required String folder,
    required String publicId,
  }) async {
    // Remove data URL prefix if present
    final cleanBase64 = base64Data.contains(',')
        ? base64Data.split(',').last
        : base64Data;

    final bytes = base64Decode(cleanBase64);

    // Write to temp file then upload
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/$publicId.jpg');
    await tempFile.writeAsBytes(bytes);

    final url = await _cloudinary.uploadImage(
      imageFile: tempFile,
      folder: folder,
      publicId: publicId,
    );

    // Clean up temp file
    if (await tempFile.exists()) await tempFile.delete();

    return url;
  }
}
