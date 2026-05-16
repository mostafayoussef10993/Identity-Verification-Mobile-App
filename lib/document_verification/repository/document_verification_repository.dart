import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/verification_result_model.dart';
import '../../document_upload/service/cloudinary_service.dart';
import '../../core/utils/logger.dart';

class DocumentVerificationRepository {
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VerificationResultModel> uploadVerificationAssets({
    required VerificationResultModel result,
    required String userId,
    required String applicationId,
    Function(double)? onProgress,
  }) async {
    try {
      // FIX: portrait is now Uint8List — write to temp file then upload
      if (result.portraitBytes != null) {
        onProgress?.call(0.2);
        AppLogger.info('Uploading portrait...');

        final portraitUrl = await _uploadBytesAsImage(
          bytes: result.portraitBytes!,
          folder: 'kyc/$userId/portrait',
          publicId: '${applicationId}_portrait',
        );
        result.portraitCloudUrl = portraitUrl;
        onProgress?.call(0.7);
      }

      onProgress?.call(0.85);

      // Save to Firestore
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
      AppLogger.success('Verification results saved');
      return result;
    } catch (e) {
      AppLogger.error('uploadVerificationAssets failed', e);
      return result;
    }
  }

  // FIX: takes Uint8List directly — no base64 conversion needed
  Future<String> _uploadBytesAsImage({
    required Uint8List bytes,
    required String folder,
    required String publicId,
  }) async {
    // Write bytes to temp file
    final tempFile = File('${Directory.systemTemp.path}/$publicId.jpg');
    await tempFile.writeAsBytes(bytes);

    final url = await _cloudinary.uploadImage(
      imageFile: tempFile,
      folder: folder,
      publicId: publicId,
    );

    // Clean up
    if (await tempFile.exists()) await tempFile.delete();
    return url;
  }
}
