import 'package:dio/dio.dart';

/// Task 2.2.2 (Phase 3): User-friendly HTTP error messages
const Map<int, String> httpErrorMessages = {
  400: 'Invalid request. Please check your input.',
  401: 'Your session has expired. Please log in again.',
  403: 'You don\'t have permission to perform this action.',
  404: 'The requested resource was not found.',
  409: 'This action conflicts with existing data.',
  422: 'Please check your input and try again.',
  413: 'Image file is too large. Please try a smaller photo.',
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
  'CHAT_DAILY_SEND_LIMIT_REACHED': 'Daily message limit reached for this chat. Upgrade to send more.',
  'CHAT_IMAGE_UPLOAD_LIMIT_REACHED': 'Too many image uploads. Please try again later.',
  
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
  'MATCHES_PREMIUM_REQUIRED': 'Upgrade to see your matches.',
  'REWIND_PREMIUM_REQUIRED': 'Rewind requires a Premium subscription.',
  'TEMPORARY_TOKEN_RESTRICTION': 'Complete your profile to access this feature.',
};

/// Backend codes that mean plan/feature access denied — never treat as session logout.
const Set<String> featureForbiddenErrorCodes = {
  'FEATURE_NOT_AVAILABLE',
  'PREMIUM_REQUIRED',
  'SUBSCRIPTION_EXPIRED',
  'MATCHES_PREMIUM_REQUIRED',
  'REWIND_PREMIUM_REQUIRED',
  'SUPERLIKE_LIMIT_REACHED',
  'DAILY_LIMIT_REACHED',
  'SWIPE_LIMIT_REACHED',
  'DAILY_LIKE_LIMIT_REACHED',
  'DAILY_VIEW_LIMIT_REACHED',
  'CHAT_DAILY_SEND_LIMIT_REACHED',
  'CHAT_IMAGE_UPLOAD_LIMIT_REACHED',
  'STICKER_PACK_LOCKED',
  'TEMPORARY_TOKEN_RESTRICTION',
  'PROFILE_PICTURE_REQUIRED',
  'PROFILE_INCOMPLETE',
  'EMAIL_NOT_VERIFIED',
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
  factory ApiError.fromResponse(
    Map<String, dynamic> json, {
    int? statusCode,
    Map<String, dynamic>? responseData,
  }) {
    final data = responseData ?? json;
    final errorCode = data['error_code']?.toString() ?? data['code']?.toString();

    return ApiError(
      code: statusCode ?? data['code'] as int?,
      message: data['message'] as String? ?? 'An error occurred',
      errorCode: errorCode,
      errors: data['errors'] != null
          ? Map<String, List<String>>.from(
              (data['errors'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List
                      ? value.map((e) => e.toString()).toList()
                      : [value.toString()],
                ),
              ),
            )
          : null,
      responseData: data,
    );
  }

  /// True when the HTTP response indicates plan/feature denial, not invalid session.
  static bool isFeatureForbiddenResponse({
    int? statusCode,
    Map<String, dynamic>? body,
  }) {
    if (statusCode == 403) return true;
    if (body == null) return false;

    if (body['upgrade_required'] == true || body['purchase_required'] == true) {
      return true;
    }

    final nested = body['data'];
    if (nested is Map<String, dynamic>) {
      if (nested['upgrade_required'] == true ||
          nested['purchase_required'] == true) {
        return true;
      }
    }

    final errorCode = body['error_code']?.toString();
    if (errorCode != null && featureForbiddenErrorCodes.contains(errorCode)) {
      return true;
    }

    return false;
  }

  /// Only true for expired/invalid auth — never for premium/plan 403 responses
  /// or anonymous requests that never sent a Bearer token.
  static bool shouldForceLogout({
    int? statusCode,
    Map<String, dynamic>? body,
    String? requestPath,
    bool hadAuthTokenOnRequest = false,
  }) {
    if (statusCode == 403) return false;
    if (isFeatureForbiddenResponse(statusCode: statusCode, body: body)) {
      return false;
    }
    if (statusCode != 401) return false;
    if (!hadAuthTokenOnRequest) return false;

    final path = requestPath ?? '';
    if (path.contains('/auth/check-token')) return false;
    if (path.contains('/auth/login') ||
        path.contains('login-password') ||
        path.contains('/auth/register')) {
      return false;
    }

    return true;
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
  
  /// Check if error requires user to log in again (never for plan/feature 403).
  bool get requiresLogin {
    if (isFeatureForbidden) return false;
    return code == 401 ||
        errorCode == 'TOKEN_EXPIRED' ||
        errorCode == 'TOKEN_INVALID' ||
        errorCode == 'UNAUTHORIZED';
  }

  /// Plan, subscription, or permission denial — user stays logged in.
  bool get isFeatureForbidden =>
      ApiError.isFeatureForbiddenResponse(
        statusCode: code,
        body: responseData,
      ) ||
      isPlanLimitError ||
      purchaseRequired;

  bool get purchaseRequired {
    final data = responseData?['data'];
    return responseData?['purchase_required'] == true ||
        (data is Map && data['purchase_required'] == true);
  }

  /// Check if error is due to plan/subscription limits
  bool get isPlanLimitError =>
      errorCode == 'FEATURE_NOT_AVAILABLE' ||
      errorCode == 'PREMIUM_REQUIRED' ||
      errorCode == 'MATCHES_PREMIUM_REQUIRED' ||
      errorCode == 'REWIND_PREMIUM_REQUIRED' ||
      errorCode == 'DAILY_LIMIT_REACHED' ||
      errorCode == 'SWIPE_LIMIT_REACHED' ||
      errorCode == 'SUPERLIKE_LIMIT_REACHED' ||
      errorCode == 'MESSAGE_LIMIT_REACHED' ||
      errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED';

  bool get upgradeRequired =>
      responseData?['upgrade_required'] == true ||
      errorCode == 'CHAT_DAILY_SEND_LIMIT_REACHED' ||
      errorCode == 'STICKER_PACK_LOCKED';
  
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
