import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/app_icons.dart';

/// Camera edit button overlaid on profile avatars.
class ProfileCameraBadge extends StatelessWidget {
  const ProfileCameraBadge({
    super.key,
    this.size = 28,
    this.iconSize = 14,
  });

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.accentGradient,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 2,
        ),
      ),
      child: Center(
        child: AppSvgIcon(
          assetPath: AppIcons.camera,
          size: iconSize,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}
