import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/optimized_image.dart';

/// List-sized call avatar decoded as [ImageSize.thumbnail] (PERF-SCR-CALLHIST-001).
class CallHistoryAvatar extends StatelessWidget {
  const CallHistoryAvatar({
    super.key,
    required this.size,
    this.imageUrl,
  });

  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final url = imageUrl?.trim();

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? OptimizedImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                size: ImageSize.thumbnail,
              )
            : ColoredBox(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.user,
                    size: size * 0.45,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
      ),
    );
  }
}
