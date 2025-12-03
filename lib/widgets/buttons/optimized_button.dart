// Widget: OptimizedButton
// Optimized button widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Optimized button widget
/// Performance-optimized button with const constructors and minimal rebuilds
class OptimizedButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool useGradient;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFullWidth;

  const OptimizedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.useGradient = false,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = backgroundColor ?? AppColors.accentPurple;
    final txtColor = textColor ?? Colors.white;
    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: useGradient && !isDisabled ? AppTheme.accentGradient : null,
        color: useGradient ? null : (isDisabled ? bgColor.withOpacity(0.5) : bgColor),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingXL,
              vertical: AppSpacing.spacingMD,
            ),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
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
                  Flexible(
                    child: Text(
                      text,
                      style: AppTypography.button.copyWith(color: txtColor),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
