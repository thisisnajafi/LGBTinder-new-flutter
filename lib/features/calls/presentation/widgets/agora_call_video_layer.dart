import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

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
  static const double _pipWidth = 112;
  static const double _pipHeight = 148;

  Offset _pipOffset = const Offset(
    AppSpacing.spacingLG,
    AppSpacing.spacingXL + 48,
  );

  @override
  Widget build(BuildContext context) {
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
            left: _pipOffset.dx,
            top: _pipOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                final size = MediaQuery.sizeOf(context);
                setState(() {
                  final next = _pipOffset + details.delta;
                  _pipOffset = Offset(
                    next.dx.clamp(0, size.width - _pipWidth),
                    next.dy.clamp(0, size.height - _pipHeight - 120),
                  );
                });
              },
              child: Container(
                width: _pipWidth,
                height: _pipHeight,
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
