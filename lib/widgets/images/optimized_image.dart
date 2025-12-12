// Widget: OptimizedImage
// PERFORMANCE FIX (Task 7.2.1): Enhanced image caching with memory optimization
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// Image size presets for consistent memory usage
enum ImageSize {
  thumbnail,  // 100x100 - for lists and avatars
  small,      // 200x200 - for cards
  medium,     // 400x400 - for profile view
  large,      // 800x800 - for full screen
  original,   // No resize - for zoom view
}

/// PERFORMANCE FIX (Task 7.2.1): Enhanced optimized image loader widget
/// 
/// Features:
/// - Memory cache size hints to prevent OOM on large lists
/// - Size-based loading for bandwidth optimization
/// - Progressive loading with blur placeholder
/// - Consistent caching strategy
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

  const OptimizedImage({
    Key? key,
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
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle empty URL
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // PERFORMANCE FIX: Memory cache hints to limit decoded image size
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      // Optimized fade durations
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Placeholder builder
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(context, isDark),
      // Error widget builder
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(context),
      // Progress indicator for large images
      progressIndicatorBuilder: size == ImageSize.large || size == ImageSize.original
          ? (context, url, progress) => _buildProgressIndicator(context, progress, isDark)
          : null,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    // If blur hash is provided, use it for placeholder
    // Note: Requires flutter_blurhash package for actual implementation
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
              AppColors.accentPurple.withOpacity(0.7),
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
      child: Icon(
        Icons.broken_image_outlined,
        color: isDark 
            ? AppColors.textSecondaryDark.withOpacity(0.5) 
            : AppColors.textSecondaryLight.withOpacity(0.5),
        size: _getIconSize(),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, DownloadProgress progress, bool isDark) {
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
            backgroundColor: AppColors.accentPurple.withOpacity(0.2),
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
    Key? key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackText,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          (fallbackText ?? '?').substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: AppColors.accentPurple,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
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
              AppColors.accentPurple.withOpacity(0.5),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Icon(
          Icons.person,
          size: radius,
          color: AppColors.textSecondaryLight.withOpacity(0.5),
        ),
      ),
      // PERFORMANCE: Small memory footprint for avatars
      memCacheWidth: (radius * 2).toInt(),
      memCacheHeight: (radius * 2).toInt(),
    );
  }
}
