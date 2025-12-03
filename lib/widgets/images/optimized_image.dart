// Widget: OptimizedImage
// Optimized image loader
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

/// Optimized image loader widget
/// Uses cached network image with placeholder and error handling
class OptimizedImage extends ConsumerWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultPlaceholder = placeholder ??
        Container(
          width: width,
          height: height,
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
            ),
          ),
        );

    final defaultErrorWidget = errorWidget ??
        Container(
          width: width,
          height: height,
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Icon(
            Icons.broken_image,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        );

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => defaultPlaceholder,
      errorWidget: (context, url, error) => defaultErrorWidget,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
