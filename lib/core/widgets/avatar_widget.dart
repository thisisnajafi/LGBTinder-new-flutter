import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_icons.dart';
import '../../widgets/loading/skeleton_loader.dart';
import 'optimized_image.dart';

/// Circular avatar with thumbnail decode cap, shimmer placeholder, and SVG fallback.
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackInitial;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackInitial,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final size = radius * 2;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _textOrIconFallback(isDark, bgColor);
    }

    return ClipOval(
      child: OptimizedImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        size: ImageSize.thumbnail,
        placeholder: SkeletonLoader(
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(radius),
        ),
        errorWidget: _textOrIconFallback(isDark, bgColor),
      ),
    );
  }

  Widget _textOrIconFallback(bool isDark, Color bgColor) {
    final initial = fallbackInitial?.trim();
    if (initial != null && initial.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initial.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.85,
            fontWeight: FontWeight.w600,
            color: AppColors.accentPurple,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: AppSvgIcon(
        assetPath: AppIcons.user,
        size: radius,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}
