/// Device session model
class DeviceSession {
  final int id;
  final String deviceId;
  final String deviceName;
  final String deviceType; // 'mobile', 'tablet', 'desktop', 'web'
  final String platform; // 'ios', 'android', 'web', 'windows', 'macos'
  final String browser; // for web sessions
  final String ipAddress;
  final String location;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isCurrentDevice;
  final bool isTrusted;
  final Map<String, dynamic> deviceInfo;

  DeviceSession({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    this.browser = 'Unknown',
    required this.ipAddress,
    required this.location,
    required this.createdAt,
    required this.lastActiveAt,
    this.isCurrentDevice = false,
    this.isTrusted = false,
    this.deviceInfo = const {},
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw FormatException('DeviceSession.fromJson: id is required but was null');
    }

    final lastActiveRaw = json['last_active_at'] ?? json['last_active'];
    final deviceName = json['device_name'] ?? json['device'] ?? 'Unknown device';
    final deviceId = json['device_id'] ?? json['session_id'] ?? json['id'];

    return DeviceSession(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      deviceId: deviceId.toString(),
      deviceName: deviceName.toString(),
      deviceType: json['device_type']?.toString() ?? 'mobile',
      platform: json['platform']?.toString() ?? 'unknown',
      browser: json['browser']?.toString() ?? 'Unknown',
      ipAddress: json['ip_address']?.toString() ?? '—',
      location: json['location']?.toString() ?? 'Unknown',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      lastActiveAt: lastActiveRaw != null
          ? (DateTime.tryParse(lastActiveRaw.toString()) ?? DateTime.now())
          : DateTime.now(),
      isCurrentDevice: json['is_current_device'] == true ||
          json['is_current_device'] == 1 ||
          json['is_current'] == true ||
          json['is_current'] == 1,
      isTrusted: json['is_trusted'] == true || json['is_trusted'] == 1,
      deviceInfo: json['device_info'] != null && json['device_info'] is Map
          ? Map<String, dynamic>.from(json['device_info'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'platform': platform,
      'browser': browser,
      'ip_address': ipAddress,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'is_current_device': isCurrentDevice,
      'is_trusted': isTrusted,
      'device_info': deviceInfo,
    };
  }

  /// Get formatted device display name
  String get displayName {
    if (deviceName.isNotEmpty) {
      return deviceName;
    }
    return '$platform ${deviceType.toUpperCase()}';
  }

  /// Get device icon based on platform
  String get deviceIcon {
    switch (platform.toLowerCase()) {
      case 'ios':
        return 'phone_iphone';
      case 'android':
        return 'phone_android';
      case 'web':
        return 'web';
      case 'windows':
        return 'computer';
      case 'macos':
        return 'desktop_mac';
      case 'linux':
        return 'desktop_windows'; // fallback
      default:
        return 'device_unknown';
    }
  }

  /// Check if session is active (used within last 30 minutes)
  bool get isActive {
    final thirtyMinutesAgo = DateTime.now().subtract(const Duration(minutes: 30));
    return lastActiveAt.isAfter(thirtyMinutesAgo);
  }

  /// Get time since last activity
  String get timeSinceLastActive {
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Revoke session request
class RevokeSessionRequest {
  final int sessionId;

  RevokeSessionRequest({required this.sessionId});

  Map<String, dynamic> toJson() {
    return {'session_id': sessionId};
  }
}

/// Trust device request
class TrustDeviceRequest {
  final int sessionId;

  TrustDeviceRequest({required this.sessionId});

  Map<String, dynamic> toJson() {
    return {'session_id': sessionId};
  }
}
