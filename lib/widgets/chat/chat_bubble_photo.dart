import 'dart:io';
import 'dart:ui' show ImageFilter;

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
    if (ChatLocalMedia.isLocalPath(imageUrl)) {
      return Image.file(
        File(ChatLocalMedia.toFilePath(imageUrl)),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
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
      memoryCacheWidth: ChatImageMemory.bubbleDecodePx(
        logicalWidth: width,
        logicalHeight: height,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
      showDownloadProgress: false,
      placeholder: _blurFill(context),
      errorWidget: _blurFill(context),
    );
  }

  Widget _blurFill(BuildContext context) {
    final bytes = ChatImagePlaceholder.fromDataUri(placeholderDataUri);
    if (bytes != null) {
      return ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: ChatImagePlaceholder.blurSigma,
            sigmaY: ChatImagePlaceholder.blurSigma,
          ),
          child: Image.memory(
            bytes,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          ),
        ),
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
