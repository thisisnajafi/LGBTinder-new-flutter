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
    // Handle status field - can be bool or string ("success")
    bool status = false;
    final statusValue = json['status'];
    if (statusValue is bool) {
      status = statusValue;
    } else if (statusValue is String) {
      // Treat "success" string as true
      status = statusValue.toLowerCase() == 'success' || statusValue.toLowerCase() == 'true';
    } else if (statusValue != null) {
      // Try to convert other types
      status = statusValue == true || statusValue == 1 || statusValue == '1';
    }
    
    return ApiResponse<T>(
      status: status,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? (fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T)
          : null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
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

  /// Check if response is successful
  bool get isSuccess => status && data != null;

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
