import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/vpn_detection_service.dart';
import '../model/network_security_model.dart';
import '../../core/utils/logger.dart';

class DeviceIntelligenceRepository {
  final VpnDetectionService _vpnService = VpnDetectionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the result so the caller can decide what to show the user.
  /// Also stores the result in Firestore under 'network_checks'.
  Future<NetworkSecurityModel> runCheck({String? userId}) async {
    final result = await _vpnService.checkNetwork();

    // Store in Firestore regardless of result
    try {
      final docRef = _firestore.collection('network_checks').doc();
      await docRef.set({
        ...result.toMap(),
        'userId': userId ?? 'anonymous',
      });
      AppLogger.success('Network check logged to Firestore');
    } catch (e) {
      // Don't block the app if Firestore write fails
      AppLogger.error('Failed to log network check to Firestore', e);
    }

    return result;
  }
}