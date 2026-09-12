// Widget: ErrorDisplayWidget
// Error display widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_icons.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'empty_state.dart';

/// Error display widget
/// Displays error message with retry option
/// Can accept either ApiError or String error message
/// Debug/stack details are not shown to the user.
class ErrorDisplayWidget extends ConsumerWidget {
  final dynamic error; // Can be ApiError, String, or Exception
  final String? errorMessage; // Fallback if error is not provided
  final VoidCallback? onRetry;
  final String? title;
  final IconData? icon;

  const ErrorDisplayWidget({
    Key? key,
    this.error,
    this.errorMessage,
    this.onRetry,
    this.title,
    this.icon,
  }) : super(key: key);

  String _getErrorMessage() {
    if (error is ApiError) {
      return ErrorHandlerService.getUserFriendlyMessage(error as ApiError);
    } else if (error is String) {
      return error as String;
    } else if (errorMessage != null) {
      return errorMessage!;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  String _getErrorTitle() {
    if (title != null) return title!;
    if (error is ApiError) {
      return ErrorHandlerService.getErrorTitle(error as ApiError);
    }
    return 'Something went wrong';
  }

  String _iconPath() {
    if (error is ApiError) {
      final apiError = error as ApiError;
      if (apiError.code == 401 || apiError.code == 403) {
        return AppIcons.getIconPath('lock');
      }
      if (apiError.code == 404) {
        return AppIcons.search;
      }
      if (apiError.code != null && apiError.code! >= 500) {
        return AppIcons.cloud;
      }
    }
    return AppIcons.warning2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      title: _getErrorTitle(),
      message: _getErrorMessage(),
      iconPath: _iconPath(),
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}
