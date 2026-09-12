import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../data/models/call_pip_layout.dart';
import '../../providers/agora_rtc_session_provider.dart';
import '../../providers/live_call_ui_provider.dart';
import 'call_speaking_ring.dart';
import 'call_stage_placeholder.dart';

/// Full-screen call video:
/// - ringing / no remote → local camera (or local profile if camera off)
/// - answered → remote camera full screen, local as a corner PiP
///
/// Controllers are kept in [State] so mute / duration / flip rebuilds do not
/// recreate Agora textures (that causes the green / corrupted frames).
/// Each [AgoraVideoView] and the local PiP sit in a [RepaintBoundary] so
/// parent timer / mute paints do not dirty the video textures.
class AgoraCallVideoLayer extends StatefulWidget {
  final RtcEngine engine;
  final String channelId;
  final int? remoteUid;
  final bool localCameraOn;
  final bool remoteCameraOn;
  final String? localAvatarUrl;
  final String? remoteAvatarUrl;
  final int localUserId;
  final int remoteUserId;
  final String localCameraCaption;
  final String remoteCameraCaption;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onStageTap;

  const AgoraCallVideoLayer({
    super.key,
    required this.engine,
    required this.channelId,
    this.remoteUid,
    this.localCameraOn = true,
    this.remoteCameraOn = true,
    this.localAvatarUrl,
    this.remoteAvatarUrl,
    this.localUserId = 0,
    this.remoteUserId = 0,
    this.localCameraCaption = 'Camera is off',
    this.remoteCameraCaption = 'Camera is off',
    this.onFlipCamera,
    this.onStageTap,
  });

  @override
  State<AgoraCallVideoLayer> createState() => _AgoraCallVideoLayerState();
}

class _AgoraCallVideoLayerState extends State<AgoraCallVideoLayer>
    with SingleTickerProviderStateMixin {
  VideoViewController? _localController;
  VideoViewController? _remoteController;
  RtcEngine? _boundEngine;
  String? _boundChannel;
  int? _boundRemoteUid;
  Offset? _pipOffset;
  bool _pipLarge = false;
  bool _pipDragging = false;
  CallPipCorner _pipCorner = CallPipCorner.bottomRight;
  late final AnimationController _snapController;
  Offset _snapFrom = Offset.zero;
  Offset _snapTo = Offset.zero;
  Curve _snapCurve = Curves.linear;

  bool get _hasRemote => widget.remoteUid != null && widget.remoteUid! > 0;

  double _pipSmallWidth(BuildContext context) => AppBreakpoints.value(
        context,
        phone: 112.0,
        tablet: 128.0,
        desktop: 144.0,
      );

  Size _pipSizeOf(BuildContext context) => CallPipLayout.pipSize(
        smallWidth: _pipSmallWidth(context),
        large: _pipLarge,
      );

  double _controlsReserve(BuildContext context) => AppBreakpoints.value(
        context,
        phone: 120.0,
        tablet: 140.0,
        desktop: 160.0,
      );

  double _topInset(BuildContext context) =>
      MediaQuery.paddingOf(context).top + AppSpacing.spacingXL;

  double _sideInset(BuildContext context) =>
      ResponsivePadding.horizontal(context).left;

  Offset _cornerOffset(BuildContext context, CallPipCorner corner) {
    final size = MediaQuery.sizeOf(context);
    final pip = _pipSizeOf(context);
    final side = _sideInset(context);
    return CallPipLayout.offsetFor(
      corner: corner,
      viewport: size,
      pipSize: pip,
      topInset: _topInset(context),
      leftInset: side,
      rightInset: side,
      bottomReserve: _controlsReserve(context),
    );
  }

  CallPipCorner _nearestCorner(BuildContext context, Offset offset) {
    final size = MediaQuery.sizeOf(context);
    final pip = _pipSizeOf(context);
    final side = _sideInset(context);
    return CallPipLayout.nearest(
      offset: offset,
      viewport: size,
      pipSize: pip,
      topInset: _topInset(context),
      leftInset: side,
      rightInset: side,
      bottomReserve: _controlsReserve(context),
    );
  }

  Offset _clampPip(BuildContext context, Offset offset) {
    final size = MediaQuery.sizeOf(context);
    final pip = _pipSizeOf(context);
    final side = _sideInset(context);
    return CallPipLayout.clampToBounds(
      offset: offset,
      viewport: size,
      pipSize: pip,
      topInset: _topInset(context),
      leftInset: side,
      rightInset: side,
      bottomReserve: _controlsReserve(context),
    );
  }

  @override
  void initState() {
    super.initState();
    _syncControllers();
    _snapController = AnimationController(
      vsync: this,
      duration: AppAnimations.callPipSnap,
    );
    _snapController.addListener(_onSnapTick);
  }

  void _onSnapTick() {
    if (!mounted) return;
    final t = _snapCurve.transform(_snapController.value);
    setState(() {
      _pipOffset = Offset.lerp(_snapFrom, _snapTo, t)!;
    });
  }

  void _snapToCorner(CallPipCorner corner) {
    if (!mounted) return;
    final target = _cornerOffset(context, corner);
    _pipCorner = corner;
    _snapFrom = _pipOffset ?? target;
    _snapTo = target;
    final reduced = !AppAnimations.animationsEnabled(context);
    _snapCurve =
        reduced ? Curves.linear : AppAnimations.callPipSnapCurve;
    _snapController.duration = reduced
        ? AppAnimations.callPipSnapReduced
        : AppAnimations.callPipSnap;
    unawaited(_snapController.forward(from: 0));
  }

  @override
  void didUpdateWidget(AgoraCallVideoLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    final engineChanged =
        widget.engine != _boundEngine || widget.channelId != _boundChannel;
    if (engineChanged) {
      _disposeLocal();
      _boundEngine = widget.engine;
      _boundChannel = widget.channelId;
      _localController = VideoViewController(
        rtcEngine: widget.engine,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
          mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
        ),
      );
    }

    if (engineChanged || widget.remoteUid != _boundRemoteUid) {
      _disposeRemote();
      _boundRemoteUid = widget.remoteUid;
      if (_hasRemote) {
        _remoteController = VideoViewController.remote(
          rtcEngine: widget.engine,
          canvas: VideoCanvas(uid: widget.remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        );
      }
    }
  }

  void _disposeLocal() {
    final local = _localController;
    _localController = null;
    if (local != null) unawaited(local.dispose());
  }

  void _disposeRemote() {
    final remote = _remoteController;
    _remoteController = null;
    if (remote != null) unawaited(remote.dispose());
  }

  @override
  void dispose() {
    _snapController.dispose();
    _disposeLocal();
    _disposeRemote();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pipSize = _pipSizeOf(context);
    final pipOffset =
        _pipOffset ?? _cornerOffset(context, CallPipCorner.bottomRight);
    final lift = _pipDragging ? AppAnimations.callPipLiftScale : 1.0;
    final animate = AppAnimations.animationsEnabled(context);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(
          key: const ValueKey('agora-main-stage'),
          child: _buildMainStage(),
        ),
        if (widget.onStageTap != null)
          Positioned.fill(
            child: Semantics(
              label: 'Show call controls',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.onStageTap,
              ),
            ),
          ),
        if (_hasRemote)
          Positioned(
            left: pipOffset.dx,
            top: pipOffset.dy,
            child: RepaintBoundary(
              key: const ValueKey('agora-local-pip'),
              child: Semantics(
                label: 'Local video preview',
                hint: 'Tap to resize. Long press to flip camera. Drag to move.',
                child: GestureDetector(
                  onTap: () {
                    setState(() => _pipLarge = !_pipLarge);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _snapToCorner(_pipCorner);
                    });
                  },
                  onLongPress: widget.onFlipCamera,
                  onPanStart: (_) {
                    _snapController.stop();
                    setState(() => _pipDragging = true);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      final base = _pipOffset ??
                          _cornerOffset(context, CallPipCorner.bottomRight);
                      _pipOffset = _clampPip(context, base + details.delta);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() => _pipDragging = false);
                    final current = _pipOffset ??
                        _cornerOffset(context, CallPipCorner.bottomRight);
                    _snapToCorner(_nearestCorner(context, current));
                  },
                  onPanCancel: () {
                    setState(() => _pipDragging = false);
                  },
                  child: _LocalPipSpeakingFrame(
                    child: AnimatedScale(
                      scale: lift,
                      duration: animate
                          ? AppAnimations.tapDuration
                          : Duration.zero,
                      curve: AppAnimations.curveDefault,
                      child: Container(
                        width: pipSize.width,
                        height: pipSize.height,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusMD),
                          border: Border.all(
                            color: AppColors.textPrimaryDark
                                .withValues(alpha: 0.24),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildLocalStage(compact: true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainStage() {
    if (_hasRemote) {
      if (widget.remoteCameraOn && _remoteController != null) {
        return ColoredBox(
          color: Colors.black,
          child: RepaintBoundary(
            key: const ValueKey('agora-remote-video'),
            child: AgoraVideoView(controller: _remoteController!),
          ),
        );
      }
      return CallStagePlaceholder(
        userId: widget.remoteUserId,
        imageUrl: widget.remoteAvatarUrl,
        caption: widget.remoteCameraCaption,
        speakingTarget: CallSpeakingTarget.remote,
      );
    }
    return _buildLocalStage(compact: false);
  }

  Widget _buildLocalStage({required bool compact}) {
    if (widget.localCameraOn && _localController != null) {
      return ColoredBox(
        color: Colors.black,
        child: RepaintBoundary(
          key: const ValueKey('agora-local-video'),
          child: AgoraVideoView(controller: _localController!),
        ),
      );
    }
    return CallStagePlaceholder(
      userId: widget.localUserId,
      imageUrl: widget.localAvatarUrl,
      caption: widget.localCameraCaption,
      compact: compact,
      speakingTarget: CallSpeakingTarget.local,
    );
  }
}

class _LocalPipSpeakingFrame extends ConsumerWidget {
  final Widget child;

  const _LocalPipSpeakingFrame({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speaking =
        ref.watch(localSpeakingProvider) && !ref.watch(isMutedProvider);
    return CallSpeakingRing(
      active: speaking,
      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      child: child,
    );
  }
}
