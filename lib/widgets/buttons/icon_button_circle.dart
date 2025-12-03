// Widget: IconButtonCircle
// Circular icon button with SVG support
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';

/// Circular icon button widget
/// Supports both IconData (Material icons) and SVG icons
class IconButtonCircle extends ConsumerWidget {
  final IconData? icon;
  final String? svgIcon;
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isActive;
  final String? semanticLabel;

  const IconButtonCircle({
    Key? key,
    this.icon,
    this.svgIcon,
    this.onTap,
    this.size = 48.0,
    this.backgroundColor,
    this.iconColor,
    this.isActive = false,
    this.semanticLabel,
  }) : assert(icon != null || svgIcon != null, 'Either icon or svgIcon must be provided'),
       super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isActive
            ? AppColors.accentPurple
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight));
    final iconColorValue = iconColor ??
        (isActive
            ? Colors.white
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight));

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: svgIcon != null
                ? AppSvgIcon(
                    assetPath: svgIcon!,
                    size: size * 0.35,
                    color: iconColorValue,
                  )
                : Icon(
                    icon!,
                    color: iconColorValue,
                    size: size * 0.35,
                  ),
          ),
        ),
      ),
    );
  }
}
