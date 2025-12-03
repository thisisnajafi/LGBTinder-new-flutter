// Widget: MediaViewer
// Full-screen media viewer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../images/optimized_image.dart';

/// Media viewer widget
/// Full-screen viewer for images and videos
class MediaViewer extends ConsumerStatefulWidget {
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;

  const MediaViewer({
    Key? key,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String mediaUrl,
    String mediaType = 'image',
    String? caption,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewer(
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          caption: caption,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends ConsumerState<MediaViewer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: widget.mediaType == 'image'
            ? InteractiveViewer(
                child: OptimizedImage(
                  imageUrl: widget.mediaUrl,
                  fit: BoxFit.contain,
                ),
              )
            : Container(
                // TODO: Implement video player
                child: const Center(
                  child: Text(
                    'Video playback not implemented',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: widget.caption != null
          ? Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              color: backgroundColor,
              child: Text(
                widget.caption!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}
