import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/services/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/utils/chat_media_playback.dart';

/// Full-screen chat video playback (CHAT-UX-007).
class ChatVideoViewer extends StatefulWidget {
  final String videoUrl;

  const ChatVideoViewer({
    super.key,
    required this.videoUrl,
  });

  static Future<void> open(
    BuildContext context, {
    required String videoUrl,
  }) {
    ChatMediaPlayback.interrupt();
    final reduce = !AppAnimations.animationsEnabled(context);
    final duration = reduce ? Duration.zero : AppAnimations.transitionModal;
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatVideoViewer(videoUrl: videoUrl);
        },
      ),
    );
  }

  @override
  State<ChatVideoViewer> createState() => _ChatVideoViewerState();
}

class _ChatVideoViewerState extends State<ChatVideoViewer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onVideo);
    _controller = null;
    unawaited(controller?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    controller.addListener(_onVideo);
    try {
      await controller.initialize();
      await controller.play();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() {
        _ready = true;
        _failed = false;
        _playing = controller.value.isPlaying;
      });
    } catch (error) {
      AppLogger.warning(
        'Chat video failed to load',
        tag: 'ChatVideo',
        error: error,
      );
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() {
        _ready = false;
        _failed = true;
      });
    }
  }

  void _onVideo() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final playing = controller.value.isPlaying;
    if (playing != _playing) {
      setState(() => _playing = playing);
    }
  }

  void _close() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _retry() async {
    final old = _controller;
    old?.removeListener(_onVideo);
    _controller = null;
    unawaited(old?.dispose() ?? Future<void>.value());
    setState(() {
      _ready = false;
      _failed = false;
      _playing = false;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _failed
                  ? _ErrorBody(
                      textTheme: textTheme,
                      onRetry: () => unawaited(_retry()),
                    )
                  : !_ready || controller == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimaryDark,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => unawaited(_togglePlay()),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio == 0
                                  ? 16 / 9
                                  : controller.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(controller),
                                  if (!_playing)
                                    AppSvgIcon(
                                      assetPath: AppIcons.playCircle,
                                      size: 64,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  Positioned(
                                    left: AppSpacing.spacingMD,
                                    right: AppSpacing.spacingMD,
                                    bottom: AppSpacing.spacingMD,
                                    child: VideoProgressIndicator(
                                      controller,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: AppColors.primaryLight,
                                        bufferedColor: AppColors.textSecondaryDark,
                                        backgroundColor: AppColors.surfaceDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
            Positioned(
              top: AppSpacing.spacingSM,
              left: AppSpacing.spacingSM,
              child: Semantics(
                button: true,
                label: 'Close video',
                child: IconButton(
                  onPressed: _close,
                  iconSize: 44,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: AppSvgIcon(
                    assetPath: AppIcons.close,
                    size: 28,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final TextTheme textTheme;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.textTheme,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't play video",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
