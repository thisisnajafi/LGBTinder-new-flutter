import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/config/agora_config.dart';
import '../../core/services/app_logger.dart';
import 'agora_rtc_types.dart';
import 'call_permissions.dart';
import 'call_token_refresh.dart';

typedef AgoraTokenRefreshCallback = Future<CallTokenRefreshResult> Function();
typedef AgoraRemoteUserCallback = void Function(int uid);
typedef AgoraNetworkQualityCallback = void Function(int uid, String quality);
typedef AgoraRtcUiConnectionCallback = void Function(CallRtcConnectionUi state);
typedef AgoraRemoteOfflineCallback = void Function(
  int uid,
  CallRemoteLeaveReason reason,
);
typedef AgoraRtcStatsCallback = void Function({
  required int bitrateKbps,
  required int packetLossPercent,
});
typedef AgoraSpeakingCallback = void Function({
  int? remoteUid,
  required bool localSpeaking,
});
typedef AgoraLocalCameraCallback = void Function(bool failed, String? message);
typedef AgoraRemoteVideoUiCallback = void Function({
  required bool stopped,
  required bool frozen,
});
typedef AgoraFirstRemoteVideoCallback = void Function(
  int uid,
  int width,
  int height,
);

/// Agora WebRTC service for video/voice calling.
///
/// Native RTC stays on the **main isolate** (Agora JNI). Callbacks hop onto
/// the UI via [_emitUi] so setState / Riverpod writes never run mid-frame
/// (PERF-ANDROID-005). Do not move this service into `compute()`.
class AgoraService {
  static const _tag = 'Agora';

  RtcEngine? _engine;
  RtcEngineEventHandler? _eventHandler;
  bool _isInitialized = false;
  String? _initializedAppId;

  bool _isInCall = false;
  String? _currentChannelId;
  int? _currentUserId;
  int? _remoteUid;
  bool _isVideoCall = false;
  int _lastTxKbps = 0;
  int _lastRxKbps = 0;
  int _lastPacketLoss = 0;
  bool _hasRtcStats = false;
  Completer<void>? _teardownCompleter;
  int? _lastLoggedSpeakingUid;
  bool? _lastLoggedLocalSpeaking;
  Timer? _tokenRefreshTimer;
  Future<void>? _tokenRefreshInFlight;
  bool _tokenRefreshFailed = false;
  bool _tokenRefreshFailureShown = false;

  /// Kept for unused [VideoCallScreen] / [VoiceCallScreen] compile compatibility.
  Function(bool isConnected)? onConnectionStateChanged;
  AgoraRemoteUserCallback? onRemoteUserJoined;
  AgoraRemoteUserCallback? onRemoteUserLeft;
  AgoraRemoteOfflineCallback? onRemoteUserOffline;
  void Function(int uid, bool muted)? onRemoteVideoMuted;
  Function(String message)? onError;
  AgoraNetworkQualityCallback? onNetworkQuality;
  AgoraTokenRefreshCallback? onTokenRefreshRequired;
  AgoraRtcUiConnectionCallback? onRtcUiConnectionChanged;
  AgoraRtcStatsCallback? onRtcStatsUpdate;
  AgoraSpeakingCallback? onSpeakingChanged;
  AgoraLocalCameraCallback? onLocalCameraFailed;
  AgoraRemoteVideoUiCallback? onRemoteVideoUiChanged;
  AgoraFirstRemoteVideoCallback? onFirstRemoteVideoFrame;
  /// Agora [onAudioRoutingChanged] (CALL-NATIVE-003). Integer is [AudioRoute].
  void Function(int routing)? onAudioRouteChanged;
  void Function(String message)? onWarning;

  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  /// Initialize Agora RTC Engine. [appId] should come from the token endpoint.
  Future<void> initialize({bool isVideoCall = false, String? appId}) async {
    await _awaitTeardown();
    final resolvedAppId = AgoraConfig.resolveAppId(appId);
    if (resolvedAppId.isEmpty) {
      AppLogger.error('Agora app_id missing', tag: _tag);
      onError?.call('Could not start the call');
      throw StateError('Agora app_id missing');
    }

    if (_isInitialized &&
        _initializedAppId == resolvedAppId &&
        _engine != null) {
      AppLogger.info('Engine already ready for this session', tag: _tag);
      return;
    }
    if (_engine != null) {
      await dispose();
    }

    try {
      await _requestPermissions(isVideoCall: isVideoCall);

      AppLogger.info('Creating engine', tag: _tag);
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: resolvedAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine!.enableAudio();
      await _engine!.setAudioScenario(
        AudioScenarioType.audioScenarioDefault,
      );

      _eventHandler = _buildEventHandler();
      _engine!.registerEventHandler(_eventHandler!);

      _isInitialized = true;
      _initializedAppId = resolvedAppId;
      AppLogger.info('Engine initialized', tag: _tag);
    } catch (e, st) {
      AppLogger.error(
        'Failed to initialize engine',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      await _abandonFailedEngine();
      onError?.call('Could not start the call');
      rethrow;
    }
  }

  /// Agora RTC 6.3.2 has no `onWarning`. Warnings are logged from
  /// connection-lost, failed connection, token expiry, and local camera failure.
  RtcEngineEventHandler _buildEventHandler() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _emitUi(() {
          AppLogger.info(
            'onJoinChannelSuccess channel=${connection.channelId} uid=${connection.localUid} elapsed=$elapsed',
            tag: _tag,
          );
          _isInCall = true;
          _currentChannelId ??= connection.channelId;
          onConnectionStateChanged?.call(true);
          onRtcUiConnectionChanged?.call(CallRtcConnectionUi.connected);
        });
      },
      onRejoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _emitUi(() {
          AppLogger.info(
            'onRejoinChannelSuccess channel=${connection.channelId} elapsed=$elapsed',
            tag: _tag,
          );
          _isInCall = true;
          onConnectionStateChanged?.call(true);
          onRtcUiConnectionChanged?.call(CallRtcConnectionUi.connected);
        });
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        _emitUi(() {
          AppLogger.info(
            'onLeaveChannel duration=${stats.duration} tx=${stats.txKBitRate} rx=${stats.rxKBitRate}',
            tag: _tag,
          );
          _isInCall = false;
          _remoteUid = null;
          onConnectionStateChanged?.call(false);
          onRtcUiConnectionChanged?.call(CallRtcConnectionUi.disconnected);
        });
      },
      onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        _emitUi(() {
          AppLogger.info('onUserJoined uid=$uid elapsed=$elapsed', tag: _tag);
          _remoteUid = uid;
          onRemoteUserJoined?.call(uid);
        });
      },
      onUserOffline: (
        RtcConnection connection,
        int uid,
        UserOfflineReasonType reason,
      ) {
        _emitUi(() {
          final mapped = AgoraErrorMessages.fromOfflineReason(reason);
          AppLogger.info(
            'onUserOffline uid=$uid reason=$reason mapped=$mapped',
            tag: _tag,
          );
          if (_remoteUid == uid) {
            _remoteUid = null;
          }
          onRemoteUserLeft?.call(uid);
          onRemoteUserOffline?.call(uid, mapped);
        });
      },
      onUserMuteVideo: (RtcConnection connection, int uid, bool muted) {
        _emitUi(() {
          AppLogger.info('onUserMuteVideo uid=$uid muted=$muted', tag: _tag);
          onRemoteVideoMuted?.call(uid, muted);
        });
      },
      onUserMuteAudio: (RtcConnection connection, int uid, bool muted) {
        _emitUi(() {
          AppLogger.info('onUserMuteAudio uid=$uid muted=$muted', tag: _tag);
        });
      },
      onError: (ErrorCodeType err, String msg) {
        _emitUi(() {
          AppLogger.error(
            'onError code=$err msg=$msg',
            tag: _tag,
            error: msg,
          );
          final tokenError = err == ErrorCodeType.errInvalidToken ||
              err == ErrorCodeType.errTokenExpired;
          if (_tokenRefreshFailed && tokenError) {
            _notifyTokenFailureOnce();
            return;
          }
          onError?.call(AgoraErrorMessages.fromErrorCode(err));
        });
      },
      onNetworkQuality: (
        RtcConnection connection,
        int remoteUid,
        QualityType txQuality,
        QualityType rxQuality,
      ) {
        _emitUi(() {
          final label = AgoraNetworkQuality.fromType(rxQuality);
          AppLogger.verbose(
            'onNetworkQuality uid=$remoteUid tx=$txQuality rx=$rxQuality label=$label',
            tag: _tag,
          );
          onNetworkQuality?.call(remoteUid, label);
        });
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        AppLogger.warning(
          'onTokenPrivilegeWillExpire channel=${connection.channelId}',
          tag: _tag,
        );
        unawaited(_refreshToken());
      },
      onRequestToken: (RtcConnection connection) {
        AppLogger.warning(
          'onRequestToken channel=${connection.channelId}',
          tag: _tag,
        );
        unawaited(_refreshToken());
      },
      onConnectionLost: (RtcConnection connection) {
        _emitUi(() {
          AppLogger.warning(
            'onConnectionLost channel=${connection.channelId}',
            tag: _tag,
          );
          onWarning?.call('Connection lost');
          onRtcUiConnectionChanged?.call(CallRtcConnectionUi.reconnecting);
        });
      },
      onConnectionStateChanged: (
        RtcConnection connection,
        ConnectionStateType state,
        ConnectionChangedReasonType reason,
      ) {
        _emitUi(() {
          final ui = AgoraErrorMessages.fromConnectionState(state);
          AppLogger.info(
            'onConnectionStateChanged state=$state reason=$reason ui=$ui',
            tag: _tag,
          );
          if (state == ConnectionStateType.connectionStateReconnecting ||
              state == ConnectionStateType.connectionStateFailed) {
            AppLogger.warning(
              'Agora connection $state ($reason)',
              tag: _tag,
            );
          }
          onRtcUiConnectionChanged?.call(ui);
          if (ui == CallRtcConnectionUi.connected) {
            onConnectionStateChanged?.call(true);
          } else if (ui == CallRtcConnectionUi.disconnected ||
              ui == CallRtcConnectionUi.failed) {
            onConnectionStateChanged?.call(false);
          }
          if (ui == CallRtcConnectionUi.failed) {
            if (_tokenRefreshFailed) {
              _notifyTokenFailureOnce();
            } else {
              onError?.call('Connection failed');
            }
          }
        });
      },
      onRemoteVideoStateChanged: (
        RtcConnection connection,
        int remoteUid,
        RemoteVideoState state,
        RemoteVideoStateReason reason,
        int elapsed,
      ) {
        _emitUi(() {
          AppLogger.info(
            'onRemoteVideoStateChanged uid=$remoteUid state=$state reason=$reason',
            tag: _tag,
          );
          final stopped = state == RemoteVideoState.remoteVideoStateStopped ||
              state == RemoteVideoState.remoteVideoStateFailed;
          final frozen = state == RemoteVideoState.remoteVideoStateFrozen;
          onRemoteVideoUiChanged?.call(stopped: stopped, frozen: frozen);
        });
      },
      onLocalVideoStateChanged: (
        VideoSourceType source,
        LocalVideoStreamState state,
        LocalVideoStreamReason reason,
      ) {
        _emitUi(() {
          AppLogger.info(
            'onLocalVideoStateChanged source=$source state=$state reason=$reason',
            tag: _tag,
          );
          if (state == LocalVideoStreamState.localVideoStreamStateFailed) {
            AppLogger.warning(
              'Local camera failed: $reason',
              tag: _tag,
            );
            onLocalCameraFailed?.call(
              true,
              AgoraErrorMessages.fromLocalVideoReason(reason),
            );
            onWarning?.call(AgoraErrorMessages.fromLocalVideoReason(reason));
          } else if (state ==
                  LocalVideoStreamState.localVideoStreamStateCapturing ||
              state == LocalVideoStreamState.localVideoStreamStateEncoding) {
            onLocalCameraFailed?.call(false, null);
          }
        });
      },
      onRtcStats: (RtcConnection connection, RtcStats stats) {
        _emitUi(() {
          final tx = stats.txKBitRate ?? 0;
          final rx = stats.rxKBitRate ?? 0;
          final loss = _maxLoss(stats.txPacketLossRate, stats.rxPacketLossRate);
          _lastTxKbps = tx;
          _lastRxKbps = rx;
          _lastPacketLoss = loss;
          _hasRtcStats = true;
          AppLogger.verbose(
            'onRtcStats tx=$tx rx=$rx loss=$loss duration=${stats.duration}',
            tag: _tag,
          );
          onRtcStatsUpdate?.call(
            bitrateKbps: tx + rx,
            packetLossPercent: loss,
          );
        });
      },
      onFirstRemoteVideoFrame: (
        RtcConnection connection,
        int remoteUid,
        int width,
        int height,
        int elapsed,
      ) {
        _emitUi(() {
          AppLogger.info(
            'onFirstRemoteVideoFrame uid=$remoteUid ${width}x$height elapsed=$elapsed',
            tag: _tag,
          );
          onFirstRemoteVideoFrame?.call(remoteUid, width, height);
        });
      },
      onAudioVolumeIndication: (
        RtcConnection connection,
        List<AudioVolumeInfo> speakers,
        int speakerNumber,
        int totalVolume,
      ) {
        _emitUi(() {
          int? speakingUid;
          var maxRemote = AgoraSpeaking.volumeThreshold;
          var localSpeaking = false;
          for (final speaker in speakers) {
            final uid = speaker.uid ?? 0;
            final volume = speaker.volume ?? 0;
            if (uid == 0) {
              localSpeaking = AgoraSpeaking.isActive(
                volume: volume,
                vad: speaker.vad ?? 0,
              );
            } else if (volume > maxRemote) {
              maxRemote = volume;
              speakingUid = uid;
            }
          }
          if (speakingUid != _lastLoggedSpeakingUid ||
              localSpeaking != _lastLoggedLocalSpeaking) {
            _lastLoggedSpeakingUid = speakingUid;
            _lastLoggedLocalSpeaking = localSpeaking;
            AppLogger.verbose(
              'onAudioVolumeIndication localSpeaking=$localSpeaking remoteUid=$speakingUid speakers=$speakerNumber total=$totalVolume',
              tag: _tag,
            );
          }
          onSpeakingChanged?.call(
            remoteUid: speakingUid,
            localSpeaking: localSpeaking,
          );
        });
      },
      onAudioRoutingChanged: (int routing) {
        _emitUi(() {
          AppLogger.info('onAudioRoutingChanged routing=$routing', tag: _tag);
          onAudioRouteChanged?.call(routing);
        });
      },
    );
  }

  int _maxLoss(int? tx, int? rx) {
    final a = tx ?? 0;
    final b = rx ?? 0;
    return a > b ? a : b;
  }

  /// Run [action] on the UI frame boundary. Agora JNI can fire while Flutter
  /// is painting; mutating providers mid-frame janks and risks ANR traces.
  void _emitUi(void Function() action) {
    final binding = WidgetsBinding.instance;
    final phase = binding.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      action();
      return;
    }
    binding.addPostFrameCallback((_) => action());
  }

  Future<void> _refreshToken() async {
    final existing = _tokenRefreshInFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final future = _refreshTokenBody();
    _tokenRefreshInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_tokenRefreshInFlight, future)) {
        _tokenRefreshInFlight = null;
      }
    }
  }

  Future<void> _refreshTokenBody() async {
    if (_teardownInFlight || _engine == null) return;
    final refresh = onTokenRefreshRequired;
    if (refresh == null) {
      AppLogger.warning('Token refresh skipped: no callback', tag: _tag);
      return;
    }

    try {
      final result = await refresh();
      if (_teardownInFlight || _engine == null) return;
      if (!result.hasToken) {
        _tokenRefreshFailed = true;
        AppLogger.warning('Token refresh returned empty', tag: _tag);
        return;
      }
      await _engine!.renewToken(result.token);
      _tokenRefreshFailed = false;
      AppLogger.info('Token renewed', tag: _tag);
      final expiresAt = result.expiresAt;
      if (expiresAt != null) {
        scheduleProactiveTokenRefresh(expiresAt);
      }
    } catch (e, st) {
      _tokenRefreshFailed = true;
      AppLogger.error(
        'Token refresh failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _notifyTokenFailureOnce() {
    if (_tokenRefreshFailureShown) return;
    _tokenRefreshFailureShown = true;
    onError?.call('Call session expired');
  }

  /// Refresh 5 minutes before [expiresAt]. Cancels any previous schedule.
  void scheduleProactiveTokenRefresh(DateTime expiresAt) {
    _tokenRefreshTimer?.cancel();
    if (_teardownInFlight || _engine == null) return;
    final delay = CallTokenRefresh.delayUntilRefresh(expiresAt, DateTime.now());
    AppLogger.info(
      'Token refresh scheduled in ${delay.inSeconds}s',
      tag: _tag,
    );
    _tokenRefreshTimer = Timer(delay, () {
      unawaited(_refreshToken());
    });
  }

  void _cancelTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  Future<void> _requestPermissions({required bool isVideoCall}) async {
    final result = await CallPermissions.ensure(video: isVideoCall);
    if (result != CallPermissionResult.granted) {
      throw CallPermissionDeniedException(result, video: isVideoCall);
    }
  }

  /// Leave the current channel (without releasing the engine) and join again.
  Future<void> rejoinChannel({
    required String channelId,
    required String token,
    required int userId,
    bool isVideoCall = false,
  }) async {
    await _awaitTeardown();
    if (!_isInitialized || _engine == null || _teardownInFlight) {
      throw Exception('Agora engine not initialized');
    }
    AppLogger.info('Rejoin start channel=$channelId uid=$userId', tag: _tag);
    try {
      await _engine!.leaveChannel();
    } catch (e) {
      AppLogger.warning('rejoin leaveChannel failed', tag: _tag, error: e);
    }
    _isInCall = false;
    await joinChannel(
      channelId: channelId,
      token: token,
      userId: userId,
      isVideoCall: isVideoCall,
    );
  }

  /// Re-apply mute / speaker / camera after Agora auto-rejoin or explicit rejoin.
  Future<void> restoreLocalMedia({
    required bool muted,
    required bool speakerOn,
    required bool cameraOn,
    required bool isVideoCall,
  }) async {
    if (!_isInitialized || _engine == null || _teardownInFlight) return;
    AppLogger.info(
      'Restore media muted=$muted speaker=$speakerOn camera=$cameraOn video=$isVideoCall',
      tag: _tag,
    );
    await toggleAudio(!muted);
    await setSpeakerphoneEnabled(speakerOn);
    if (isVideoCall) {
      await toggleVideo(cameraOn);
    }
  }

  /// Join a call channel.
  Future<void> joinChannel({
    required String channelId,
    required String token,
    required int userId,
    bool isVideoCall = false,
  }) async {
    await _awaitTeardown();
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora engine not initialized');
    }

    try {
      if (_isInCall &&
          _currentChannelId == channelId &&
          _engine != null) {
        AppLogger.info(
          'Already in channel $channelId, skip join',
          tag: _tag,
        );
        return;
      }

      _currentChannelId = channelId;
      _currentUserId = userId;
      _isVideoCall = isVideoCall;

      await _engine!.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _configureJoinAudioRoute(isVideoCall: isVideoCall);

      if (isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: userId,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideoCall,
        ),
      );

      await _setSpeakerphoneAfterJoin(isVideoCall: isVideoCall);

      try {
        await _engine!.enableAudioVolumeIndication(
          interval: 200,
          smooth: 3,
          reportVad: true,
        );
      } catch (e) {
        AppLogger.warning(
          'enableAudioVolumeIndication failed',
          tag: _tag,
          error: e,
        );
      }
      AppLogger.info('Joined channel $channelId uid=$userId', tag: _tag);
    } catch (e, st) {
      AppLogger.error(
        'Failed to join channel',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      onError?.call('Could not join the call');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    await _leaveAndStopMedia();
  }

  Future<void> _leaveAndStopMedia() async {
    final engine = _engine;
    if (engine == null) return;

    try {
      AppLogger.info('leaveChannel', tag: _tag);
      await engine.leaveChannel();
    } catch (e) {
      AppLogger.warning('leaveChannel failed', tag: _tag, error: e);
    }
    await restoreMediaAudioSession();
    try {
      AppLogger.info('stopPreview', tag: _tag);
      await engine.stopPreview();
    } catch (e) {
      AppLogger.warning('stopPreview failed', tag: _tag, error: e);
    }
    try {
      AppLogger.info('disableVideo', tag: _tag);
      await engine.disableVideo();
    } catch (e) {
      AppLogger.warning('disableVideo failed', tag: _tag, error: e);
    }

    _resetCallFlags();
    AppLogger.info('Media stopped', tag: _tag);
  }

  void _resetCallFlags() {
    _currentChannelId = null;
    _currentUserId = null;
    _remoteUid = null;
    _isInCall = false;
    _lastTxKbps = 0;
    _lastRxKbps = 0;
    _lastPacketLoss = 0;
    _hasRtcStats = false;
    _lastLoggedSpeakingUid = null;
    _lastLoggedLocalSpeaking = null;
  }

  Future<void> _awaitTeardown() async {
    final pending = _teardownCompleter;
    if (pending != null && !pending.isCompleted) {
      AppLogger.info('Waiting for engine teardown', tag: _tag);
      await pending.future;
    }
  }

  bool get _teardownInFlight =>
      _teardownCompleter != null && !_teardownCompleter!.isCompleted;

  Future<void> _abandonFailedEngine() async {
    _cancelTokenRefreshTimer();
    final engine = _engine;
    _engine = null;
    _eventHandler = null;
    _isInitialized = false;
    _initializedAppId = null;
    _resetCallFlags();
    if (engine == null) return;
    try {
      await engine.release();
    } catch (e) {
      AppLogger.warning('release after failed init', tag: _tag, error: e);
    }
  }

  Future<void> toggleVideo(bool enabled) async {
    if (!_isInitialized || _engine == null || _teardownInFlight) return;

    try {
      // Mute the local camera only. disableVideo() would also stop remote video.
      await _engine!.enableLocalVideo(enabled);
      await _engine!.muteLocalVideoStream(!enabled);
      if (enabled) {
        await _engine!.startPreview();
      } else {
        await _engine!.stopPreview();
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to toggle video',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      onError?.call('Could not change camera');
    }
  }

  Future<void> _configureJoinAudioRoute({required bool isVideoCall}) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setDefaultAudioRouteToSpeakerphone(isVideoCall);
    } catch (e) {
      AppLogger.warning(
        'setDefaultAudioRouteToSpeakerphone failed',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<void> _setSpeakerphoneAfterJoin({required bool isVideoCall}) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setEnableSpeakerphone(isVideoCall);
    } catch (e) {
      AppLogger.warning(
        'setEnableSpeakerphone after join failed',
        tag: _tag,
        error: e,
      );
    }
  }

  /// Return playback to the OS session so in-app media is not stuck on speaker.
  Future<void> restoreMediaAudioSession() async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setEnableSpeakerphone(false);
    } catch (e) {
      AppLogger.warning(
        'restore setEnableSpeakerphone failed',
        tag: _tag,
        error: e,
      );
    }
    try {
      await engine.setDefaultAudioRouteToSpeakerphone(false);
    } catch (e) {
      AppLogger.warning(
        'restore setDefaultAudioRouteToSpeakerphone failed',
        tag: _tag,
        error: e,
      );
    }
    try {
      await engine.setAudioScenario(AudioScenarioType.audioScenarioDefault);
    } catch (e) {
      AppLogger.warning(
        'restore setAudioScenario failed',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<void> toggleAudio(bool enabled) async {
    if (!_isInitialized || _engine == null || _teardownInFlight) return;

    try {
      await _engine!.muteLocalAudioStream(!enabled);
    } catch (e, st) {
      AppLogger.error(
        'Failed to toggle audio',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      onError?.call('Could not change microphone');
    }
  }

  Future<void> switchCamera() async {
    if (!_isInitialized || _engine == null || _teardownInFlight) return;
    await _engine!.switchCamera();
  }

  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (!_isInitialized || _engine == null || _teardownInFlight) return;

    try {
      await _engine!.setEnableSpeakerphone(enabled);
    } catch (e, st) {
      AppLogger.error(
        'Failed to set speakerphone',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      onError?.call('Could not change speaker');
    }
  }

  Future<Map<String, dynamic>> getCallStats() async {
    if (!_isInitialized || _engine == null) {
      return {};
    }

    return {
      'isInCall': _isInCall,
      'channelId': _currentChannelId,
      'userId': _currentUserId,
      'remoteUid': _remoteUid,
      if (_hasRtcStats) 'bitrate': _lastTxKbps + _lastRxKbps,
      if (_hasRtcStats) 'packetLoss': _lastPacketLoss,
      if (_hasRtcStats) 'txBitrate': _lastTxKbps,
      if (_hasRtcStats) 'rxBitrate': _lastRxKbps,
    };
  }

  void clearSessionCallbacks({bool keepTokenRefresh = false}) {
    onConnectionStateChanged = null;
    onRemoteUserJoined = null;
    onRemoteUserLeft = null;
    onRemoteUserOffline = null;
    onRemoteVideoMuted = null;
    onError = null;
    onNetworkQuality = null;
    if (!keepTokenRefresh) {
      onTokenRefreshRequired = null;
    }
    onRtcUiConnectionChanged = null;
    onRtcStatsUpdate = null;
    onSpeakingChanged = null;
    onLocalCameraFailed = null;
    onRemoteVideoUiChanged = null;
    onFirstRemoteVideoFrame = null;
    onAudioRouteChanged = null;
    onWarning = null;
  }

  /// Leave, stop preview, disable video, then release. Safe to call twice.
  Future<void> dispose() async {
    if (_teardownCompleter != null) {
      return _teardownCompleter!.future;
    }
    if (_engine == null && !_isInitialized) {
      _cancelTokenRefreshTimer();
      clearSessionCallbacks();
      return;
    }

    final done = Completer<void>();
    _teardownCompleter = done;
    AppLogger.info('Teardown start', tag: _tag);
    try {
      _cancelTokenRefreshTimer();
      clearSessionCallbacks(keepTokenRefresh: true);
      await _leaveAndStopMedia();
      onTokenRefreshRequired = null;
      _tokenRefreshFailed = false;
      _tokenRefreshFailureShown = false;

      final engine = _engine;
      final handler = _eventHandler;
      if (engine != null && handler != null) {
        try {
          AppLogger.info('unregisterEventHandler', tag: _tag);
          engine.unregisterEventHandler(handler);
        } catch (e) {
          AppLogger.warning(
            'unregisterEventHandler failed',
            tag: _tag,
            error: e,
          );
        }
      }
      _eventHandler = null;

      if (engine != null) {
        try {
          AppLogger.info('release', tag: _tag);
          await engine.release();
        } catch (e) {
          AppLogger.warning('release failed', tag: _tag, error: e);
        }
      }
      _engine = null;
      _isInitialized = false;
      _initializedAppId = null;
      _resetCallFlags();
      AppLogger.info('Teardown complete', tag: _tag);
    } finally {
      done.complete();
      if (identical(_teardownCompleter, done)) {
        _teardownCompleter = null;
      }
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isInCall => _isInCall;
  String? get currentChannelId => _currentChannelId;
  int? get currentUserId => _currentUserId;
  int? get remoteUid => _remoteUid;
  bool get isVideoCall => _isVideoCall;
  RtcEngine? get engine => _engine;
}
