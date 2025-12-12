import 'package:dio/dio.dart';

/// Task 2.2.2 (Phase 3): User-friendly HTTP error messages
const Map<int, String> httpErrorMessages = {
  400: 'Invalid request. Please check your input.',
  401: 'Your session has expired. Please log in again.',
  403: 'You don\'t have permission to perform this action.',
  404: 'The requested resource was not found.',
  409: 'This action conflicts with existing data.',
  422: 'Please check your input and try again.',
  429: 'Too many requests. Please wait a moment.',
  500: 'Server error. Please try again later.',
  502: 'Service temporarily unavailable. Please try again.',
  503: 'Service maintenance in progress. Please try later.',
};

/// Task 2.2.2 (Phase 3): User-friendly backend error code messages
const Map<String, String> backendErrorMessages = {
  // Feature access errors
  'FEATURE_NOT_AVAILABLE': 'Upgrade your plan to access this feature.',
  'PREMIUM_REQUIRED': 'This feature requires a premium subscription.',
  'SUBSCRIPTION_EXPIRED': 'Your subscription has expired. Please renew.',
  
  // Limit errors
  'DAILY_LIMIT_REACHED': 'You\'ve reached your daily limit. Try again tomorrow!',
  'SWIPE_LIMIT_REACHED': 'No more swipes today. Upgrade for unlimited swipes!',
  'SUPERLIKE_LIMIT_REACHED': 'You\'ve used all your Super Likes for today.',
  'MESSAGE_LIMIT_REACHED': 'You\'ve reached your message limit.',
  
  // Profile errors
  'PROFILE_PICTURE_REQUIRED': 'Please add a profile picture first.',
  'PROFILE_INCOMPLETE': 'Please complete your profile to continue.',
  'AGE_VERIFICATION_REQUIRED': 'Age verification is required for this action.',
  
  // User interaction errors
  'USER_BLOCKED': 'You cannot interact with this user.',
  'USER_NOT_FOUND': 'This user is no longer available.',
  'ALREADY_MATCHED': 'You\'ve already matched with this user!',
  'ALREADY_LIKED': 'You\'ve already liked this user.',
  'SELF_ACTION': 'You cannot perform this action on yourself.',
  
  // Chat errors
  'CHAT_NOT_ALLOWED': 'You need to match with this user to chat.',
  'MATCH_REQUIRED': 'Match with this user first to send messages.',
  'MESSAGE_TOO_LONG': 'Your message is too long. Please shorten it.',
  
  // Auth errors
  'INVALID_CREDENTIALS': 'Invalid email or password. Please try again.',
  'EMAIL_NOT_VERIFIED': 'Please verify your email address first.',
  'ACCOUNT_DISABLED': 'Your account has been disabled. Contact support.',
  'TOKEN_EXPIRED': 'Your session has expired. Please log in again.',
  'TOKEN_INVALID': 'Invalid authentication. Please log in again.',
  
  // Validation errors
  'VALIDATION_FAILED': 'Please check your input and try again.',
  'INVALID_FORMAT': 'The format of your input is invalid.',
  
  // Call errors
  'CALL_NOT_ALLOWED': 'Video calls require a premium subscription.',
  'USER_BUSY': 'This user is currently busy. Try again later.',
  'CALL_DECLINED': 'The user declined your call.',
  
  // Generic errors
  'UNAUTHORIZED': 'Please log in to continue.',
  'FORBIDDEN': 'You don\'t have permission for this action.',
  'NOT_FOUND': 'The requested item was not found.',
  'SERVER_ERROR': 'Something went wrong. Please try again later.',
};

/// API Error model for handling API errors
class ApiError {
  final int? code;
  final String message;
  final String? errorCode; // Backend error code (e.g., 'DAILY_LIMIT_REACHED')
  final Map<String, List<String>>? errors;
  final dynamic originalError;
  final Map<String, dynamic>? responseData; // Store full response data for special cases

  ApiError({
    this.code,
    required this.message,
    this.errorCode,
    this.errors,
    this.originalError,
    this.responseData,
  });

  /// Create ApiError from DioException
  /// UPDATED: Task 2.2.2 - Added user-friendly error message mapping
  factory ApiError.fromDioException(DioException error) {
    String message = 'An unexpected error occurred';
    String? errorCode;
    int? statusCode;
    Map<String, List<String>>? errors;
    Map<String, dynamic>? responseDataMap;

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
          
          // Extract error code if present
          errorCode = data['error_code']?.toString() ?? 
                      data['code']?.toString();
          
          // Get backend message
          final backendMessage = data['message']?.toString();
          
          // Priority: 
          // 1. Backend error code mapped message
          // 2. Backend message
          // 3. HTTP status code mapped message
          // 4. Generic error
          if (errorCode != null && backendErrorMessages.containsKey(errorCode)) {
            message = backendErrorMessages[errorCode]!;
          } else if (backendMessage != null && backendMessage.isNotEmpty) {
            message = backendMessage;
          } else if (statusCode != null && httpErrorMessages.containsKey(statusCode)) {
            message = httpErrorMessages[statusCode]!;
          } else {
            message = 'An error occurred';
          }
          
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
          // No response data - use HTTP status message
          if (statusCode != null && httpErrorMessages.containsKey(statusCode)) {
            message = httpErrorMessages[statusCode]!;
          } else {
            message = 'Server error occurred';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          message = 'No internet connection. Please check your network.';
        } else if (error.message?.contains('HandshakeException') ?? false) {
          message = 'Secure connection failed. Please try again.';
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
      errorCode: errorCode,
      errors: errors,
      originalError: error,
      responseData: responseDataMap,
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
  /// UPDATED: Task 2.2.2 - Enhanced with error code mapping
  String getUserFriendlyMessage() {
    // 1. Check for mapped error code first
    if (errorCode != null && backendErrorMessages.containsKey(errorCode)) {
      return backendErrorMessages[errorCode]!;
    }
    
    // 2. Prefer validation errors if available
    if (errors != null && errors!.isNotEmpty) {
      final firstErr = this.firstError;
      if (firstErr != null) {
        return firstErr;
      }
      return getAllErrors();
    }
    
    // 3. Check for HTTP status code mapped message
    if (code != null && httpErrorMessages.containsKey(code)) {
      // Only use HTTP message if current message is generic
      if (message == 'An error occurred' || 
          message == 'Server error occurred' ||
          message == 'An unexpected error occurred') {
        return httpErrorMessages[code]!;
      }
    }
    
    // 4. Return the message if it's user-friendly
    return message;
  }
  
  /// Check if error requires user to log in again
  bool get requiresLogin => 
      code == 401 || 
      errorCode == 'TOKEN_EXPIRED' || 
      errorCode == 'TOKEN_INVALID' ||
      errorCode == 'UNAUTHORIZED';
  
  /// Check if error is due to plan/subscription limits
  bool get isPlanLimitError =>
      errorCode == 'FEATURE_NOT_AVAILABLE' ||
      errorCode == 'PREMIUM_REQUIRED' ||
      errorCode == 'DAILY_LIMIT_REACHED' ||
      errorCode == 'SWIPE_LIMIT_REACHED' ||
      errorCode == 'SUPERLIKE_LIMIT_REACHED' ||
      errorCode == 'MESSAGE_LIMIT_REACHED';
  
  /// Check if error is a validation error
  bool get isValidationError => 
      code == 422 || 
      (errors != null && errors!.isNotEmpty);
  
  /// Check if error is a network/connection error
  bool get isNetworkError =>
      message.contains('internet') ||
      message.contains('connection') ||
      message.contains('network') ||
      message.contains('timeout');

  @override
  String toString() {
    return 'ApiError(code: $code, message: $message, errors: $errors)';
  }
}
