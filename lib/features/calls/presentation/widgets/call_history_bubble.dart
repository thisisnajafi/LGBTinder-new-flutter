import 'package:flutter/material.dart';

import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/core/theme/border_radius_constants.dart';
import 'package:lgbtindernew/core/theme/spacing_constants.dart';
import 'package:lgbtindernew/core/theme/typography.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/utils/call_log_labels.dart';
/// Centered call log bubble shown inline in a chat thread (WhatsApp-style).
class CallHistoryBubble extends StatelessWidget {
  final Call call;
  final int currentUserId;
  final DateTime? timestamp;
  final VoidCallback? onTap;

  const CallHistoryBubble({
    super.key,
    required this.call,
    required this.currentUserId,
    this.timestamp,
    this.onTap,
  });

  bool get _isOutgoing => call.callerId == currentUserId;

  bool get _isVideo => call.isVideoCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNegative = CallLogLabels.isMissedOrDeclined(
      call: call,
      currentUserId: currentUserId,
    );
    final label = CallLogLabels.title(call: call, currentUserId: currentUserId);
    final textColor = isNegative
        ? AppColors.feedbackError
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final iconPath = _isVideo ? AppIcons.video : AppIcons.phone;
    final directionIcon =
        _isOutgoing ? AppIcons.arrowRight : AppIcons.arrowLeft;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.spacingSM,
          horizontal: AppSpacing.spacingLG,
        ),
        child: Semantics(
          label: label,
          button: onTap != null,
          child: Material(
            color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                .withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetPath: directionIcon,
                      size: 14,
                      color: textColor,
                    ),
                    SizedBox(width: AppSpacing.spacingXS),
                    AppSvgIcon(
                      assetPath: isNegative ? AppIcons.callMissed : iconPath,
                      size: 16,
                      color: textColor,
                    ),
                    SizedBox(width: AppSpacing.spacingXS),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTypography.labelMedium.copyWith(color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
