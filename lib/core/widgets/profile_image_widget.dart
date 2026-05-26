import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_providers.dart';
import '../theme/app_colors.dart';
import '../theme/border_radius_constants.dart' show AppRadius;
import '../utils/app_icons.dart';
import '../../widgets/loading/skeleton_loader.dart';

/// Full-size profile image with custom cache manager, shimmer placeholder, and SVG fallback.
class ProfileImageWidget extends ConsumerWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.radiusMD);
    final cacheManager = ref.watch(imageCacheServiceProvider);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallback(context, isDark, radius);
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: cacheManager,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => SkeletonLoader(
        width: width,
        height: height,
        borderRadius: radius,
      ),
      errorWidget: (_, __, ___) => _fallback(context, isDark, radius),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: radius, child: image);
    }

    return image;
  }

  Widget _fallback(BuildContext context, bool isDark, BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: AppSvgIcon(
        assetPath: AppIcons.user,
        size: (height ?? width ?? 48) * 0.4,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}
