/// Generic API Response model
class ApiResponse<T> {
  final bool status;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.meta,
  });

  /// Create ApiResponse from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    if (!_looksLikeApiEnvelope(json)) {
      return ApiResponse<T>(
        status: true,
        message: json['message']?.toString() ?? '',
        data: fromJsonT != null ? fromJsonT(json) : json as T,
      );
    }

    // Handle status field - can be bool, string ("success"), or `success` key
    bool status = false;
    if (json['success'] is bool) {
      status = json['success'] as bool;
    }
    final statusValue = json['status'];
    if (statusValue is bool) {
      status = statusValue;
    } else if (statusValue is String) {
      status = statusValue.toLowerCase() == 'success' || statusValue.toLowerCase() == 'true';
    } else if (statusValue != null) {
      status = statusValue == true || statusValue == 1 || statusValue == '1';
    }
    
    return ApiResponse<T>(
      status: status,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? (fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T)
          : null,
      meta: _parseMeta(json['meta']),
    );
  }

  /// Backend often sends `meta: []` for empty metadata; only maps are valid here.
  static Map<String, dynamic>? _parseMeta(dynamic meta) {
    if (meta is Map<String, dynamic>) return meta;
    if (meta is Map) return Map<String, dynamic>.from(meta);
    return null;
  }

  static bool _looksLikeApiEnvelope(Map<String, dynamic> json) {
    if (json.containsKey('data') || json.containsKey('success')) return true;
    if (json['status'] is String || json['status'] is int) return true;
    if (json.containsKey('error')) return true;

    // `{status: false, message: "..."}` without a nested `data` field.
    if (json.containsKey('message') &&
        json.containsKey('status') &&
        !json.containsKey('id') &&
        !json.containsKey('first_name') &&
        !json.containsKey('email')) {
      return true;
    }

    return false;
  }

  /// Create ApiResponse from response data (when data is directly the response)
  factory ApiResponse.fromData(
    dynamic data,
    T Function(dynamic)? fromJsonT,
  ) {
    if (data is Map<String, dynamic>) {
      return ApiResponse.fromJson(data, fromJsonT);
    }
    
    // If data is not a map, assume it's the data field
    return ApiResponse<T>(
      status: true,
      message: 'Success',
      data: fromJsonT != null ? fromJsonT(data) : data as T?,
    );
  }

  /// Create success response
  factory ApiResponse.success({
    required T data,
    String message = 'Success',
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      status: true,
      message: message,
      data: data,
      meta: meta,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String message,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      status: false,
      message: message,
      data: null,
      meta: meta,
    );
  }

  /// Check if response is successful (allows empty/null [data] for void endpoints).
  bool get isSuccess => status;

  /// Check if response has error
  bool get hasError => !status;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
      if (meta != null) 'meta': meta,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(status: $status, message: $message, data: $data)';
  }
}
