/// System health model for monitoring server status
class SystemHealth {
  final String status; // 'healthy', 'warning', 'critical'
  final double uptime; // in hours
  final SystemResources resources;
  final List<ServiceStatus> services;
  final DateTime lastChecked;
  final Map<String, dynamic> details;

  SystemHealth({
    required this.status,
    required this.uptime,
    required this.resources,
    required this.services,
    required this.lastChecked,
    required this.details,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    return SystemHealth(
      status: json['status'] as String? ?? 'unknown',
      uptime: (json['uptime'] as num?)?.toDouble() ?? 0.0,
      resources: json['resources'] != null
          ? SystemResources.fromJson(json['resources'] as Map<String, dynamic>)
          : SystemResources.empty(),
      services: json['services'] != null
          ? (json['services'] as List)
              .map((e) => ServiceStatus.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      lastChecked: json['last_checked'] != null
          ? DateTime.parse(json['last_checked'] as String)
          : DateTime.now(),
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'uptime': uptime,
      'resources': resources.toJson(),
      'services': services.map((e) => e.toJson()).toList(),
      'last_checked': lastChecked.toIso8601String(),
      'details': details,
    };
  }

  /// Check if system is healthy
  bool get isHealthy => status == 'healthy';

  /// Check if system has warnings
  bool get hasWarnings => status == 'warning';

  /// Check if system is critical
  bool get isCritical => status == 'critical';

  /// Get uptime as formatted string
  String get uptimeFormatted {
    final days = uptime ~/ 24;
    final hours = uptime % 24;
    if (days > 0) {
      return '${days}d ${hours}h';
    } else {
      return '${hours.toStringAsFixed(1)}h';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'healthy':
        return 'green';
      case 'warning':
        return 'orange';
      case 'critical':
        return 'red';
      default:
        return 'grey';
    }
  }
}

/// System resources model
class SystemResources {
  final double cpuUsage; // percentage 0-100
  final double memoryUsage; // percentage 0-100
  final double diskUsage; // percentage 0-100
  final int activeConnections;
  final double responseTime; // in milliseconds

  SystemResources({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.activeConnections,
    required this.responseTime,
  });

  factory SystemResources.fromJson(Map<String, dynamic> json) {
    return SystemResources(
      cpuUsage: (json['cpu_usage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (json['memory_usage'] as num?)?.toDouble() ?? 0.0,
      diskUsage: (json['disk_usage'] as num?)?.toDouble() ?? 0.0,
      activeConnections: json['active_connections'] as int? ?? 0,
      responseTime: (json['response_time'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory SystemResources.empty() {
    return SystemResources(
      cpuUsage: 0.0,
      memoryUsage: 0.0,
      diskUsage: 0.0,
      activeConnections: 0,
      responseTime: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'disk_usage': diskUsage,
      'active_connections': activeConnections,
      'response_time': responseTime,
    };
  }

  /// Check if CPU usage is high
  bool get isCpuHigh => cpuUsage > 80;

  /// Check if memory usage is high
  bool get isMemoryHigh => memoryUsage > 85;

  /// Check if disk usage is high
  bool get isDiskHigh => diskUsage > 90;

  /// Check if response time is slow
  bool get isResponseTimeSlow => responseTime > 1000; // > 1 second
}

/// Service status model
class ServiceStatus {
  final String name;
  final String status; // 'running', 'stopped', 'error'
  final String? errorMessage;
  final DateTime lastChecked;

  ServiceStatus({
    required this.name,
    required this.status,
    this.errorMessage,
    required this.lastChecked,
  });

  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    return ServiceStatus(
      name: json['name'] as String,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      lastChecked: json['last_checked'] != null
          ? DateTime.parse(json['last_checked'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      'last_checked': lastChecked.toIso8601String(),
    };
  }

  /// Check if service is running
  bool get isRunning => status == 'running';

  /// Check if service has error
  bool get hasError => status == 'error';
}

/// System notification request
class SystemNotificationRequest {
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'error', 'maintenance'
  final List<String>? targetUsers; // null means all users
  final DateTime? scheduledTime;
  final Map<String, dynamic> metadata;

  SystemNotificationRequest({
    required this.title,
    required this.message,
    required this.type,
    this.targetUsers,
    this.scheduledTime,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      if (targetUsers != null) 'target_users': targetUsers,
      if (scheduledTime != null) 'scheduled_time': scheduledTime!.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// App configuration model
class AppConfiguration {
  final Map<String, dynamic> settings;
  final Map<String, dynamic> features;
  final Map<String, dynamic> limits;
  final DateTime lastUpdated;

  AppConfiguration({
    required this.settings,
    required this.features,
    required this.limits,
    required this.lastUpdated,
  });

  factory AppConfiguration.fromJson(Map<String, dynamic> json) {
    return AppConfiguration(
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : {},
      features: json['features'] != null
          ? Map<String, dynamic>.from(json['features'] as Map)
          : {},
      limits: json['limits'] != null
          ? Map<String, dynamic>.from(json['limits'] as Map)
          : {},
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': settings,
      'features': features,
      'limits': limits,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Get setting value with fallback
  T getSetting<T>(String key, T fallback) {
    final value = settings[key];
    if (value != null && value is T) {
      return value;
    }
    return fallback;
  }

  /// Get feature flag
  bool getFeatureFlag(String key, {bool fallback = false}) {
    final value = features[key];
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  /// Get limit value
  int getLimit(String key, {int fallback = 0}) {
    final value = limits[key];
    if (value is int) {
      return value;
    }
    return fallback;
  }
}

/// Update app configuration request
class UpdateAppConfigurationRequest {
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? features;
  final Map<String, dynamic>? limits;

  UpdateAppConfigurationRequest({
    this.settings,
    this.features,
    this.limits,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (settings != null) data['settings'] = settings;
    if (features != null) data['features'] = features;
    if (limits != null) data['limits'] = limits;
    return data;
  }
}
