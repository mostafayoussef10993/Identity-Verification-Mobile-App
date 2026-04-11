import 'dart:convert';
import 'package:dio/dio.dart';
import '../model/network_security_model.dart';
import '../../core/utils/logger.dart';

/// Service responsible for detecting VPN, Proxy, TOR, and Hosting (datacenter) usage
/// using the free tier of ip-api.com.
///
/// This service makes a real-time check of the user's public IP and returns
/// a [NetworkSecurityModel] containing the security status.
class VpnDetectionService {
  final Dio _dio = Dio();

  /// ip-api.com endpoint (free tier)
  ///
  /// Fields requested: status, message, country, countryCode, isp, query, proxy, hosting, tor
  /// Note: 'proxy' field on free plan also detects most VPNs.
  static const String _ipApiUrl =
      'http://ip-api.com/json/?fields=status,message,country,countryCode,isp,query,proxy,hosting,tor';

  /// Checks the current network connection for suspicious activity.
  /// If the API call fails for any reason, it returns a safe "unknown" result
  /// instead of throwing an error (failsafe design for better UX).
  Future<NetworkSecurityModel> checkNetwork() async {
    try {
      AppLogger.info('Checking network security...');

      final response = await _dio.get(_ipApiUrl);

      if (response.statusCode == 200) {
        // Handle both String and Map response types safely
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        // API returned an error (e.g., rate limit or invalid request)
        if (data['status'] == 'fail') {
          AppLogger.warning('ip-api returned fail: ${data['message']}');
          return _unknownResult();
        }

        // Successfully parsed data → create model
        final result = NetworkSecurityModel(
          publicIp: data['query'] ?? 'unknown',
          isVpn:
              data['proxy'] ??
              false, // Free tier: proxy field also covers many VPNs
          isProxy: data['proxy'] ?? false,
          isTor: data['tor'] ?? false,
          isHosting: data['hosting'] ?? false,
          countryCode: data['countryCode'] ?? 'XX',
          isp: data['isp'],
          checkedAt: DateTime.now(),
        );

        AppLogger.info(
          'Network check complete — suspicious: ${result.isSuspicious} '
          '(${result.suspicionReason})',
        );

        return result;
      }

      // If status code is not 200
      return _unknownResult();
    } on DioException catch (e) {
      AppLogger.error('Network check failed (DioException)', e);
      return _unknownResult();
    } catch (e) {
      AppLogger.error('Network check failed (unexpected)', e);
      return _unknownResult();
    }
  }

  /// Returns a safe default result when the API check fails or is unavailable.
  ///
  /// This design choice ensures the app never blocks the user due to a
  /// network detection failure — it just treats the network as "unverified".
  NetworkSecurityModel _unknownResult() {
    return NetworkSecurityModel(
      publicIp: 'unknown',
      isVpn: false,
      isProxy: false,
      isTor: false,
      isHosting: false,
      countryCode: 'XX',
      isp: 'unknown',
      checkedAt: DateTime.now(),
    );
  }
}
