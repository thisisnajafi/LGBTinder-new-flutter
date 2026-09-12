import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_providers.dart';
import '../cache/peer_avatar_cache.dart';
import '../theme/app_colors.dart';
import '../theme/border_radius_constants.dart' show AppRadius;
import '../utils/app_icons.dart';
import '../utils/media_url.dart';
import '../../widgets/loading/skeleton_loader.dart';

/// Full-size profile image with custom cache manager, shimmer placeholder, and SVG fallback.
class ProfileImageWidget extends ConsumerWidget {
  final String? imageUrl;
  final int? userId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.userId,
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
    final widgetUserId = userId ?? 0;
    final cachedAvatar = widgetUserId > 0
        ? ref.watch(
            peerAvatarCacheProvider.select((avatars) => avatars[widgetUserId]),
          )
        : null;
    final resolvedUrl = MediaUrl.pick(
      userId: widgetUserId,
      incoming: imageUrl,
      cached: cachedAvatar,
    );
    final incomingResolved = MediaUrl.resolve(imageUrl);
    if (widgetUserId > 0 &&
        incomingResolved != null &&
        cachedAvatar != incomingResolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        unawaited(
          ref.read(peerAvatarCacheProvider.notifier).remember(
                widgetUserId,
                incomingResolved,
              ),
        );
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutWidth = _finitePx(width, constraints.maxWidth);
        final layoutHeight = _finitePx(height ?? width, constraints.maxHeight);
        final memWidth = _memCachePx(context, layoutWidth);
        final displayWidth = _layoutSize(width);
        final displayHeight = _layoutSize(height ?? width);

        if (resolvedUrl == null) {
          return _fallback(
            context,
            isDark,
            radius,
            displayWidth,
            displayHeight,
            layoutHeight ?? layoutWidth,
          );
        }

        Widget image = CachedNetworkImage(
          imageUrl: resolvedUrl,
          cacheManager: cacheManager,
          cacheKey: MediaUrl.cacheKey(userId: userId, url: resolvedUrl),
          width: displayWidth,
          height: displayHeight,
          memCacheWidth: memWidth,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (_, __) => SkeletonLoader(
            width: displayWidth,
            height: displayHeight,
            borderRadius: radius,
          ),
          errorWidget: (_, __, ___) => _fallback(
            context,
            isDark,
            radius,
            displayWidth,
            displayHeight,
            layoutHeight ?? layoutWidth,
          ),
        );

        if (borderRadius != null) {
          image = ClipRRect(borderRadius: radius, child: image);
        }

        return image;
      },
    );
  }

  Widget _fallback(
    BuildContext context,
    bool isDark,
    BorderRadius radius,
    double? displayWidth,
    double? displayHeight,
    double? iconBasis,
  ) {
    return Container(
      width: displayWidth,
      height: displayHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: AppSvgIcon(
        assetPath: AppIcons.user,
        size: _fallbackIconSize(iconBasis ?? displayHeight ?? displayWidth),
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  /// Infinity/NaN is valid for layout (fill parent) but must never be rounded.
  static double? _layoutSize(double? size) {
    if (size == null) return null;
    if (!size.isFinite || size <= 0) return null;
    return size;
  }

  static double? _finitePx(double? requested, double constraint) {
    if (requested != null && requested.isFinite && requested > 0) {
      return requested;
    }
    if (constraint.isFinite && constraint > 0) {
      return constraint;
    }
    return null;
  }

  static int? _memCachePx(BuildContext context, double? logical) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    var source = logical;
    if (source == null || !source.isFinite || source <= 0) {
      source = MediaQuery.sizeOf(context).shortestSide;
    }
    if (!source.isFinite || source <= 0 || !dpr.isFinite || dpr <= 0) {
      return 512;
    }
    return (source * dpr).round().clamp(1, 2048);
  }

  static double _fallbackIconSize(double? size) {
    if (size == null || !size.isFinite || size <= 0) return 19.2;
    return size * 0.4;
  }
}
