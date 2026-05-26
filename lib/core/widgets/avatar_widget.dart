import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_providers.dart';
import '../theme/app_colors.dart';
import '../utils/app_icons.dart';
import '../../widgets/loading/skeleton_loader.dart';

/// Circular avatar with custom image cache, shimmer placeholder, and SVG fallback.
class AvatarWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cacheManager = ref.watch(imageCacheServiceProvider);
    final size = radius * 2;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _textOrIconFallback(isDark, bgColor);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: cacheManager,
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: size.toInt(),
      memCacheHeight: size.toInt(),
      imageBuilder: (context, provider) => CircleAvatar(
        radius: radius,
        backgroundImage: provider,
        backgroundColor: bgColor,
      ),
      placeholder: (_, __) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SkeletonLoader(
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      errorWidget: (_, __, ___) => _textOrIconFallback(isDark, bgColor),
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
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}
