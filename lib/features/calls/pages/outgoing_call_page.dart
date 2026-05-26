import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/app_icons.dart';
import '../../../shared/services/agora_service.dart';
import '../../../shared/services/call_quality_monitor.dart';
import '../data/models/call_action_request.dart';
import '../data/services/call_signaling_service.dart';
import '../presentation/widgets/agora_call_video_layer.dart';
import '../providers/call_provider.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

enum OutgoingCallType { voice, video }

/// Full-screen outgoing / active call UI with Agora RTC.
class OutgoingCallPage extends ConsumerStatefulWidget {
  final int recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;
  final int callId;
  final OutgoingCallType type;
  final bool isCallee;

  const OutgoingCallPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
    required this.callId,
    required this.type,
    this.isCallee = false,
  });

  @override
  ConsumerState<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends ConsumerState<OutgoingCallPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  late final AgoraService _agoraService;
  late final CallQualityMonitor _qualityMonitor;

  Timer? _durationTimer;
  Duration _duration = Duration.zero;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;
  bool _callConnected = false;
  bool _agoraJoined = false;
  bool _showDeclinedMessage = false;
  String? _statusLabel;
  String? _channelName;
  int? _remoteUid;
  String? _connectionError;
  String _networkQuality = 'unknown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agoraService = AgoraService();
    _qualityMonitor = CallQualityMonitor(_agoraService);
    _statusLabel = widget.isCallee ? 'Connecting...' : 'Calling...';

    final disableAnimations =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (!disableAnimations) {
      _pulseController.repeat();
    }

    _listenForCallEvents();
    if (widget.isCallee) {
      _onCallAccepted({});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_agoraJoined) return;
    if (state == AppLifecycleState.resumed && widget.type == OutgoingCallType.voice) {
      unawaited(_agoraService.setSpeakerphoneEnabled(_isSpeakerOn));
    }
  }

  void _listenForCallEvents() {
    ref.read(callSignalingServiceProvider).listen(
      callId: widget.callId,
      onAccepted: _onCallAccepted,
      onRejected: _onCallRejected,
      onEnded: _onCallEnded,
      onBusy: _onCallRejected,
    );
  }

  Future<void> _onCallAccepted(Map<String, dynamic> _) async {
    if (!mounted || _callConnected) return;
    setState(() {
      _callConnected = true;
      _statusLabel = null;
      _connectionError = null;
    });
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _duration = _duration + const Duration(seconds: 1));
      }
    });
    await WakelockPlus.enable();
    await _joinAgoraChannel();
  }

  Future<void> _joinAgoraChannel() async {
    final isVideo = widget.type == OutgoingCallType.video;
    try {
      _agoraService.onRemoteUserJoined = (uid) {
        if (!mounted) return;
        setState(() => _remoteUid = uid);
      };
      _agoraService.onRemoteUserLeft = (uid) {
        if (!mounted) return;
        setState(() => _remoteUid = null);
        if (_callConnected) {
          unawaited(Future.delayed(const Duration(seconds: 1), _endCall));
        }
      };
      _agoraService.onError = (message) {
        _qualityMonitor.recordError(message);
        if (!mounted) return;
        setState(() => _connectionError = message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      };
      _agoraService.onNetworkQuality = (_, rxQuality) {
        final label = _qualityFromScore(rxQuality);
        _qualityMonitor.updateNetworkQuality(label);
        if (!mounted) return;
        setState(() => _networkQuality = label);
      };
      _agoraService.onTokenRefreshRequired = () async {
        final tokenData =
            await ref.read(callSignalingServiceProvider).fetchAgoraToken(widget.callId);
        return tokenData.token;
      };

      final tokenData =
          await ref.read(callSignalingServiceProvider).fetchAgoraToken(widget.callId);

      await _agoraService.initialize(isVideoCall: isVideo);
      await _agoraService.joinChannel(
        channelId: tokenData.channelName,
        token: tokenData.token,
        userId: tokenData.uid,
        isVideoCall: isVideo,
      );

      _qualityMonitor.startMonitoring(
        callId: widget.callId.toString(),
        callerId: widget.isCallee ? widget.recipientId : tokenData.uid,
        receiverId: widget.isCallee ? tokenData.uid : widget.recipientId,
        callType: isVideo ? 'video' : 'voice',
      );

      if (!mounted) return;
      setState(() {
        _agoraJoined = true;
        _channelName = tokenData.channelName;
        _remoteUid = _agoraService.remoteUid;
      });
    } catch (e) {
      _qualityMonitor.recordError(e.toString());
      if (mounted) {
        setState(() {
          _connectionError = 'Connection failed';
          _statusLabel = 'Connection failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
        await _endCall();
      }
    }
  }

  String _qualityFromScore(int score) {
    if (score <= 1) return 'good';
    if (score <= 3) return 'poor';
    if (score >= 4) return 'bad';
    return 'unknown';
  }

  void _onCallRejected(Map<String, dynamic> _) {
    if (!mounted) return;
    setState(() {
      _showDeclinedMessage = true;
      _statusLabel = 'Call declined';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.pop();
    });
  }

  void _onCallEnded(Map<String, dynamic> _) {
    if (mounted) context.pop();
  }

  Future<void> _endCall() async {
    _qualityMonitor.stopMonitoring(callSuccessful: _agoraJoined);
    await WakelockPlus.disable();

    try {
      await ref.read(callProvider.notifier).endCall(
            CallActionRequest.end(widget.callId.toString()),
          );
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'outgoing_call_page', error: e); }

    try {
      await _agoraService.leaveChannel();
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'outgoing_call_page', error: e); }

    ref.read(callSignalingServiceProvider).disposeCall(widget.callId);
    if (mounted) context.pop();
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _agoraService.toggleAudio(!_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _agoraService.setSpeakerphoneEnabled(_isSpeakerOn);
  }

  Future<void> _toggleCamera() async {
    setState(() => _isCameraOn = !_isCameraOn);
    await _agoraService.toggleVideo(_isCameraOn);
  }

  Future<void> _flipCamera() async {
    await _agoraService.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationTimer?.cancel();
    _pulseController.dispose();
    _qualityMonitor.stopMonitoring(callSuccessful: false, failureReason: 'disposed');
    unawaited(WakelockPlus.disable());
    ref.read(callSignalingServiceProvider).disposeCall(widget.callId);
    unawaited(_agoraService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isVideo = widget.type == OutgoingCallType.video;
    final showVideoLayer =
        isVideo && _callConnected && _agoraJoined && _agoraService.engine != null && _channelName != null;

    return Scaffold(
      backgroundColor: isVideo ? Colors.black : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showVideoLayer)
              AgoraCallVideoLayer(
                engine: _agoraService.engine!,
                channelId: _channelName!,
                remoteUid: _remoteUid,
                showLocalPreview: _isCameraOn,
                mirrorLocal: _isFrontCamera,
              )
            else
              _buildVoiceOrRingingBody(theme, isDark, textPrimary, textSecondary),
            if (showVideoLayer)
              Positioned(
                top: AppSpacing.spacingMD,
                left: AppSpacing.spacingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipientName,
                      style: AppTypography.titleLarge.copyWith(color: Colors.white),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            if (_networkQuality == 'poor' || _networkQuality == 'bad')
              Positioned(
                top: AppSpacing.spacingMD,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.feedbackWarning.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _networkQuality == 'bad' ? 'Poor connection' : 'Unstable connection',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimaryDark),
                    ),
                  ),
                ),
              ),
            if (_connectionError != null && !_callConnected)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  child: Text(
                    _connectionError!,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.feedbackError),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.spacingXL,
              child: _buildControls(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceOrRingingBody(
    ThemeData theme,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_callConnected) ...[
                  _PulsingRing(controller: _pulseController, intervalBegin: 0.0, intervalEnd: 0.33),
                  _PulsingRing(controller: _pulseController, intervalBegin: 0.33, intervalEnd: 0.66),
                  _PulsingRing(controller: _pulseController, intervalBegin: 0.66, intervalEnd: 1.0),
                ],
                ClipOval(
                  child: widget.recipientAvatarUrl != null
                      ? ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: _callConnected ? 0 : 8,
                            sigmaY: _callConnected ? 0 : 8,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: widget.recipientAvatarUrl!,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 140,
                          height: 140,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: AppSvgIcon(
                            assetPath: AppIcons.userOutline,
                            size: 48,
                            color: textSecondary,
                          ),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Text(
            widget.recipientName,
            style: AppTypography.headlineSmall.copyWith(color: textPrimary),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            _showDeclinedMessage
                ? 'Call declined'
                : (_callConnected
                    ? _formatDuration(_duration)
                    : (_statusLabel ?? 'Calling...')),
            style: AppTypography.bodyLarge.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isDark) {
    final isVideo = widget.type == OutgoingCallType.video;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Semantics(
            label: _isMuted ? 'Unmute microphone' : 'Mute microphone',
            button: true,
            child: _CallActionButton(
              icon: _isMuted ? AppIcons.microphoneSlash : AppIcons.microphone,
              label: _isMuted ? 'Unmute' : 'Mute',
              onTap: _toggleMute,
              isDark: isDark,
            ),
          ),
          Semantics(
            label: 'End call',
            button: true,
            child: _CallActionButton(
              icon: AppIcons.callMissed,
              label: 'End',
              onTap: _endCall,
              isDark: isDark,
              isDestructive: true,
            ),
          ),
          if (isVideo)
            Semantics(
              label: _isCameraOn ? 'Turn camera off' : 'Turn camera on',
              button: true,
              child: _CallActionButton(
                icon: AppIcons.video,
                label: _isCameraOn ? 'Camera' : 'Cam off',
                onTap: _toggleCamera,
                isDark: isDark,
              ),
            )
          else
            Semantics(
              label: _isSpeakerOn ? 'Speaker on' : 'Speaker off',
              button: true,
              child: _CallActionButton(
                icon: AppIcons.getIconPath('volume-high'),
                label: 'Speaker',
                onTap: _toggleSpeaker,
                isDark: isDark,
                isActive: _isSpeakerOn,
              ),
            ),
          if (isVideo)
            Semantics(
              label: 'Flip camera',
              button: true,
              child: _CallActionButton(
                icon: AppIcons.getIconPath('rotate-right'),
                label: 'Flip',
                onTap: _flipCamera,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PulsingRing extends StatelessWidget {
  final AnimationController controller;
  final double intervalBegin;
  final double intervalEnd;

  const _PulsingRing({
    required this.controller,
    required this.intervalBegin,
    required this.intervalEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) return const SizedBox.shrink();

    final scale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(intervalBegin, intervalEnd, curve: Curves.easeOut),
      ),
    );
    final opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(intervalBegin, intervalEnd, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: Opacity(
            opacity: opacity.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;
  final bool isActive;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    if (isDestructive) {
      bg = AppColors.feedbackError;
      fg = AppColors.textPrimaryDark;
    } else if (isActive) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else {
      bg = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;
      fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: AppSvgIcon(assetPath: icon, size: 24, color: fg),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.spacingXS),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
