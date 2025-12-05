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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('DeviceSession.fromJson: id is required but was null');
    }
    if (json['device_id'] == null) {
      throw FormatException('DeviceSession.fromJson: device_id is required but was null');
    }
    if (json['device_name'] == null) {
      throw FormatException('DeviceSession.fromJson: device_name is required but was null');
    }
    if (json['device_type'] == null) {
      throw FormatException('DeviceSession.fromJson: device_type is required but was null');
    }
    if (json['platform'] == null) {
      throw FormatException('DeviceSession.fromJson: platform is required but was null');
    }
    if (json['ip_address'] == null) {
      throw FormatException('DeviceSession.fromJson: ip_address is required but was null');
    }
    if (json['location'] == null) {
      throw FormatException('DeviceSession.fromJson: location is required but was null');
    }
    
    return DeviceSession(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      deviceId: json['device_id'].toString(),
      deviceName: json['device_name'].toString(),
      deviceType: json['device_type'].toString(),
      platform: json['platform'].toString(),
      browser: json['browser']?.toString() ?? 'Unknown',
      ipAddress: json['ip_address'].toString(),
      location: json['location'].toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      lastActiveAt: json['last_active_at'] != null
          ? (DateTime.tryParse(json['last_active_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isCurrentDevice: json['is_current_device'] == true || json['is_current_device'] == 1,
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
      if (browser != null) 'browser': browser,
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
