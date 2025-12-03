import 'package:flutter/material.dart';
import '../models/api_error.dart';
import '../../core/theme/app_colors.dart';

/// Service for handling API errors and displaying user-friendly messages
class ErrorHandlerService {
  /// Get user-friendly error message from ApiError
  static String getUserFriendlyMessage(ApiError error) {
    // Check for validation errors first - these are the most important
    if (error.errors != null && error.errors!.isNotEmpty) {
      // For validation errors, show the first error (most important)
      // This is more concise and user-friendly
      final firstErr = error.firstError;
      if (firstErr != null && firstErr.isNotEmpty) {
        return firstErr;
      }
      // Fallback to all errors if first error is not available
      final validationErrors = error.getAllErrors();
      if (validationErrors.isNotEmpty && validationErrors != error.message) {
        return validationErrors;
      }
    }

    // Handle specific status codes
    if (error.code != null) {
      switch (error.code) {
        case 400:
          // If we have a specific message, use it; otherwise use generic
          return error.message != 'An error occurred' 
              ? error.message 
              : 'Invalid request. Please check your input and try again.';
        case 401:
          // For login errors, show the actual API message (e.g., "Invalid email or password")
          // Only use generic message if API didn't provide a specific one
          if (error.message.isNotEmpty && 
              error.message != 'An error occurred' &&
              !error.message.toLowerCase().contains('session expired')) {
            return error.message;
          }
          return 'Your session has expired. Please log in again.';
        case 403:
          // Check if this is a special 403 (profile completion or email verification required)
          // These should be handled by the auth service, not shown as generic errors
          final message = error.message.toLowerCase();
          if (message.contains('profile completion required') || 
              message.contains('verify your email') ||
              message.contains('email verification required')) {
            // Return the actual message instead of generic permission error
            return error.message;
          }
          return 'You don\'t have permission to perform this action.';
        case 404:
          return 'The requested resource was not found.';
        case 422:
          // For 422, prefer validation errors if available, otherwise use the message
          if (error.errors != null && error.errors!.isNotEmpty) {
            return error.getAllErrors();
          }
          return error.message != 'An error occurred' && error.message != 'Validation error'
              ? error.message 
              : 'Please check your input and try again.';
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server error. Please try again later.';
        default:
          break;
      }
    }

    // Check error message for common patterns
    final message = error.message.toLowerCase();
    
    if (message.contains('timeout') || message.contains('connection timeout')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }
    
    if (message.contains('socketexception') || 
        message.contains('no internet') ||
        message.contains('network') ||
        message.contains('offline')) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    if (message.contains('unauthorized') || message.contains('authentication')) {
      return 'Authentication failed. Please log in again.';
    }
    
    if (message.contains('validation') || message.contains('invalid')) {
      return 'Please check your input and try again.';
    }
    
    if (message.contains('not found') || message.contains('404')) {
      return 'The requested resource was not found.';
    }
    
    if (message.contains('server error') || message.contains('500')) {
      return 'Server error. Please try again later.';
    }

    // Return the original message if no pattern matches
    return error.message;
  }

  /// Get error title based on error type
  static String getErrorTitle(ApiError error) {
    if (error.code != null) {
      switch (error.code) {
        case 400:
          return 'Invalid Request';
        case 401:
          return 'Authentication Required';
        case 403:
          return 'Access Denied';
        case 404:
          return 'Not Found';
        case 422:
          return 'Validation Error';
        case 429:
          return 'Too Many Requests';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server Error';
        default:
          break;
      }
    }

    final message = error.message.toLowerCase();
    
    if (message.contains('timeout') || message.contains('connection')) {
      return 'Connection Error';
    }
    
    if (message.contains('socketexception') || 
        message.contains('no internet') ||
        message.contains('network') ||
        message.contains('offline')) {
      return 'Network Error';
    }
    
    if (message.contains('unauthorized') || message.contains('authentication')) {
      return 'Authentication Error';
    }
    
    if (message.contains('validation') || message.contains('invalid')) {
      return 'Validation Error';
    }

    return 'Error';
  }

  /// Get error color based on error type
  static Color getErrorColor(ApiError error) {
    if (error.code != null) {
      switch (error.code) {
        case 400:
        case 422:
          return Colors.orange;
        case 401:
          return Colors.orange;
        case 403:
        case 404:
        case 500:
        case 502:
        case 503:
        case 504:
          return Colors.red;
        case 429:
          return Colors.red;
        default:
          break;
      }
    }

    final message = error.message.toLowerCase();
    
    if (message.contains('timeout') || 
        message.contains('socketexception') ||
        message.contains('no internet') ||
        message.contains('network') ||
        message.contains('offline')) {
      return Colors.red;
    }
    
    if (message.contains('validation') || message.contains('invalid')) {
      return Colors.orange;
    }

    return Colors.red;
  }

  /// Show error as SnackBar
  static void showErrorSnackBar(
    BuildContext context,
    ApiError error, {
    String? customMessage,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = customMessage != null 
        ? '$customMessage: ${getUserFriendlyMessage(error)}'
        : getUserFriendlyMessage(error);
    final color = getErrorColor(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show error as Dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    ApiError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final title = getErrorTitle(error);
    final message = getUserFriendlyMessage(error);
    final color = getErrorColor(error);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          if (onDismiss != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              child: Text('Dismiss'),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text('Retry'),
            ),
          if (onRetry == null && onDismiss == null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
        ],
      ),
    );
  }

  /// Handle error and show appropriate UI
  static void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showAsDialog = false,
    String? customMessage,
  }) {
    if (error is ApiError) {
      if (showAsDialog) {
        showErrorDialog(context, error, onRetry: onRetry);
      } else {
        showErrorSnackBar(context, error, customMessage: customMessage, onRetry: onRetry);
      }
    } else if (error is Exception) {
      // Convert generic exception to ApiError
      final apiError = ApiError(
        message: customMessage ?? error.toString(),
      );
      if (showAsDialog) {
        showErrorDialog(context, apiError, onRetry: onRetry);
      } else {
        showErrorSnackBar(context, apiError, customMessage: customMessage, onRetry: onRetry);
      }
    } else {
      // Handle string errors
      final apiError = ApiError(
        message: customMessage ?? error.toString(),
      );
      if (showAsDialog) {
        showErrorDialog(context, apiError, onRetry: onRetry);
      } else {
        showErrorSnackBar(context, apiError, onRetry: onRetry);
      }
    }
  }
}

