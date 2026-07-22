import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';

/// Full-screen remote video with draggable local PiP preview.
class AgoraCallVideoLayer extends StatefulWidget {
  final RtcEngine engine;
  final String channelId;
  final int? remoteUid;
  final bool showLocalPreview;
  final bool mirrorLocal;

  const AgoraCallVideoLayer({
    super.key,
    required this.engine,
    required this.channelId,
    this.remoteUid,
    this.showLocalPreview = true,
    this.mirrorLocal = true,
  });

  @override
  State<AgoraCallVideoLayer> createState() => _AgoraCallVideoLayerState();
}

class _AgoraCallVideoLayerState extends State<AgoraCallVideoLayer> {
  Offset? _pipOffset;

  double _pipWidth(BuildContext context) => AppBreakpoints.value(
        context,
        phone: 112.0,
        tablet: 128.0,
        desktop: 144.0,
      );

  double _pipHeight(BuildContext context) => _pipWidth(context) * (148 / 112);

  double _controlsReserve(BuildContext context) => AppBreakpoints.value(
        context,
        phone: 120.0,
        tablet: 140.0,
        desktop: 160.0,
      );

  Offset _defaultPipOffset(BuildContext context) {
    final inset = ResponsivePadding.horizontal(context);
    return Offset(
      inset.left,
      inset.top + MediaQuery.paddingOf(context).top + AppSpacing.spacingXL,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pipWidth = _pipWidth(context);
    final pipHeight = _pipHeight(context);
    final pipOffset = _pipOffset ?? _defaultPipOffset(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: widget.remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: widget.engine,
                    canvas: VideoCanvas(uid: widget.remoteUid),
                    connection: RtcConnection(channelId: widget.channelId),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
        ),
        if (widget.showLocalPreview)
          Positioned(
            left: pipOffset.dx,
            top: pipOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                final size = MediaQuery.sizeOf(context);
                setState(() {
                  final base = _pipOffset ?? _defaultPipOffset(context);
                  final next = base + details.delta;
                  _pipOffset = Offset(
                    next.dx.clamp(0, size.width - pipWidth),
                    next.dy.clamp(0, size.height - pipHeight - _controlsReserve(context)),
                  );
                });
              },
              child: Container(
                width: pipWidth,
                height: pipHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: widget.engine,
                    canvas: VideoCanvas(
                      uid: 0,
                      mirrorMode: widget.mirrorLocal
                          ? VideoMirrorModeType.videoMirrorModeEnabled
                          : VideoMirrorModeType.videoMirrorModeDisabled,
                      renderMode: RenderModeType.renderModeHidden,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
