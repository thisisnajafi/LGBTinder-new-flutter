/// Promotional banner model
/// Part of the Marketing System Implementation (Task 3.1.3)
class BannerModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? actionUrl;
  final String actionType; // url, screen, promotion, plan
  final Map<String, dynamic>? actionData;
  final String position; // home, discover, chat, profile, settings, plans, matches
  final String bannerType; // hero, interstitial, sticky, popup
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isDismissible;
  final bool isActive;
  final int priority;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.actionUrl,
    required this.actionType,
    this.actionData,
    required this.position,
    required this.bannerType,
    this.startDate,
    this.endDate,
    this.isDismissible = true,
    this.isActive = true,
    this.priority = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString(),
      actionUrl: json['action_url']?.toString(),
      actionType: json['action_type']?.toString() ?? 'url',
      actionData: json['action_data'] as Map<String, dynamic>?,
      position: json['position']?.toString() ?? 'home',
      bannerType: json['banner_type']?.toString() ?? 'hero',
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      isDismissible: _parseBool(json['is_dismissible'], defaultValue: true),
      isActive: _parseBool(json['is_active'], defaultValue: true),
      priority: _parseInt(json['priority']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (imageUrl != null) 'image_url': imageUrl,
      if (actionUrl != null) 'action_url': actionUrl,
      'action_type': actionType,
      if (actionData != null) 'action_data': actionData,
      'position': position,
      'banner_type': bannerType,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'is_dismissible': isDismissible,
      'is_active': isActive,
      'priority': priority,
    };
  }

  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

