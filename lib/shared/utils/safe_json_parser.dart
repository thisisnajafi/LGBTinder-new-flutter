/// CODE QUALITY (Task 8.2.2): Safe JSON Parsing Utilities
/// 
/// Provides type-safe parsing functions to prevent crashes from malformed API responses.
/// Use these functions in all model `fromJson` methods.
///
/// ## Usage
/// ```dart
/// factory MyModel.fromJson(Map<String, dynamic> json) {
///   return MyModel(
///     id: SafeJsonParser.parseInt(json['id'], defaultValue: 0),
///     name: SafeJsonParser.parseString(json['name'], defaultValue: ''),
///     isActive: SafeJsonParser.parseBool(json['is_active'], defaultValue: false),
///     createdAt: SafeJsonParser.parseDateTime(json['created_at']),
///     tags: SafeJsonParser.parseList<String>(json['tags'], (e) => e.toString()),
///   );
/// }
/// ```
///
/// ## Field Guidelines (Based on API Response Audit)
///
/// | Field Type | Required Fields | Nullable Fields |
/// |------------|-----------------|-----------------|
/// | User | `id`, `firstName` | `lastName`, `avatar`, `bio` |
/// | Message | `id`, `senderId`, `receiverId`, `message` | `attachmentUrl`, `metadata` |
/// | Notification | `id`, `type` | `userId`, `userImageUrl`, `data` |
/// | Call | `id`, `callerId`, `receiverId`, `type` | `duration`, `endedAt` |
/// | DiscoveryProfile | `id`, `firstName` | All other fields |

class SafeJsonParser {
  /// Parse an integer from various input types
  /// 
  /// Handles: int, double, String, null
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parse a nullable integer
  static int? parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parse a double from various input types
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parse a nullable double
  static double? parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse a boolean from various input types
  /// 
  /// Handles: bool, int (0/1), String ('true'/'false', '0'/'1')
  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return defaultValue;
  }

  /// Parse a nullable boolean
  static bool? parseBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return null;
  }

  /// Parse a string, converting other types if needed
  static String parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Parse a nullable string
  static String? parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isNotEmpty ? value : null;
    final str = value.toString();
    return str.isNotEmpty ? str : null;
  }

  /// Parse a DateTime from string or DateTime
  static DateTime parseDateTime(dynamic value, {DateTime? defaultValue}) {
    final parsed = parseDateTimeOrNull(value);
    return parsed ?? defaultValue ?? DateTime.now();
  }

  /// Parse a nullable DateTime
  static DateTime? parseDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Parse a list with type conversion
  static List<T> parseList<T>(
    dynamic value,
    T Function(dynamic) converter, {
    List<T>? defaultValue,
  }) {
    if (value == null) return defaultValue ?? <T>[];
    if (value is! List) return defaultValue ?? <T>[];
    
    return value
        .map((item) {
          try {
            return converter(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  /// Parse a nullable list
  static List<T>? parseListOrNull<T>(
    dynamic value,
    T Function(dynamic) converter,
  ) {
    if (value == null) return null;
    if (value is! List) return null;
    
    final result = value
        .map((item) {
          try {
            return converter(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();
    
    return result.isEmpty ? null : result;
  }

  /// Parse a map with type safety
  static Map<String, dynamic> parseMap(
    dynamic value, {
    Map<String, dynamic>? defaultValue,
  }) {
    if (value == null) return defaultValue ?? {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return defaultValue ?? {};
  }

  /// Parse a nullable map
  static Map<String, dynamic>? parseMapOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Parse enum from string
  static T parseEnum<T extends Enum>(
    dynamic value,
    List<T> values, {
    required T defaultValue,
  }) {
    if (value == null) return defaultValue;
    final stringValue = value.toString().toLowerCase();
    
    for (final enumValue in values) {
      if (enumValue.name.toLowerCase() == stringValue) {
        return enumValue;
      }
    }
    return defaultValue;
  }

  /// Parse nullable enum from string
  static T? parseEnumOrNull<T extends Enum>(
    dynamic value,
    List<T> values,
  ) {
    if (value == null) return null;
    final stringValue = value.toString().toLowerCase();
    
    for (final enumValue in values) {
      if (enumValue.name.toLowerCase() == stringValue) {
        return enumValue;
      }
    }
    return null;
  }
}

/// Extension methods for convenient access on Map<String, dynamic>
extension SafeJsonMapExtension on Map<String, dynamic> {
  int getInt(String key, {int defaultValue = 0}) =>
      SafeJsonParser.parseInt(this[key], defaultValue: defaultValue);

  int? getIntOrNull(String key) => SafeJsonParser.parseIntOrNull(this[key]);

  double getDouble(String key, {double defaultValue = 0.0}) =>
      SafeJsonParser.parseDouble(this[key], defaultValue: defaultValue);

  double? getDoubleOrNull(String key) =>
      SafeJsonParser.parseDoubleOrNull(this[key]);

  bool getBool(String key, {bool defaultValue = false}) =>
      SafeJsonParser.parseBool(this[key], defaultValue: defaultValue);

  bool? getBoolOrNull(String key) => SafeJsonParser.parseBoolOrNull(this[key]);

  String getString(String key, {String defaultValue = ''}) =>
      SafeJsonParser.parseString(this[key], defaultValue: defaultValue);

  String? getStringOrNull(String key) =>
      SafeJsonParser.parseStringOrNull(this[key]);

  DateTime getDateTime(String key, {DateTime? defaultValue}) =>
      SafeJsonParser.parseDateTime(this[key], defaultValue: defaultValue);

  DateTime? getDateTimeOrNull(String key) =>
      SafeJsonParser.parseDateTimeOrNull(this[key]);

  List<T> getList<T>(String key, T Function(dynamic) converter) =>
      SafeJsonParser.parseList(this[key], converter);

  List<T>? getListOrNull<T>(String key, T Function(dynamic) converter) =>
      SafeJsonParser.parseListOrNull(this[key], converter);

  Map<String, dynamic> getMap(String key) =>
      SafeJsonParser.parseMap(this[key]);

  Map<String, dynamic>? getMapOrNull(String key) =>
      SafeJsonParser.parseMapOrNull(this[key]);
}

