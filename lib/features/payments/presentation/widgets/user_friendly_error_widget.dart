import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';

/// User-friendly error display widget
/// Displays errors with actionable suggestions based on backend error response
class UserFriendlyErrorWidget extends StatelessWidget {
  final String? errorCode;
  final String? userMessage;
  final String? technicalMessage;
  final String? suggestedAction;
  final bool retryable;
  final VoidCallback? onRetry;
  final VoidCallback? onContactSupport;

  const UserFriendlyErrorWidget({
    Key? key,
    this.errorCode,
    this.userMessage,
    this.technicalMessage,
    this.suggestedAction,
    this.retryable = false,
    this.onRetry,
    this.onContactSupport,
  }) : super(key: key);

  /// Create from API error response
  factory UserFriendlyErrorWidget.fromApiError(
    Map<String, dynamic> errorResponse, {
    VoidCallback? onRetry,
    VoidCallback? onContactSupport,
  }) {
    final error = errorResponse['error'] ?? errorResponse;
    return UserFriendlyErrorWidget(
      errorCode: error['code']?.toString(),
      userMessage: error['userMessage']?.toString() ?? error['message']?.toString(),
      technicalMessage: error['message']?.toString(),
      suggestedAction: error['action']?.toString(),
      retryable: error['retryable'] == true,
      onRetry: onRetry,
      onContactSupport: onContactSupport,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      margin: EdgeInsets.all(AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error Icon and Title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.accentRed,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Text(
                  'Purchase Error',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.spacingMD),

          // User-Friendly Message
          if (userMessage != null) ...[
            Text(
              userMessage!,
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.spacingMD),
          ],

          // Suggested Action
          if (suggestedAction != null) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.accentYellow,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Text(
                      suggestedAction!,
                      style: AppTypography.body.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.spacingMD),
          ],

          // Action Buttons
          Row(
            children: [
              if (retryable && onRetry != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh, size: 18),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingMD,
                        vertical: AppSpacing.spacingSM,
                      ),
                    ),
                  ),
                ),
              if (retryable && onRetry != null && onContactSupport != null)
                SizedBox(width: AppSpacing.spacingSM),
              if (onContactSupport != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContactSupport,
                    icon: Icon(Icons.support_agent, size: 18),
                    label: Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentPurple,
                      side: BorderSide(color: AppColors.accentPurple),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingMD,
                        vertical: AppSpacing.spacingSM,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Error Code (for support reference)
          if (errorCode != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Divider(),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Error Code: $errorCode',
              style: AppTypography.caption.copyWith(
                color: secondaryTextColor,
                fontFamily: 'monospace',
              ),
            ),
            if (technicalMessage != null && technicalMessage != userMessage)
              Text(
                technicalMessage!,
                style: AppTypography.caption.copyWith(
                  color: secondaryTextColor,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
