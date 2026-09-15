// PERFORMANCE FIX (Task 7.2.1 / PERF-INFRA-031): single image cache widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../cache/cache_providers.dart';
import '../constants/animation_constants.dart';
import '../theme/app_colors.dart';
import '../utils/app_icons.dart';
import '../utils/blur_hash_average.dart';
import '../responsive/responsive.dart';

/// Image size presets for consistent memory usage
enum ImageSize {
  thumbnail, // 100x100 - for lists and avatars
  small, // 200x200 - for cards
  medium, // 400x400 - for profile view
  large, // 800x800 - for full screen
  original, // No resize - for zoom view
}

/// Cached network image with decode-size hints (PERF-INFRA-031).
class OptimizedImage extends ConsumerWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final ImageSize size;
  final bool useMemoryCacheHint;
  final String? blurHash;

  /// Override size-preset decode cap (chat bubbles use 800).
  final int? memoryCacheWidth;
  final int? memoryCacheHeight;

  /// When false, keep [placeholder] instead of a download spinner.
  final bool? showDownloadProgress;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.size = ImageSize.medium,
    this.useMemoryCacheHint = true,
    this.blurHash,
    this.memoryCacheWidth,
    this.memoryCacheHeight,
    this.showDownloadProgress,
  });

  /// Get memory cache dimensions based on size preset
  int? get memCacheWidth {
    if (!useMemoryCacheHint) return null;
    switch (size) {
      case ImageSize.thumbnail:
        return 100;
      case ImageSize.small:
        return 200;
      case ImageSize.medium:
        return 400;
      case ImageSize.large:
        return 800;
      case ImageSize.original:
        return null;
    }
  }

  int? get memCacheHeight {
    if (!useMemoryCacheHint) return null;
    switch (size) {
      case ImageSize.thumbnail:
        return 100;
      case ImageSize.small:
        return 200;
      case ImageSize.medium:
        return 400;
      case ImageSize.large:
        return 800;
      case ImageSize.original:
        return null;
    }
  }

  int? get resolvedMemCacheWidth {
    if (memoryCacheWidth != null || memoryCacheHeight != null) {
      return memoryCacheWidth;
    }
    return memCacheWidth;
  }

  int? get resolvedMemCacheHeight {
    if (memoryCacheWidth != null || memoryCacheHeight != null) {
      return memoryCacheHeight;
    }
    return memCacheHeight;
  }

  bool get _useDownloadProgress =>
      showDownloadProgress ??
      (size == ImageSize.large || size == ImageSize.original);

  bool get _hasBlurHash => blurHash != null && blurHash!.trim().length >= 6;

  /// Fade only on detail/full-screen presets. List/thumbnail/card sizes stay
  /// instant so scrolling does not run a 200ms fade per cell (PERF-COMP-IMG-002).
  static bool shouldFade(ImageSize size) =>
      size == ImageSize.large || size == ImageSize.original;

  static Duration fadeInDurationFor(ImageSize size, BuildContext context) {
    if (!shouldFade(size)) return Duration.zero;
    return AppAnimations.imageFadeDuration(context);
  }

  static Duration fadeOutDurationFor(ImageSize size, BuildContext context) {
    if (!shouldFade(size)) return Duration.zero;
    return AppAnimations.imageFadeOutDuration(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cacheManager = ref.watch(imageCacheServiceProvider);
    final fadeIn = fadeInDurationFor(size, context);
    final fadeOut = fadeOutDurationFor(size, context);
    final useProgress = _useDownloadProgress && !_hasBlurHash;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: resolvedMemCacheWidth,
      memCacheHeight: resolvedMemCacheHeight,
      fadeInDuration: fadeIn,
      fadeOutDuration: fadeOut,
      fadeInCurve: AppAnimations.curveDefault,
      placeholder: (context, url) =>
          placeholder ?? _buildPlaceholder(context, isDark),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context),
      progressIndicatorBuilder: useProgress
          ? (context, url, progress) =>
                _buildProgressIndicator(context, progress, isDark)
          : null,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    final average = BlurHashAverage.tryColor(blurHash);
    if (average != null) {
      return ColoredBox(
        color: average,
        child: SizedBox(width: width, height: height),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.accentPurple.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: borderRadius,
      ),
      child: AppSvgIcon(
        assetPath: AppIcons.user,
        size: _getIconSize(),
        color: isDark
            ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
            : AppColors.textSecondaryLight.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    DownloadProgress progress,
    bool isDark,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: progress.progress,
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentPurple,
            ),
            backgroundColor: AppColors.accentPurple.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case ImageSize.thumbnail:
        return 16;
      case ImageSize.small:
        return 20;
      case ImageSize.medium:
        return 24;
      case ImageSize.large:
      case ImageSize.original:
        return 32;
    }
  }
}

/// Optimized avatar image specifically for user avatars in lists
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: AppText(
          (fallbackText ?? '?').substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: AppColors.accentPurple,
          ),
          maxLines: 1,
        ),
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final cacheManager = ref.watch(imageCacheServiceProvider);
        return CachedNetworkImage(
          imageUrl: imageUrl!,
          cacheManager: cacheManager,
          fadeInDuration: Duration.zero,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
            backgroundColor: bgColor,
          ),
          placeholder: (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentPurple.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            child: AppSvgIcon(
              assetPath: AppIcons.user,
              size: radius,
              color: AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
          ),
          memCacheWidth: 100,
          memCacheHeight: 100,
        );
      },
    );
  }
}
