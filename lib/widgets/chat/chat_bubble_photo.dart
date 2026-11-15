import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/utils/chat_image_placeholder.dart';
import '../../features/chat/utils/chat_image_memory.dart';
import '../../features/chat/utils/chat_local_media.dart';
import '../../core/widgets/optimized_image.dart';

/// Image in a chat bubble: local file while uploading, network after send.
///
/// Reserves aspect ratio so the 20×20 blur never causes layout shift
/// (CHAT-IMG-002).
///
/// The placeholder is the 20×20 preview stretched with smooth filtering,
/// which already reads as a blur. No `ImageFiltered` is used, so a photo
/// bubble costs one image draw while scrolling instead of an offscreen blur
/// pass.
class ChatBubblePhoto extends StatelessWidget {
  final String imageUrl;
  final String? thumbnailUrl;
  final String? placeholderDataUri;
  final double? aspectRatio;
  final BoxFit fit;

  const ChatBubblePhoto({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.placeholderDataUri,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  /// Stretched 20×20 preview shown until the photo is ready (tests).
  @visibleForTesting
  static const Key blurPlaceholderKey = ValueKey('chat-bubble-photo-blur');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = ChatImagePlaceholder.reservedHeight(
          boxWidth: width,
          aspectRatio: aspectRatio,
        );
        return SizedBox(
          width: width,
          height: height,
          child: _photo(context, width: width, height: height),
        );
      },
    );
  }

  Widget _photo(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    final decodePx = ChatImageMemory.bubbleDecodePx(
      logicalWidth: width,
      logicalHeight: height,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );

    if (ChatLocalMedia.isLocalPath(imageUrl)) {
      return Image.file(
        File(ChatLocalMedia.toFilePath(imageUrl)),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        // Camera originals are far larger than a bubble; decode at bubble size.
        cacheWidth: decodePx,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _blurFill(context),
              AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppAnimations.imageFadeDuration(context),
                curve: AppAnimations.curveDefault,
                child: child,
              ),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) => _blurFill(context),
      );
    }

    return OptimizedImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      memoryCacheWidth: decodePx,
      showDownloadProgress: false,
      placeholder: _blurFill(context),
      errorWidget: _blurFill(context),
    );
  }

  Widget _blurFill(BuildContext context) {
    final bytes = ChatImagePlaceholder.fromDataUri(placeholderDataUri);
    if (bytes != null) {
      return Image.memory(
        bytes,
        key: ChatBubblePhoto.blurPlaceholderKey,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.medium,
      );
    }

    final thumb = thumbnailUrl;
    if (thumb != null &&
        thumb.isNotEmpty &&
        !ChatLocalMedia.isLocalPath(thumb)) {
      return OptimizedImage(
        imageUrl: thumb,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        size: ImageSize.thumbnail,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Center(
        child: AppSvgIcon(
          assetPath: AppIcons.gallery,
          size: 32,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
