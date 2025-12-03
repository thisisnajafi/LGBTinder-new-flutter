// Widget: AccessibleButton
// Accessible button widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Accessible button widget
/// Button with enhanced accessibility features (semantic labels, minimum touch targets)
class AccessibleButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final String? semanticLabel;
  final double? minWidth;
  final double? minHeight;

  const AccessibleButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.semanticLabel,
    this.minWidth,
    this.minHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = backgroundColor ?? AppColors.accentPurple;
    final txtColor = textColor ?? Colors.white;
    final isDisabled = onPressed == null || isLoading;

    // Minimum touch target size for accessibility (44x44 points)
    final minTouchSize = 44.0;
    final buttonWidth = minWidth ?? minTouchSize;
    final buttonHeight = minHeight ?? minTouchSize;

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: !isDisabled,
      child: Container(
        constraints: BoxConstraints(
          minWidth: buttonWidth,
          minHeight: buttonHeight,
        ),
        decoration: BoxDecoration(
          color: isDisabled ? bgColor.withOpacity(0.5) : bgColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingLG,
                vertical: AppSpacing.spacingMD,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(txtColor),
                      ),
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, color: txtColor, size: 20),
                      SizedBox(width: AppSpacing.spacingSM),
                    ],
                    Text(
                      text,
                      style: AppTypography.button.copyWith(color: txtColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
