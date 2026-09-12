import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/agora_config.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../../../features/profile/providers/profile_providers.dart';
import '../../../features/settings/providers/sound_preferences_provider.dart';
import '../../../features/user/providers/user_providers.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/agora_rtc_types.dart';
import '../../../shared/services/agora_service.dart';
import '../../../shared/services/call_permissions.dart';
import '../../../shared/services/call_quality_monitor.dart';
import '../../../shared/services/call_token_refresh.dart';
import '../data/models/call.dart';
import '../data/models/call_action_request.dart';
import '../data/models/call_end_summary.dart';
import '../data/models/call_hud_policy.dart';
import '../data/models/call_initiate_exception.dart';
import '../data/models/call_reconnect_policy.dart';
import '../data/models/call_wake_lock.dart';
import '../data/models/active_call_session.dart';
import '../data/services/call_signaling_service.dart';
import '../presentation/widgets/call_end_overlay.dart';
import '../presentation/widgets/call_connect_transition.dart';
import '../presentation/widgets/call_hud.dart';
import '../presentation/widgets/call_live_chrome.dart';
import '../presentation/widgets/call_quality_toast.dart';
import '../presentation/widgets/call_outgoing_pulse.dart';
import '../presentation/widgets/call_permission_sheet.dart';
import '../presentation/widgets/call_stage_placeholder.dart';
import '../providers/active_call_session_provider.dart';
import '../providers/agora_rtc_session_provider.dart';
import '../providers/call_end_summary_provider.dart';
import '../providers/call_provider.dart';
import '../providers/call_providers.dart';
import '../providers/live_call_ui_provider.dart';
import '../providers/messenger_calls_provider.dart';
import '../utils/call_log_labels.dart';
import '../utils/call_audio_route.dart';
import '../utils/call_navigation.dart';
import '../utils/call_ring_timeout.dart';

enum OutgoingCallType { voice, video }

/// Full-screen outgoing / active call UI with Agora RTC.
class OutgoingCallPage extends ConsumerStatefulWidget {
  final int recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;
  final int callId;
  final OutgoingCallType type;
  final bool isCallee;
  final bool shouldInitiate;

  const OutgoingCallPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
    required this.callId,
    required this.type,
    this.isCallee = false,
    this.shouldInitiate = false,
  });

  @override
  ConsumerState<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends ConsumerState<OutgoingCallPage>
    with WidgetsBindingObserver {
  late final AgoraService _agoraService;
  late final CallQualityMonitor _qualityMonitor;
  late final CallSignalingService _signaling;
  final CallWakeLock _wakeLock = CallWakeLock();

  Timer? _durationTimer;
  bool _agoraJoined = false;
  String? _statusLabel;
  String? _channelName;
  String? _connectionError;
  late int _callId;
  bool _leaving = false;
  bool _hangupTonePlayed = false;
  bool _joiningAgora = false;
  bool _endPosted = false;
  Timer? _acceptPollTimer;
  Timer? _ringTimeoutTimer;
  Timer? _remoteLeftTimer;
  Timer? _reconnectWatchdog;
  StreamSubscription<NetworkConnectionState>? _connectivitySub;
  final CallReconnectPolicy _reconnect = CallReconnectPolicy();
  CallRtcConnectionUi? _lastRtcConnection;
  bool _giveUpStarted = false;
  bool _preservingEngine = false;
  String? _primaryPhotoUrl;
  String? _backdropPhotoUrl;
  String? _localAvatarUrl;
  int _localUserId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agoraService = AgoraService();
    _qualityMonitor = CallQualityMonitor(_agoraService);
    _signaling = ref.read(callSignalingServiceProvider);
    _callId = widget.callId;
    _statusLabel = 'Connecting...';
    unawaited(_wakeLock.enable());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = ref.read(activeCallSessionProvider);
      final resuming = ActiveCallLifecycle.shouldResume(
        pageCallId: widget.callId,
        session: session,
        agoraInCall: _agoraService.isInCall,
      );
      if (resuming && session != null) {
        unawaited(_resumeActiveCall(session));
        return;
      }
      ref.read(agoraRtcSessionProvider.notifier).reset();
      ref.read(liveCallUiProvider.notifier).reset(
            speakerOn: widget.type == OutgoingCallType.video,
          );
      final me = ref.read(cachedCurrentUserProvider).asData?.value;
      _localUserId = me?.id ?? 0;
      _localAvatarUrl = me?.avatarUrl;
      unawaited(_resolveCallPhotos());
      _connectivitySub ??=
          ConnectivityService.instance.onStateChange.listen(_onConnectivityState);
      if (!widget.isCallee) {
        unawaited(SoundService.instance.startOutgoingRingback());
      }
      if (widget.shouldInitiate || _callId <= 0) {
        unawaited(_startOutgoing());
      } else if (widget.isCallee) {
        _listenForCallEvents();
        unawaited(_onCallAccepted({}));
      } else {
        _listenForCallEvents();
        unawaited(_joinAgoraChannel());
        _startAcceptPoll();
        _startRingTimeout();
      }
    });
  }

  String? get _headerPhotoUrl => _primaryPhotoUrl ?? widget.recipientAvatarUrl;

  String? get _displayBackdropUrl =>
      _backdropPhotoUrl ?? _primaryPhotoUrl ?? widget.recipientAvatarUrl;

  bool _sessionConnected() => ref.read(liveCallUiProvider).connected;

  LiveCallUiNotifier get _liveUi => ref.read(liveCallUiProvider.notifier);

  Future<void> _resolveCallPhotos() async {
    if (widget.recipientId <= 0) return;
    try {
      final profile = await ref
          .read(profileServiceProvider)
          .getUserProfile(widget.recipientId);
      final primaryUrl = primaryProfilePhotoUrl(profile.images);
      final backdropUrl = firstNonPrimaryProfilePhotoUrl(profile.images);
      if (!mounted) return;
      setState(() {
        if (primaryUrl != null && primaryUrl.isNotEmpty) {
          _primaryPhotoUrl = primaryUrl;
        }
        if (backdropUrl != null && backdropUrl.isNotEmpty) {
          _backdropPhotoUrl = backdropUrl;
        }
      });
    } catch (e) {
      AppLogger.warning(
        'Could not resolve call photos',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_agoraJoined || !_sessionConnected()) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreLocalMedia());
    }
  }

  void _listenForCallEvents() {
    if (_callId <= 0) return;
    _signaling.listen(
      callId: _callId,
      onAccepted: _onCallAccepted,
      onRejected: _onCallRejected,
      onEnded: _onCallEnded,
      onBusy: _onCallRejected,
    );
  }

  void _cancelRingingTimers() {
    _acceptPollTimer?.cancel();
    _ringTimeoutTimer?.cancel();
  }

  /// Caller UI timeout only — never `POST reject` / `POST end`.
  void _startRingTimeout() {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(CallRingTimeout.duration, () async {
      if (!mounted || _sessionConnected() || _leaving || _callId <= 0) return;
      try {
        final call = await ref
            .read(callRepositoryProvider)
            .getCall(_callId.toString());
        if (!mounted || _sessionConnected() || _leaving) return;
        final status = call.status.toLowerCase();
        if (status == 'active' || status == 'connected') {
          unawaited(_onCallAccepted({}));
          return;
        }
        if (CallLogLabels.isTerminalStatus(status)) {
          _onCallEnded({'status': status});
          return;
        }
      } catch (e) {
        AppLogger.warning(
          'Ring timeout getCall failed',
          tag: 'outgoing_call_page',
          error: e,
        );
        if (!mounted || _sessionConnected() || _leaving) return;
      }
      _onCallEnded({'status': 'missed'});
    });
  }

  void _startAcceptPoll() {
    _acceptPollTimer?.cancel();
    var ticks = 0;
    _acceptPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _sessionConnected() || _leaving || _callId <= 0) {
        _acceptPollTimer?.cancel();
        return;
      }
      ticks += 1;
      if (ticks > 23) {
        _acceptPollTimer?.cancel();
        return;
      }
      try {
        final call = await ref.read(callRepositoryProvider).getCall(_callId.toString());
        if (!mounted || _sessionConnected() || _leaving) return;
        final status = call.status.toLowerCase();
        if (status == 'active' || status == 'connected') {
          _cancelRingingTimers();
          unawaited(_onCallAccepted({}));
        } else if (CallLogLabels.isTerminalStatus(status)) {
          _cancelRingingTimers();
          _onCallEnded({'status': status});
        }
      } catch (e) {
        AppLogger.warning(
          'Accept poll getCall failed',
          tag: 'outgoing_call_page',
          error: e,
        );
      }
    });
  }

  String _userFacingCallError(Object error) {
    final text = error.toString();
    if (text.contains('No space left') ||
        text.contains('Writing to the log') ||
        text.contains('errno=28') ||
        text.contains('ApiError')) {
      return 'Connection failed';
    }
    return 'Connection failed';
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() {
      _statusLabel = message;
      _connectionError = null;
    });
  }

  void _leaveCallUi() {
    if (!mounted) return;
    leaveCallRoute(
      context,
      callId: _callId > 0 ? _callId.toString() : null,
    );
  }

  ActiveCallSession _currentSession({bool minimized = false}) {
    return ActiveCallSession(
      callId: _callId,
      peerId: widget.recipientId,
      peerName: widget.recipientName,
      peerAvatarUrl: widget.recipientAvatarUrl ?? _headerPhotoUrl,
      isVideo: widget.type == OutgoingCallType.video,
      channelName: _channelName ?? _agoraService.currentChannelId,
      agoraJoined: _agoraJoined || _agoraService.isInCall,
      minimized: minimized,
      isCallee: widget.isCallee,
    );
  }

  void _syncActiveSession() {
    if (_callId <= 0) return;
    try {
      ref.read(activeCallSessionProvider.notifier).attach(_currentSession());
    } catch (e) {
      AppLogger.warning(
        'attach active session failed',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
  }

  void _clearActiveSession() {
    try {
      ref.read(activeCallSessionProvider.notifier).clearUiOnly();
    } catch (e) {
      AppLogger.warning(
        'clear active session failed',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
  }

  void _minimizeCall() {
    if (_leaving || _callId <= 0 || !_sessionConnected()) return;
    _preservingEngine = true;
    try {
      ref.read(activeCallSessionProvider.notifier).minimize(_currentSession());
    } catch (e) {
      AppLogger.warning(
        'minimize active session failed',
        tag: 'outgoing_call_page',
        error: e,
      );
      _preservingEngine = false;
      return;
    }
    if (!mounted) return;
    leaveCallRoute(context);
  }

  Future<void> _resumeActiveCall(ActiveCallSession session) async {
    _callId = session.callId;
    _channelName = _agoraService.currentChannelId ?? session.channelName;
    unawaited(_wakeLock.enable());
    final me = ref.read(cachedCurrentUserProvider).asData?.value;
    _localUserId = me?.id ?? 0;
    _localAvatarUrl = me?.avatarUrl;
    unawaited(_resolveCallPhotos());
    _connectivitySub ??=
        ConnectivityService.instance.onStateChange.listen(_onConnectivityState);
    _listenForCallEvents();
    try {
      ref.read(activeCallSessionProvider.notifier).reveal();
    } catch (e) {
      AppLogger.warning(
        'reveal active session failed',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
    await _joinAgoraChannel();
    if (!mounted) return;
    if (_sessionConnected()) {
      _statusLabel = null;
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          _liveUi.tick();
        }
      });
    }
    if (mounted) setState(() {});
  }

  void _failOnPage(String message) {
    unawaited(SoundService.instance.stopCallSounds());
    if (!mounted) return;
    setState(() {
      _statusLabel = message;
      _connectionError = message;
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_sessionConnected()) _leaveCallUi();
    });
  }

  Future<void> _startOutgoing() async {
    _setStatus('Connecting...');
    final isVideo = widget.type == OutgoingCallType.video;
    final allowed = await ensureCallMediaPermissions(context, video: isVideo);
    if (!allowed) {
      if (mounted) _leaveCallUi();
      return;
    }
    if (!mounted) return;
    try {
      final apiType = widget.type == OutgoingCallType.video ? 'video' : 'voice';
      final call = await ref.read(callProvider.notifier).initiateCall(
            InitiateCallRequest(
              receiverId: widget.recipientId,
              callType: apiType,
            ),
          );
      if (!mounted) return;
      final id = call != null && call.id > 0
          ? call.id
          : int.tryParse(call?.callId ?? '') ?? 0;
      if (id <= 0) {
        _failOnPage('Could not start call');
        return;
      }
      _callId = id;
      _listenForCallEvents();
      unawaited(_joinAgoraChannel());
      _startAcceptPoll();
      _startRingTimeout();
      _setStatus('Ringing...');
    } on CallInitiateException catch (e) {
      if (e.alreadyInCall) {
        await _rejoinActiveCall();
        return;
      }
      _failOnPage(e.message);
    } on ApiError catch (e) {
      if (e.message.toLowerCase().contains('already an active call')) {
        await _rejoinActiveCall();
        return;
      }
      _failOnPage(e.message);
    } catch (e) {
      AppLogger.warning('Outgoing call start failed', tag: 'outgoing_call_page', error: e);
      _failOnPage('Could not start call');
    }
  }

  Future<void> _rejoinActiveCall() async {
    _setStatus('Connecting...');
    final existing = await ref.read(callRepositoryProvider).getActiveCall();
    if (!mounted) return;
    if (existing == null || existing.id <= 0) {
      _failOnPage('There is already an active call with this user');
      return;
    }
    final peer = widget.recipientId;
    final involvesPeer =
        existing.callerId == peer || existing.receiverId == peer;
    if (!involvesPeer) {
      _failOnPage("You're already in another call");
      return;
    }
    await _attachExistingCall(existing);
  }

  Future<void> _attachExistingCall(Call existing) async {
    _callId = existing.id;
    _listenForCallEvents();
    final me = ref.read(cachedCurrentUserProvider).asData?.value.id ?? 0;
    final iAmCallee = me > 0 && existing.receiverId == me;
    final status = existing.status.toLowerCase();
    final live = status == 'active' || status == 'connected';
    if (live || iAmCallee) {
      if (iAmCallee && !live) {
        final allowed = await ensureCallMediaPermissions(
          context,
          video: widget.type == OutgoingCallType.video,
        );
        if (!allowed || !mounted) {
          if (mounted) _leaveCallUi();
          return;
        }
        try {
          await ref.read(callProvider.notifier).acceptCall(
                CallActionRequest.accept(_callId.toString()),
              );
        } catch (e) {
          AppLogger.warning('Could not accept existing call', tag: 'outgoing_call_page', error: e);
        }
      }
      await _onCallAccepted({});
      return;
    }
    _setStatus('Connecting...');
  }

  Future<void> _onCallAccepted(Map<String, dynamic> _) async {
    if (!mounted || _sessionConnected()) return;
    _cancelRingingTimers();
    _remoteLeftTimer?.cancel();
    await SoundService.instance.stopCallSounds();
    if (!mounted || _sessionConnected()) return;
    unawaited(SoundService.instance.playCallConnect());
    _liveUi.setConnected(true);
    if (mounted) {
      setState(() {
        _connectionError = null;
      });
    }
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _liveUi.tick();
      }
    });
    if (!_agoraJoined) {
      await _joinAgoraChannel();
    }
    _syncActiveSession();
  }

  Future<void> _joinAgoraChannel() async {
    if (_joiningAgora || _callId <= 0) return;
    _joiningAgora = true;
    final isVideo = widget.type == OutgoingCallType.video;
    final rtc = ref.read(agoraRtcSessionProvider.notifier);
    try {
      _agoraService.onRemoteUserJoined = (uid) {
        if (!mounted) return;
        _remoteLeftTimer?.cancel();
        _remoteLeftTimer = null;
        rtc.remoteUserJoined(uid);
      };
      _agoraService.onRemoteUserLeft = (_) {};
      _agoraService.onRemoteUserOffline = (uid, reason) {
        if (!mounted) return;
        rtc.remoteUserLeft(uid, reason);
        if (!_sessionConnected()) return;
        if (reason == CallRemoteLeaveReason.quit) {
          _remoteLeftTimer?.cancel();
          _remoteLeftTimer = null;
          _setStatus('Call ended');
          unawaited(_endCall());
          return;
        }
        if (reason == CallRemoteLeaveReason.dropped) {
          _qualityMonitor.recordConnectionDrop();
          _remoteLeftTimer?.cancel();
          _remoteLeftTimer = Timer(const Duration(seconds: 8), () {
            if (!mounted || _leaving) return;
            final stillGone =
                ref.read(agoraRtcSessionProvider).remoteUid == null;
            if (!stillGone) return;
            unawaited(_endCall());
          });
        }
      };
      _agoraService.onRemoteVideoMuted = (uid, muted) {
        if (!mounted) return;
        final current = ref.read(agoraRtcSessionProvider).remoteUid;
        if (current != null && uid != current) return;
        rtc.setRemoteCameraOn(!muted);
      };
      _agoraService.onRemoteVideoUiChanged = ({
        required bool stopped,
        required bool frozen,
      }) {
        if (!mounted) return;
        rtc.setRemoteVideoUi(stopped: stopped, frozen: frozen);
      };
      _agoraService.onLocalCameraFailed = (failed, message) {
        if (!mounted) return;
        rtc.setLocalCameraFailed(failed, message: message);
      };
      _agoraService.onRtcUiConnectionChanged = (state) {
        if (!mounted) return;
        final previous = _lastRtcConnection;
        final wasUnstable = previous == CallRtcConnectionUi.reconnecting ||
            previous == CallRtcConnectionUi.failed ||
            _reconnect.inFlight;
        rtc.setConnection(state);
        _lastRtcConnection = state;
        if (state == CallRtcConnectionUi.reconnecting &&
            previous != CallRtcConnectionUi.reconnecting) {
          _qualityMonitor.recordConnectionDrop();
          if (_sessionConnected()) {
            _armReconnectWatchdog();
          }
        }
        if (state == CallRtcConnectionUi.connected &&
            _sessionConnected() &&
            _agoraJoined &&
            wasUnstable) {
          _cancelReconnectWatchdog();
          _reconnect.markRecovered();
          rtc.setReconnectInFlight(false);
          unawaited(_restoreLocalMedia());
        }
        if (state == CallRtcConnectionUi.failed && _sessionConnected()) {
          unawaited(_retryOrEndCall());
        }
        if (state == CallRtcConnectionUi.failed && !_sessionConnected()) {
          _failOnPage('Connection failed');
        }
      };
      _agoraService.onError = (message) {
        _qualityMonitor.recordError(message);
        if (!mounted) return;
        rtc.setUserFacingError(message);
        if (!_sessionConnected()) {
          setState(() {
            _connectionError = message;
            _statusLabel = message;
          });
        }
      };
      _agoraService.onWarning = (message) {
        AppLogger.warning(message, tag: 'outgoing_call_page');
      };
      _agoraService.onNetworkQuality = (_, label) {
        _qualityMonitor.updateNetworkQuality(label);
        if (!mounted) return;
        rtc.setNetworkQuality(label);
      };
      _agoraService.onRtcStatsUpdate = ({
        required int bitrateKbps,
        required int packetLossPercent,
      }) {
        _qualityMonitor.applyRtcStats(
          bitrateKbps: bitrateKbps,
          packetLossPercent: packetLossPercent,
        );
        if (!mounted) return;
        rtc.setRtcStats(
          bitrateKbps: bitrateKbps,
          packetLossPercent: packetLossPercent,
        );
      };
      _agoraService.onSpeakingChanged = ({
        int? remoteUid,
        required bool localSpeaking,
      }) {
        if (!mounted) return;
        rtc.setSpeaking(remoteUid: remoteUid, localSpeaking: localSpeaking);
      };
      _agoraService.onFirstRemoteVideoFrame = (uid, width, height) {
        if (!mounted) return;
        rtc.setFirstRemoteVideoFrame();
      };
      _agoraService.onAudioRouteChanged = (routing) {
        if (!mounted) return;
        final previous = ref.read(agoraRtcSessionProvider).audioRoute;
        rtc.setAudioRoute(routing);
        final preference = ref.read(isSpeakerOnProvider);
        if (CallAudioRoute.shouldRestoreSpeakerPreference(
          previousRouting: previous,
          nextRouting: routing,
          speakerPreference: preference,
        )) {
          unawaited(_agoraService.setSpeakerphoneEnabled(preference));
        }
      };
      _agoraService.onTokenRefreshRequired = () async {
        try {
          final tokenData = await _signaling.fetchAgoraToken(_callId);
          return CallTokenRefreshResult(
            token: tokenData.token,
            expiresAt: tokenData.expiresAt,
          );
        } catch (e) {
          AppLogger.warning(
            'Agora token refresh failed',
            tag: 'outgoing_call_page',
            error: e,
          );
          return const CallTokenRefreshResult(token: '');
        }
      };

      if (ActiveCallLifecycle.shouldSkipJoin(
        agoraInCall: _agoraService.isInCall,
        engineChannelId: _agoraService.currentChannelId,
        sessionChannelId: _channelName,
        sessionJoined: _agoraJoined || _agoraService.isInCall,
      )) {
        if (!mounted) return;
        setState(() {
          _agoraJoined = true;
          _channelName = _agoraService.currentChannelId ?? _channelName;
        });
        _syncActiveSession();
        return;
      }

      final tokenData =
          await _signaling.fetchAgoraToken(_callId);
      final appId = AgoraConfig.resolveAppId(tokenData.appId);
      if (appId.isEmpty) {
        AppLogger.error(
          'Agora app_id missing from token payload',
          tag: 'outgoing_call_page',
        );
        if (mounted) _failOnPage('Connection failed');
        return;
      }

      await _agoraService.initialize(
        isVideoCall: isVideo,
        appId: appId,
      );
      await _agoraService.joinChannel(
        channelId: tokenData.channelName,
        token: tokenData.token,
        userId: tokenData.uid,
        isVideoCall: isVideo,
      );
      _agoraService.scheduleProactiveTokenRefresh(tokenData.expiresAt);

      _qualityMonitor.startMonitoring(
        callId: _callId.toString(),
        callerId: widget.isCallee ? widget.recipientId : tokenData.uid,
        receiverId: widget.isCallee ? tokenData.uid : widget.recipientId,
        callType: isVideo ? 'video' : 'voice',
      );

      if (!mounted) return;
      final existingRemote = _agoraService.remoteUid;
      if (existingRemote != null) {
        rtc.remoteUserJoined(existingRemote);
      }
      setState(() {
        _agoraJoined = true;
        _channelName = tokenData.channelName;
      });
      _syncActiveSession();
    } on CallPermissionDeniedException catch (e) {
      _qualityMonitor.recordError(e.toString());
      if (!mounted) return;
      await CallPermissionSheet.show(
        context,
        video: e.video,
        permanentlyDenied: e.permanentlyDenied,
      );
      if (mounted) _leaveCallUi();
    } catch (e) {
      _qualityMonitor.recordError(e.toString());
      if (mounted) {
        _failOnPage(_userFacingCallError(e));
      }
    } finally {
      _joiningAgora = false;
    }
  }

  void _onConnectivityState(NetworkConnectionState state) {
    if (state != NetworkConnectionState.connected) return;
    if (!_sessionConnected() || _leaving || !_agoraJoined || _giveUpStarted) return;
    final connection = ref.read(agoraRtcSessionProvider).connection;
    if (connection != CallRtcConnectionUi.reconnecting &&
        connection != CallRtcConnectionUi.failed) {
      return;
    }
    unawaited(_retryOrEndCall());
  }

  void _armReconnectWatchdog() {
    _reconnectWatchdog?.cancel();
    _reconnectWatchdog = Timer(CallReconnectPolicy.watchdog, () {
      if (!mounted || _leaving || !_sessionConnected()) return;
      final connection = ref.read(agoraRtcSessionProvider).connection;
      if (connection != CallRtcConnectionUi.reconnecting &&
          !_reconnect.inFlight) {
        return;
      }
      unawaited(_retryOrEndCall());
    });
  }

  void _cancelReconnectWatchdog() {
    _reconnectWatchdog?.cancel();
    _reconnectWatchdog = null;
  }

  Future<void> _restoreLocalMedia() async {
    if (_leaving || !_agoraJoined) return;
    await _agoraService.restoreLocalMedia(
      muted: ref.read(isMutedProvider),
      speakerOn: ref.read(isSpeakerOnProvider),
      cameraOn: ref.read(isCameraOnProvider),
      isVideoCall: widget.type == OutgoingCallType.video,
    );
  }

  Future<void> _retryOrEndCall() async {
    if (_leaving || _giveUpStarted || !_sessionConnected() || !_agoraJoined) return;
    if (!_reconnect.beginRetry()) {
      if (_reconnect.shouldGiveUp) {
        await _giveUpReconnect();
      }
      return;
    }
    _cancelReconnectWatchdog();
    final rtc = ref.read(agoraRtcSessionProvider.notifier);
    rtc.setReconnectInFlight(true);
    AppLogger.info(
      'Call rejoin attempt ${_reconnect.attempts}/${CallReconnectPolicy.maxAttempts}',
      tag: 'Agora',
    );
    try {
      final tokenData = await _signaling.fetchAgoraToken(_callId);
      if (!mounted || _leaving || _giveUpStarted) {
        _reconnect.markRetryFinished();
        rtc.setReconnectInFlight(false);
        return;
      }
      await _agoraService.rejoinChannel(
        channelId: tokenData.channelName,
        token: tokenData.token,
        userId: tokenData.uid,
        isVideoCall: widget.type == OutgoingCallType.video,
      );
      _agoraService.scheduleProactiveTokenRefresh(tokenData.expiresAt);
      if (!mounted || _leaving) {
        _reconnect.markRetryFinished();
        return;
      }
      await _restoreLocalMedia();
      _reconnect.markRecovered();
      rtc.setConnection(CallRtcConnectionUi.connected);
      rtc.setReconnectInFlight(false);
    } catch (e) {
      AppLogger.warning(
        'Call rejoin failed attempt=${_reconnect.attempts}',
        tag: 'Agora',
        error: e,
      );
      if (_agoraService.isInCall) {
        await _restoreLocalMedia();
        _reconnect.markRecovered();
        rtc.setConnection(CallRtcConnectionUi.connected);
        rtc.setReconnectInFlight(false);
        return;
      }
      _reconnect.markRetryFinished();
      rtc.setReconnectInFlight(_reconnect.canRetry);
      if (_reconnect.shouldGiveUp) {
        await _giveUpReconnect();
      } else {
        _armReconnectWatchdog();
      }
    }
  }

  Future<void> _giveUpReconnect() async {
    if (_giveUpStarted || _leaving) return;
    _giveUpStarted = true;
    _cancelReconnectWatchdog();
    _reconnect.markRetryFinished();
    final rtc = ref.read(agoraRtcSessionProvider.notifier);
    rtc.setReconnectInFlight(false);
    rtc.setConnection(CallRtcConnectionUi.failed);
    rtc.setUserFacingError(CallReconnectPolicy.lostMessage);
    AppLogger.warning(
      'Reconnect exhausted, ending call',
      tag: 'Agora',
    );
    if (mounted) {
      setState(() {
        _statusLabel = CallReconnectPolicy.lostMessage;
        _connectionError = CallReconnectPolicy.lostMessage;
      });
    }
    await _postEndIfNeeded();
    await Future<void>.delayed(CallReconnectPolicy.giveUpVisible);
    if (_leaving) return;
    await _endCall();
  }

  void _syncMessengerStatus(String status) {
    if (_callId <= 0) return;
    ref.read(messengerCallsProvider.notifier).applyRemoteStatus(
          callId: _callId,
          status: status,
        );
  }

  void _onCallRejected(Map<String, dynamic> payload) {
    if (_leaving) return;
    _leaving = true;
    _preservingEngine = false;
    _clearActiveSession();
    _cancelRingingTimers();
    _remoteLeftTimer?.cancel();
    _cancelReconnectWatchdog();
    unawaited(_playBusyTone());
    final status = payload['status']?.toString();
    _syncMessengerStatus(status ?? 'rejected');
    unawaited(_stopCallMedia());
    _presentEndSummary(
      CallEndSummary.resolve(
        wasConnected: false,
        status: status,
      ),
    );
  }

  void _onCallEnded(Map<String, dynamic> payload) {
    if (_leaving) return;
    _leaving = true;
    _preservingEngine = false;
    _clearActiveSession();
    _cancelRingingTimers();
    _remoteLeftTimer?.cancel();
    _cancelReconnectWatchdog();
    unawaited(_playHangupTone());
    final connected = _sessionConnected();
    final status = payload['status']?.toString();
    _syncMessengerStatus(status ?? (connected ? 'ended' : 'missed'));
    unawaited(_stopCallMedia());
    _presentEndSummary(
      CallEndSummary.resolve(
        wasConnected: connected,
        status: status,
        connectionError: _connectionError,
      ),
    );
  }

  Future<void> _playBusyTone() async {
    if (_hangupTonePlayed) return;
    _hangupTonePlayed = true;
    await SoundService.instance.stopCallSounds();
    await SoundService.instance.playCallBusy();
  }

  Future<void> _playHangupTone() async {
    if (_hangupTonePlayed) return;
    _hangupTonePlayed = true;
    await SoundService.instance.stopCallSounds();
    await SoundService.instance.playCallEnded();
  }

  Future<void> _endCall() async {
    if (_leaving) return;
    _leaving = true;
    _preservingEngine = false;
    _clearActiveSession();
    _cancelRingingTimers();
    _remoteLeftTimer?.cancel();
    _cancelReconnectWatchdog();
    unawaited(_playHangupTone());
    _qualityMonitor.stopMonitoring(callSuccessful: _agoraJoined);

    final connected = _sessionConnected();
    if (mounted) {
      _syncMessengerStatus(connected ? 'ended' : 'missed');
    }

    unawaited(_stopCallMedia());
    unawaited(_postEndIfNeeded());
    _presentEndSummary(
      CallEndSummary.resolve(
        wasConnected: connected,
        connectionError: _connectionError,
      ),
    );
  }

  Future<void> _stopCallMedia() async {
    _durationTimer?.cancel();
    await _wakeLock.disable();
    try {
      await _agoraService.dispose();
    } catch (e) {
      AppLogger.warning(
        'Agora teardown failed',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
    if (_callId > 0) {
      _signaling.disposeCall(_callId);
    }
  }

  void _presentEndSummary(CallEndReason reason) {
    if (!mounted) return;
    final live = ref.read(liveCallUiProvider);
    ref.read(callEndSummaryProvider.notifier).state = CallEndSummary(
      reason: reason,
      talkTime: live.duration,
      isVideo: widget.type == OutgoingCallType.video,
      wasConnected: live.connected,
    );
  }

  Future<void> _postEndIfNeeded({dynamic notifier}) async {
    if (_endPosted || _callId <= 0) return;
    _endPosted = true;
    final endCall = notifier ??
        (mounted ? ref.read(callProvider.notifier) : null);
    if (endCall == null) {
      _endPosted = false;
      return;
    }
    try {
      await endCall.endCall(CallActionRequest.end(_callId.toString()));
    } catch (e) {
      AppLogger.warning(
        'endCall API failed',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
  }

  Future<void> _toggleMute() async {
    final muted = !ref.read(isMutedProvider);
    _liveUi.setMuted(muted);
    await _agoraService.toggleAudio(!muted);
  }

  Future<void> _toggleSpeaker() async {
    final preference = ref.read(isSpeakerOnProvider);
    final kind = CallAudioRoute.kind(
      ref.read(agoraRtcSessionProvider).audioRoute,
      fallbackSpeakerOn: preference,
    );
    if (!CallAudioRoute.canToggleSpeaker(kind)) return;
    final on = !preference;
    _liveUi.setSpeakerOn(on);
    await _agoraService.setSpeakerphoneEnabled(on);
  }

  Future<void> _toggleCamera() async {
    final on = !ref.read(isCameraOnProvider);
    _liveUi.setCameraOn(on);
    await _agoraService.toggleVideo(on);
  }

  Future<void> _flipCamera() async {
    if (!ref.read(isCameraOnProvider) || !_agoraJoined) return;
    try {
      await _agoraService.switchCamera();
    } catch (e) {
      AppLogger.warning('Camera flip failed', tag: 'outgoing_call_page', error: e);
    }
  }

  @override
  void dispose() {
    final keep = ActiveCallLifecycle.keepEngine(
      callEnded: _leaving,
      minimized: _preservingEngine,
    );
    if (keep) {
      _cancelRingingTimers();
      _remoteLeftTimer?.cancel();
      _cancelReconnectWatchdog();
      unawaited(_connectivitySub?.cancel());
      WidgetsBinding.instance.removeObserver(this);
      _durationTimer?.cancel();
      super.dispose();
      return;
    }
    final shouldEnd = !_leaving && !_endPosted && _callId > 0;
    final callId = _callId;
    final wasConnected = _sessionConnected();
    dynamic endNotifier;
    if (shouldEnd) {
      try {
        endNotifier = ref.read(callProvider.notifier);
        ref.read(messengerCallsProvider.notifier).applyRemoteStatus(
              callId: callId,
              status: wasConnected ? 'ended' : 'missed',
            );
      } catch (e) {
        AppLogger.warning(
          'dispose applyRemoteStatus failed',
          tag: 'outgoing_call_page',
          error: e,
        );
      }
    }
    _leaving = true;
    _cancelRingingTimers();
    _remoteLeftTimer?.cancel();
    _cancelReconnectWatchdog();
    unawaited(_connectivitySub?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    _durationTimer?.cancel();
    _agoraService.clearSessionCallbacks(keepTokenRefresh: true);
    _qualityMonitor.stopMonitoring(callSuccessful: false, failureReason: 'disposed');
    unawaited(_wakeLock.disable(force: true));
    if (callId > 0) {
      _signaling.disposeCall(callId);
    }
    unawaited(_agoraService.dispose());
    unawaited(SoundService.instance.stopCallSounds());
    if (endNotifier != null) {
      unawaited(_postEndIfNeeded(notifier: endNotifier));
    }
    try {
      ref.read(liveCallUiProvider.notifier).reset();
      ref.read(agoraRtcSessionProvider.notifier).reset();
      ref.read(callEndSummaryProvider.notifier).state = null;
    } catch (e) {
      AppLogger.warning(
        'dispose live-call reset failed',
        tag: 'outgoing_call_page',
        error: e,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(callStatusProvider);
    final isVideo = widget.type == OutgoingCallType.video;
    final engine = _agoraService.engine;
    final showVideoLayer =
        isVideo && _agoraJoined && engine != null && _channelName != null;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final showRingChrome = !_leaving &&
        _connectionError == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_sessionConnected() && !_leaving) {
          _minimizeCall();
          return;
        }
        unawaited(_endCall());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CallHudHost(
          autoHide: CallHudPolicy.autoHide(
            isVideo: isVideo,
            connected: connected && !_leaving,
          ),
          child: CallConnectHost(
            connected: connected && !_leaving,
            child: Builder(
              builder: (context) {
              void revealHud() {
                CallHudController.maybeOf(context)?.reveal();
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  CallConnectStage(
                    child: showVideoLayer
                        ? RepaintBoundary(
                            child: CallLiveVideoStage(
                              engine: engine,
                              channelId: _channelName!,
                              localAvatarUrl: _localAvatarUrl,
                              remoteAvatarUrl: _headerPhotoUrl,
                              localUserId: _localUserId,
                              remoteUserId: widget.recipientId,
                              onFlipCamera: () {
                                unawaited(_flipCamera());
                              },
                              onStageTap: revealHud,
                            ),
                          )
                        : Consumer(
                            builder: (context, ref, _) {
                              final failed = ref.watch(
                                agoraRtcSessionProvider.select(
                                  (state) => state.localCameraFailed,
                                ),
                              );
                              final caption = ref.watch(
                                agoraRtcSessionProvider.select(
                                  (state) => state.localCameraCaption,
                                ),
                              );
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: revealHud,
                                child: CallStagePlaceholder(
                                  userId: widget.recipientId,
                                  imageUrl: _displayBackdropUrl,
                                  caption: failed ? caption : 'Camera is off',
                                ),
                              );
                            },
                          ),
                  ),
                  if (showRingChrome)
                    IgnorePointer(
                      child: Center(
                        child: CallConnectPulse(
                          child: CallOutgoingPulseAvatar(
                            active: !connected,
                            userId: widget.recipientId,
                            imageUrl: _headerPhotoUrl,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: topPad + AppSpacing.spacingMD,
                    left: AppBreakpoints.value(
                      context,
                      phone: AppSpacing.spacingLG,
                      tablet: AppSpacing.spacingXL,
                    ),
                    right: AppSpacing.spacingLG,
                    child: CallHudFade(
                      child: OutgoingCallHeader(
                        recipientName: widget.recipientName,
                        recipientId: widget.recipientId,
                        photoUrl: _headerPhotoUrl,
                        statusLabel: _statusLabel,
                        connectionError: _connectionError,
                      ),
                    ),
                  ),
                  Positioned(
                    top: topPad +
                        AppSpacing.spacingXXXL +
                        AppSpacing.spacingXL,
                    left: 0,
                    right: 0,
                    child: CallHudFade(
                      child: const CallQualityToast(),
                    ),
                  ),
                  CallReconnectLayer(leaving: _leaving),
                  Positioned(
                    left: AppSpacing.spacingSM,
                    right: AppSpacing.spacingSM,
                    bottom: bottomPad + AppSpacing.spacingSM,
                    child: CallHudFade(
                      child: _buildControlSheet(),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      return CallEndOverlay(
                        summary: ref.watch(callEndSummaryProvider),
                        onFinished: _leaveCallUi,
                      );
                    },
                  ),
                ],
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlSheet() {
    final isVideo = widget.type == OutgoingCallType.video;
    const circle = 56.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.spacingLG,
            AppSpacing.spacingSM,
            AppSpacing.spacingLG,
            AppSpacing.spacingLG,
          ),
          color: AppColors.backgroundDark.withValues(alpha: 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimaryDark.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppSpacing.spacingLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CallMuteButton(onTap: _toggleMute, size: circle),
                  if (isVideo)
                    CallFlipButton(onTap: _flipCamera, size: circle),
                  CallEndButton(onTap: _endCall, size: circle),
                ],
              ),
              SizedBox(height: AppSpacing.spacingMD),
              Row(
                children: [
                  if (_sessionConnected()) ...[
                    Expanded(
                      child: CallHideButton(onTap: _minimizeCall),
                    ),
                    SizedBox(width: AppSpacing.spacingSM),
                  ],
                  if (isVideo) ...[
                    Expanded(
                      child: CallCameraPill(onTap: _toggleCamera),
                    ),
                    SizedBox(width: AppSpacing.spacingSM),
                  ],
                  Expanded(
                    child: CallSpeakerPill(onTap: _toggleSpeaker),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
