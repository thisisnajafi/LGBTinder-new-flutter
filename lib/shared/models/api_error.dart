import 'package:dio/dio.dart';

/// API Error model for handling API errors
class ApiError {
  final int? code;
  final String message;
  final Map<String, List<String>>? errors;
  final dynamic originalError;
  final Map<String, dynamic>? responseData; // Store full response data for special cases

  ApiError({
    this.code,
    required this.message,
    this.errors,
    this.originalError,
    this.responseData,
  });

  /// Create ApiError from DioException
  factory ApiError.fromDioException(DioException error) {
    String message = 'An unexpected error occurred';
    int? statusCode;
    Map<String, List<String>>? errors;
    Map<String, dynamic>? responseDataMap; // Declare at function level

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        if (data is Map<String, dynamic>) {
          responseDataMap = data;
          message = data['message'] ?? 'An error occurred';
          
          // Handle validation errors
          if (data['errors'] != null) {
            errors = Map<String, List<String>>.from(
              (data['errors'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List ? value.map((e) => e.toString()).toList() : [value.toString()],
                ),
              ),
            );
          }
        } else {
          message = 'Server error occurred';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          message = 'No internet connection. Please check your network.';
        } else {
          message = error.message ?? 'An unexpected error occurred';
        }
        break;
      default:
        message = error.message ?? 'An error occurred';
    }

    return ApiError(
      code: statusCode,
      message: message,
      errors: errors,
      originalError: error,
      responseData: responseDataMap, // Preserve response data for special error handling
    );
  }

  /// Create ApiError from response data
  factory ApiError.fromResponse(Map<String, dynamic> json, {int? statusCode, Map<String, dynamic>? responseData}) {
    return ApiError(
      code: statusCode ?? json['code'] as int?,
      message: json['message'] as String? ?? 'An error occurred',
      errors: json['errors'] != null
          ? Map<String, List<String>>.from(
              (json['errors'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List ? value.map((e) => e.toString()).toList() : [value.toString()],
                ),
              ),
            )
          : null,
      responseData: responseData ?? json, // Store the full response data
    );
  }

  /// Get first error message from validation errors
  String? get firstError {
    if (errors != null && errors!.isNotEmpty) {
      final firstKey = errors!.keys.first;
      final firstErrors = errors![firstKey];
      if (firstErrors != null && firstErrors.isNotEmpty) {
        return firstErrors.first;
      }
    }
    return null;
  }

  /// Get all error messages as a single string
  String getAllErrors() {
    if (errors != null && errors!.isNotEmpty) {
      final allErrors = <String>[];
      errors!.forEach((key, value) {
        // Format: "Field name: error message" or just "error message" if field name is not user-friendly
        for (final errorMsg in value) {
          // For validation errors, show the error message directly (it's usually clear enough)
          // Only add field name if it's helpful
          final formattedField = _formatFieldName(key);
          if (formattedField.toLowerCase() != key.toLowerCase() && 
              !errorMsg.toLowerCase().contains(formattedField.toLowerCase())) {
            allErrors.add('$formattedField: $errorMsg');
          } else {
            allErrors.add(errorMsg);
          }
        }
      });
      return allErrors.join('. ');
    }
    return message;
  }

  /// Format field name for display (e.g., "first_name" -> "First Name")
  String _formatFieldName(String fieldName) {
    return fieldName
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage() {
    // Prefer validation errors if available
    if (errors != null && errors!.isNotEmpty) {
      // Get the first error message (most important one)
      final firstErr = this.firstError;
      if (firstErr != null) {
        return firstErr;
      }
      // If no first error, return all errors
      return getAllErrors();
    }
    // For non-validation errors, return the message if it's user-friendly
    // Otherwise return a generic message
    if (message.isNotEmpty && 
        message != 'An error occurred' && 
        message != 'Server error occurred' &&
        message != 'An unexpected error occurred') {
      return message;
    }
    return message;
  }

  @override
  String toString() {
    return 'ApiError(code: $code, message: $message, errors: $errors)';
  }
}
