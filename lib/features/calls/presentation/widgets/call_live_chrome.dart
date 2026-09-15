import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/profile_image_widget.dart';
import '../../data/models/call_reconnect_policy.dart';
import '../../data/models/live_call_ui_state.dart';
import '../../providers/agora_rtc_session_provider.dart';
import '../../providers/live_call_ui_provider.dart';
import '../../utils/call_audio_route.dart';
import 'agora_call_video_layer.dart';
import 'call_connect_transition.dart';
import 'call_network_signal.dart';
import 'call_reconnecting_overlay.dart';
import 'call_speaking_ring.dart';

typedef _RtcHeaderSlice = ({
  bool reconnecting,
  bool failed,
  String? userFacingError,
});

/// Remote + local video; watches only camera / remote-uid slices so timer
/// and mute ticks do not rebuild Agora textures.
class CallLiveVideoStage extends ConsumerWidget {
  final RtcEngine engine;
  final String channelId;
  final String? localAvatarUrl;
  final String? remoteAvatarUrl;
  final int localUserId;
  final int remoteUserId;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onStageTap;

  const CallLiveVideoStage({
    super.key,
    required this.engine,
    required this.channelId,
    this.localAvatarUrl,
    this.remoteAvatarUrl,
    this.localUserId = 0,
    this.remoteUserId = 0,
    this.onFlipCamera,
    this.onStageTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(
      agoraRtcSessionProvider.select(
        (state) => (
          remoteUid: state.remoteUid,
          remoteCameraOn: state.remoteCameraOn,
          localCameraFailed: state.localCameraFailed,
          localCameraCaption: state.localCameraCaption,
          remoteCameraCaption: state.remoteCameraCaption,
        ),
      ),
    );
    final cameraOn = ref.watch(isCameraOnProvider);
    return AgoraCallVideoLayer(
      engine: engine,
      channelId: channelId,
      remoteUid: slice.remoteUid,
      localCameraOn: cameraOn && !slice.localCameraFailed,
      remoteCameraOn: slice.remoteCameraOn,
      localAvatarUrl: localAvatarUrl,
      remoteAvatarUrl: remoteAvatarUrl,
      localUserId: localUserId,
      remoteUserId: remoteUserId,
      localCameraCaption: slice.localCameraCaption,
      remoteCameraCaption: slice.remoteCameraCaption,
      onFlipCamera: onFlipCamera,
      onStageTap: onStageTap,
    );
  }
}

/// Name + timer / ringing status. Timer watches [callTimerProvider] only.
class OutgoingCallHeader extends ConsumerWidget {
  final String recipientName;
  final int recipientId;
  final String? photoUrl;
  final String? statusLabel;
  final String? connectionError;
  final bool showDeclined;

  const OutgoingCallHeader({
    super.key,
    required this.recipientName,
    required this.recipientId,
    this.photoUrl,
    this.statusLabel,
    this.connectionError,
    this.showDeclined = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(callStatusProvider);
    final duration = ref.watch(callTimerProvider);
    final remoteSpeaking = connected && ref.watch(remoteSpeakingProvider);
    final rtc = ref.watch(
      agoraRtcSessionProvider.select(
        (state) => (
          reconnecting: state.isReconnecting,
          failed: state.isFailed,
          userFacingError: state.userFacingError,
        ),
      ),
    );
    final isError = (connectionError != null || rtc.userFacingError != null) &&
        !connected &&
        !rtc.reconnecting;
    final statusStyle = AppTypography.bodySmall.copyWith(
      color: isError
          ? AppColors.feedbackError
          : AppColors.textPrimaryDark.withValues(alpha: 0.7),
    );

    return Row(
      children: [
        CallSpeakingRing(
          active: remoteSpeaking,
          diameter: 40,
          child: ClipOval(
            child: ProfileImageWidget(
              imageUrl: photoUrl,
              userId: recipientId,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                recipientName,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
                maxLines: 1,
              ),
              _statusLine(
                context: context,
                connected: connected,
                duration: duration,
                rtc: rtc,
                style: statusStyle,
              ),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.spacingSM),
        const CallNetworkSignal(),
      ],
    );
  }

  Widget _statusLine({
    required BuildContext context,
    required bool connected,
    required Duration duration,
    required _RtcHeaderSlice rtc,
    required TextStyle style,
  }) {
    if (showDeclined) {
      return Text('Call declined', style: style);
    }
    if (connectionError == CallReconnectPolicy.lostMessage) {
      return Text(CallReconnectPolicy.lostMessage, style: style);
    }
    if (rtc.reconnecting) {
      return Text('Reconnecting…', style: style);
    }
    if (rtc.failed && !connected) {
      return Text(
        rtc.userFacingError ?? statusLabel ?? 'Connection failed',
        style: style,
      );
    }

    if (CallConnectScope.maybeOf(context) == null) {
      return Text(
        connected
            ? LiveCallUiState.formatDuration(duration)
            : (statusLabel ?? 'Connecting...'),
        style: style,
      );
    }

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        CallConnectRingingLabel(
          child: Text(statusLabel ?? 'Connecting...', style: style),
        ),
        CallConnectTimer(
          child: Text(
            LiveCallUiState.formatDuration(duration),
            style: style,
          ),
        ),
      ],
    );
  }
}

class CallReconnectLayer extends ConsumerWidget {
  final bool leaving;

  const CallReconnectLayer({super.key, required this.leaving});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconnecting = ref.watch(
      agoraRtcSessionProvider.select((state) => state.isReconnecting),
    );
    return CallReconnectingOverlay(visible: reconnecting && !leaving);
  }
}

class CallMuteButton extends ConsumerWidget {
  final VoidCallback onTap;
  final double size;

  const CallMuteButton({
    super.key,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(isMutedProvider);
    return Semantics(
      label: muted ? 'Unmute microphone' : 'Mute microphone',
      button: true,
      child: RepaintBoundary(
        child: _CallActionButton(
          icon: muted ? AppIcons.microphoneSlash : AppIcons.microphone,
          label: 'mute',
          onTap: onTap,
          isDark: true,
          size: size,
          overlayStyle: true,
          isActive: muted,
        ),
      ),
    );
  }
}

class CallFlipButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const CallFlipButton({
    super.key,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Flip camera',
      button: true,
      child: RepaintBoundary(
        child: _CallActionButton(
          icon: AppIcons.getIconPath('rotate-right'),
          label: 'flip',
          onTap: onTap,
          isDark: true,
          size: size,
          overlayStyle: true,
        ),
      ),
    );
  }
}

class CallEndButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const CallEndButton({
    super.key,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'End call',
      button: true,
      child: RepaintBoundary(
        child: _CallActionButton(
          icon: AppIcons.close,
          label: 'end',
          onTap: onTap,
          isDark: true,
          isDestructive: true,
          size: size,
          overlayStyle: true,
        ),
      ),
    );
  }
}

class CallHideButton extends StatelessWidget {
  final VoidCallback onTap;

  const CallHideButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hide call and open chat',
      button: true,
      child: ExcludeSemantics(
        child: _CallPillButton(
          icon: AppIcons.message,
          label: 'Chat',
          onTap: onTap,
        ),
      ),
    );
  }
}

class CallCameraPill extends ConsumerWidget {
  final VoidCallback onTap;

  const CallCameraPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraOn = ref.watch(isCameraOnProvider);
    return _CallPillButton(
      icon: cameraOn ? AppIcons.camera : AppIcons.cameraSlash,
      label: cameraOn ? 'Camera On' : 'Camera Off',
      onTap: onTap,
    );
  }
}

class CallSpeakerPill extends ConsumerWidget {
  final VoidCallback onTap;

  const CallSpeakerPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speakerOn = ref.watch(isSpeakerOnProvider);
    final routing = ref.watch(
      agoraRtcSessionProvider.select((state) => state.audioRoute),
    );
    final kind = CallAudioRoute.kind(
      routing,
      fallbackSpeakerOn: speakerOn,
    );
    final locked = !CallAudioRoute.canToggleSpeaker(kind);
    return _CallPillButton(
      icon: CallAudioRoute.iconFor(kind),
      label: CallAudioRoute.labelFor(kind),
      onTap: locked ? null : onTap,
      isActive: kind == CallAudioRouteKind.speaker,
    );
  }
}

class _CallActionButton extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;
  final bool isActive;
  final bool overlayStyle;
  final double size;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
    this.isActive = false,
    this.overlayStyle = false,
    this.size = 56,
  });

  @override
  State<_CallActionButton> createState() => _CallActionButtonState();
}

class _CallActionButtonState extends State<_CallActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animate = AppAnimations.animationsEnabled(context);
    final iconDuration =
        animate ? AppAnimations.callMuteIconCrossfade : Duration.zero;
    final tintDuration = animate ? AppAnimations.callMuteTint : Duration.zero;
    final pressDuration = animate ? AppAnimations.tapDuration : Duration.zero;

    Color bg;
    Color fg;
    if (widget.isDestructive) {
      bg = AppColors.feedbackError;
      fg = AppColors.textPrimaryDark;
    } else if (widget.isActive) {
      bg = theme.colorScheme.error.withValues(alpha: 0.20);
      fg = AppColors.textPrimaryDark;
    } else if (widget.overlayStyle) {
      bg = AppColors.cardBackgroundDark;
      fg = AppColors.textPrimaryDark;
    } else {
      bg = widget.isDark
          ? AppColors.cardBackgroundDark
          : AppColors.cardBackgroundLight;
      fg = widget.isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: _pressed ? AppAnimations.buttonPressScale : 1.0,
          duration: pressDuration,
          curve: AppAnimations.curveDefault,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              onHighlightChanged: (highlighted) {
                if (!animate) return;
                setState(() => _pressed = highlighted);
              },
              child: AnimatedContainer(
                duration: tintDuration,
                curve: AppAnimations.curveDefault,
                width: widget.size,
                height: widget.size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: iconDuration,
                  switchInCurve: AppAnimations.curveDefault,
                  switchOutCurve: AppAnimations.curveDefault,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: AppSvgIcon(
                    key: ValueKey(widget.icon),
                    assetPath: widget.icon,
                    size: widget.size * 0.43,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingXS),
        AppText(
          widget.label,
          style: AppTypography.labelSmall.copyWith(
            color: widget.overlayStyle || widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _CallPillButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _CallPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: isActive
            ? AppColors.cardBackgroundDark
            : AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingSM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(
                    assetPath: icon,
                    size: 20,
                    color: AppColors.textPrimaryDark,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Flexible(
                    child: AppText(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
