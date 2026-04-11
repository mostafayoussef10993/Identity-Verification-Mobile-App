/// Represents the security status of a user's network connection.
///
/// This model is used to detect and store information about potentially
/// suspicious network conditions such as VPN, Proxy, TOR, or Datacenter IPs.
class NetworkSecurityModel {
  /// The user's public IP address.
  final String publicIp;

  /// Indicates whether the connection is using a VPN.
  final bool isVpn;

  /// Indicates whether the connection is using a Proxy.
  final bool isProxy;

  /// Indicates whether the connection is using the TOR network.
  final bool isTor;

  /// Indicates whether the IP belongs to a datacenter or hosting provider.
  /// Datacenter IPs are often considered suspicious in security contexts.
  final bool isHosting;

  /// The ISO country code of the detected IP address (e.g., 'EG', 'US').
  final String countryCode;

  /// The Internet Service Provider (ISP) name, if available.
  final String? isp;

  /// The timestamp when this network check was performed.
  final DateTime checkedAt;

  const NetworkSecurityModel({
    required this.publicIp,
    required this.isVpn,
    required this.isProxy,
    required this.isTor,
    required this.isHosting,
    required this.countryCode,
    this.isp,
    required this.checkedAt,
  });

  /// Returns `true` if any suspicious network condition is detected.

  bool get isSuspicious => isVpn || isProxy || isTor || isHosting;

  /// Returns a human-readable reason for why the connection is suspicious.

  String get suspicionReason {
    if (isTor) return 'TOR network detected';
    if (isVpn) return 'VPN detected';
    if (isProxy) return 'Proxy detected';
    if (isHosting) return 'Datacenter/hosting IP detected';
    return 'Clean';
  }

  /// Converts the model into a Map for easy JSON serialization or database storage.
  Map<String, dynamic> toMap() => {
    'publicIp': publicIp,
    'isVpn': isVpn,
    'isProxy': isProxy,
    'isTor': isTor,
    'isHosting': isHosting,
    'countryCode': countryCode,
    'isp': isp,
    'isSuspicious': isSuspicious,
    'suspicionReason': suspicionReason,
    'checkedAt': checkedAt.toIso8601String(),
  };
}
