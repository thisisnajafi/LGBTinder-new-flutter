// Widget: ErrorDisplayWidget
// Error display widget
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'empty_state.dart';
import 'retry_button.dart';

/// Error display widget
/// Displays error message with retry option
/// Can accept either ApiError or String error message
/// [debugDetails] when set and kDebugMode, shows expandable technical details for debugging
class ErrorDisplayWidget extends ConsumerWidget {
  final dynamic error; // Can be ApiError, String, or Exception
  final String? errorMessage; // Fallback if error is not provided
  final String? debugDetails; // Shown in debug mode for easier troubleshooting
  final VoidCallback? onRetry;
  final String? title;
  final IconData? icon;

  const ErrorDisplayWidget({
    Key? key,
    this.error,
    this.errorMessage,
    this.debugDetails,
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

  IconData _getErrorIcon() {
    if (icon != null) return icon!;
    if (error is ApiError) {
      final apiError = error as ApiError;
      if (apiError.code == 401 || apiError.code == 403) {
        return Icons.lock_outline;
      } else if (apiError.code == 404) {
        return Icons.search_off;
      } else if (apiError.code != null && apiError.code! >= 500) {
        return Icons.cloud_off;
      }
    }
    return Icons.error_outline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showDebug = kDebugMode && debugDetails != null && debugDetails!.isNotEmpty;

    if (!showDebug) {
      return EmptyState(
        title: _getErrorTitle(),
        message: _getErrorMessage(),
        icon: _getErrorIcon(),
        actionLabel: onRetry != null ? 'Retry' : null,
        onAction: onRetry,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          EmptyState(
            title: _getErrorTitle(),
            message: _getErrorMessage(),
            icon: _getErrorIcon(),
            actionLabel: onRetry != null ? 'Retry' : null,
            onAction: onRetry,
          ),
          const SizedBox(height: 16),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              title: Text(
                'Debug details',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.grey.shade200).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight,
                    ),
                  ),
                  child: SelectableText(
                    debugDetails!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
