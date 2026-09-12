import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/cache/image_cache_service.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/utils/chat_gallery_items.dart';
import '../../features/chat/utils/chat_image_memory.dart';
import '../../features/chat/utils/chat_image_saver.dart';
import '../../features/chat/utils/chat_local_media.dart';

/// Full-screen chat photo album (CHAT-IMG-004).
///
/// Pinch 0.5–5×, horizontal swipe between thread photos, swipe down to close,
/// cached image provider, download to gallery after permission.
class ChatImageViewer extends StatefulWidget {
  final List<ChatGalleryItem> images;
  final int initialIndex;
  final ChatImageSaveHandler? saveHandler;
  final Duration chromeHideAfter;

  const ChatImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.saveHandler,
    this.chromeHideAfter = const Duration(seconds: 3),
  });

  static const double minScale = 0.5;
  static const double maxScale = 5;
  static const double dismissDistance = 120;

  static Future<void> open(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    List<ChatGalleryItem>? images,
    int initialIndex = 0,
    ChatImageSaveHandler? saveHandler,
    Duration chromeHideAfter = const Duration(seconds: 3),
  }) {
    final items = (images != null && images.isNotEmpty)
        ? images
        : [
            ChatGalleryItem(
              url: imageUrl,
              heroTag: heroTag ?? ChatGalleryItem.heroTagFor(),
            ),
          ];
    final index = initialIndex.clamp(0, items.length - 1);
    final reduce = !AppAnimations.animationsEnabled(context);
    final duration = reduce ? Duration.zero : AppAnimations.transitionModal;
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatImageViewer(
            images: items,
            initialIndex: index,
            saveHandler: saveHandler,
            chromeHideAfter: chromeHideAfter,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Barrier fades separately; fading the child would cancel Hero reverse.
          return child;
        },
      ),
    );
  }

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  late final PageController _pageController;
  late final TransformationController _transform;
  late int _index;
  bool _chromeVisible = true;
  bool _zoomed = false;
  double _dismissDy = 0;
  Timer? _hideTimer;
  bool _saving = false;

  ChatGalleryItem get _current => widget.images[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);
    _transform = TransformationController();
    _scheduleChromeHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pageController.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _scheduleChromeHide() {
    _hideTimer?.cancel();
    if (widget.chromeHideAfter <= Duration.zero) return;
    _hideTimer = Timer(widget.chromeHideAfter, () {
      if (!mounted) return;
      setState(() => _chromeVisible = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _scheduleChromeHide();
  }

  void _resetZoom() {
    _transform.value = Matrix4.identity();
    _zoomed = false;
  }

  void _onInteraction() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
    }
  }

  void _close() {
    if (!mounted) return;
    _resetZoom();
    Navigator.of(context).maybePop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_zoomed) return;
    setState(() {
      _dismissDy = (_dismissDy + details.delta.dy).clamp(0, 480);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_zoomed) return;
    final fling = details.primaryVelocity ?? 0;
    if (_dismissDy >= ChatImageViewer.dismissDistance || fling > 800) {
      _close();
      return;
    }
    setState(() => _dismissDy = 0);
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() => _saving = true);
    final saver = widget.saveHandler ?? ChatImageGallerySaver.save;
    final result = await saver(_current.url);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved to gallery',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
          ),
        ),
      );
      return;
    }

    if (result.denied) {
      await _showPermissionSheet();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not save photo',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryDark,
              ),
        ),
      ),
    );
  }

  Future<void> _showPermissionSheet() async {
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacingMD),
            child: Material(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.downloadOutline,
                      size: 40,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: AppSpacing.spacingMD),
                    Text(
                      'Allow photo access to save this image',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.spacingLG),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await openAppSettings();
                        },
                        child: const Text('Open Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fade = AppAnimations.imageFadeDuration(context);
    final routeAnimation = ModalRoute.of(context)?.animation;
    final reduce = !AppAnimations.animationsEnabled(context);
    final drag = (1 - (_dismissDy / 480)).clamp(0.0, 1.0);

    final album = GestureDetector(
      onTap: _toggleChrome,
      onVerticalDragUpdate: _zoomed ? null : _onVerticalDragUpdate,
      onVerticalDragEnd: _zoomed ? null : _onVerticalDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(0, _dismissDy),
            child: PageView.builder(
              controller: _pageController,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _index = index;
                  _dismissDy = 0;
                });
                _resetZoom();
                if (_chromeVisible) _scheduleChromeHide();
              },
              itemBuilder: (context, index) {
                return _ZoomablePhoto(
                  item: widget.images[index],
                  heroEnabled: index == _index,
                  transform: index == _index ? _transform : null,
                  onInteraction: _onInteraction,
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: fade,
              curve: AppAnimations.curveDefault,
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM,
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Close photo',
                          child: IconButton(
                            onPressed: _close,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            icon: AppSvgIcon(
                              assetPath: AppIcons.close,
                              size: 24,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_index + 1} / ${widget.images.length}',
                            textAlign: TextAlign.center,
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Save photo to gallery',
                          child: IconButton(
                            onPressed: _saving ? null : _download,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(44, 44),
                            ),
                            icon: AppSvgIcon(
                              assetPath: AppIcons.downloadOutline,
                              size: 24,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: routeAnimation ?? const AlwaysStoppedAnimation<double>(1),
      builder: (context, child) {
        final t = reduce ? 1.0 : (routeAnimation?.value ?? 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: ColoredBox(
                key: const ValueKey('chat-image-viewer-barrier'),
                color: Colors.black.withValues(alpha: t * drag),
              ),
            ),
            child!,
          ],
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: album,
      ),
    );
  }
}

class _ZoomablePhoto extends StatelessWidget {
  final ChatGalleryItem item;
  final bool heroEnabled;
  final TransformationController? transform;
  final VoidCallback onInteraction;

  const _ZoomablePhoto({
    required this.item,
    required this.heroEnabled,
    required this.transform,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (ChatLocalMedia.isLocalPath(item.url)) {
      image = Image.file(
        File(ChatLocalMedia.toFilePath(item.url)),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Center(
          child: AppSvgIcon(
            assetPath: AppIcons.gallery,
            size: 48,
            color: AppColors.textSecondaryDark,
          ),
        ),
      );
    } else {
      final decodePx = ChatImageMemory.viewerDecodePx(
        screen: MediaQuery.sizeOf(context),
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      image = Image(
        image: lgbtfinderCachedImageProvider(item.url, maxWidth: decodePx),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryLight,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: AppSvgIcon(
            assetPath: AppIcons.gallery,
            size: 48,
            color: AppColors.textSecondaryDark,
          ),
        ),
      );
    }

    final useHero =
        heroEnabled && AppAnimations.animationsEnabled(context);
    final heroChild = useHero
        ? Hero(tag: item.heroTag, child: image)
        : image;

    return InteractiveViewer(
      transformationController: transform,
      minScale: ChatImageViewer.minScale,
      maxScale: ChatImageViewer.maxScale,
      panEnabled: transform != null,
      onInteractionUpdate: (_) => onInteraction(),
      onInteractionEnd: (_) => onInteraction(),
      child: SizedBox.expand(child: heroChild),
    );
  }
}
