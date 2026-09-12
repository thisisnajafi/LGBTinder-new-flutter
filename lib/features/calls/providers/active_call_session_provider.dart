import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../../../shared/services/agora_rtc_types.dart';
import '../../../shared/services/agora_service.dart';
import '../../../shared/services/call_token_refresh.dart';
import '../../../shared/services/push_notification_service.dart';
import '../data/models/active_call_session.dart';
import '../data/models/call_action_request.dart';
import '../data/models/call_wake_lock.dart';
import '../data/services/call_kit_service.dart';
import '../data/services/call_signaling_service.dart';
import '../utils/call_audio_route.dart';
import 'agora_rtc_session_provider.dart';
import 'call_provider.dart';
import 'live_call_ui_provider.dart';
import 'messenger_calls_provider.dart';

final activeCallSessionProvider =
    StateNotifierProvider<ActiveCallSessionNotifier, ActiveCallSession?>((ref) {
  return ActiveCallSessionNotifier(ref);
});

/// Owns a live Agora session after [OutgoingCallPage] is popped (CALL-NATIVE-004).
class ActiveCallSessionNotifier extends StateNotifier<ActiveCallSession?> {
  ActiveCallSessionNotifier(this._ref) : super(null);

  static const _tag = 'active_call_session';

  final Ref _ref;
  Timer? _tick;
  Timer? _remoteLeft;

  void attach(ActiveCallSession session) {
    final keepMinimized =
        state?.minimized == true && state?.callId == session.callId;
    state = session.copyWith(minimized: keepMinimized);
  }

  void minimize(ActiveCallSession session) {
    state = session.copyWith(minimized: true, agoraJoined: true);
    _bindEngineWhileMinimized();
    _listenSignaling();
    _startTick();
    unawaited(PushNotificationService().showActiveCall(state!));
    AppLogger.info(
      'Call minimized callId=${session.callId}',
      tag: _tag,
    );
  }

  void reveal() {
    if (state == null) return;
    state = state!.copyWith(minimized: false);
    _tick?.cancel();
    _tick = null;
    _remoteLeft?.cancel();
    _remoteLeft = null;
    unawaited(PushNotificationService().hideActiveCall());
  }

  void clearUiOnly() {
    _tick?.cancel();
    _tick = null;
    _remoteLeft?.cancel();
    _remoteLeft = null;
    state = null;
    unawaited(PushNotificationService().hideActiveCall());
  }

  Future<void> hangUpFromSystem({
    int? callIdOverride,
    bool postEnd = true,
  }) async {
    final session = state;
    final callId = callIdOverride ?? session?.callId ?? 0;
    final wasConnected = _ref.read(liveCallUiProvider).connected;
    clearUiOnly();

    try {
      await AgoraService().dispose();
    } catch (e) {
      AppLogger.warning('Agora dispose from notification failed', tag: _tag, error: e);
    }

    unawaited(CallWakeLock().disable(force: true));

    if (callId > 0) {
      try {
        _ref.read(callSignalingServiceProvider).disposeCall(callId);
      } catch (e) {
        AppLogger.warning(
          'disposeCall from notification failed',
          tag: _tag,
          error: e,
        );
      }
      if (postEnd) {
        try {
          await _ref.read(callProvider.notifier).endCall(
                CallActionRequest.end(callId.toString()),
              );
        } catch (e) {
          AppLogger.warning('endCall from notification failed', tag: _tag, error: e);
        }
      }
      try {
        _ref.read(messengerCallsProvider.notifier).applyRemoteStatus(
              callId: callId,
              status: wasConnected ? 'ended' : 'missed',
            );
      } catch (e) {
        AppLogger.warning(
          'applyRemoteStatus from notification failed',
          tag: _tag,
          error: e,
        );
      }
      unawaited(CallKitService.instance.endCall(callId.toString()));
    }

    try {
      _ref.read(liveCallUiProvider.notifier).reset();
      _ref.read(agoraRtcSessionProvider.notifier).reset();
    } catch (e) {
      AppLogger.warning(
        'live-call reset from notification failed',
        tag: _tag,
        error: e,
      );
    }

    AppLogger.info('Call ended from notification callId=$callId', tag: _tag);
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      _ref.read(liveCallUiProvider.notifier).tick();
    });
  }

  void _listenSignaling() {
    final callId = state?.callId ?? 0;
    if (callId <= 0) return;
    _ref.read(callSignalingServiceProvider).listen(
          callId: callId,
          onRejected: (_) => unawaited(_onRemoteEnded()),
          onEnded: (_) => unawaited(_onRemoteEnded()),
          onBusy: (_) => unawaited(_onRemoteEnded()),
        );
  }

  Future<void> _onRemoteEnded() async {
    if (state == null) return;
    await hangUpFromSystem(postEnd: false);
  }

  void _bindEngineWhileMinimized() {
    final agora = AgoraService();
    final rtc = _ref.read(agoraRtcSessionProvider.notifier);

    agora.onRemoteUserJoined = (uid) {
      _remoteLeft?.cancel();
      _remoteLeft = null;
      rtc.remoteUserJoined(uid);
    };
    agora.onRemoteUserLeft = (_) {};
    agora.onRemoteUserOffline = (uid, reason) {
      rtc.remoteUserLeft(uid, reason);
      if (reason == CallRemoteLeaveReason.quit) {
        unawaited(_onRemoteEnded());
        return;
      }
      if (reason == CallRemoteLeaveReason.dropped) {
        _remoteLeft?.cancel();
        _remoteLeft = Timer(const Duration(seconds: 8), () {
          if (state == null) return;
          if (_ref.read(agoraRtcSessionProvider).remoteUid != null) return;
          unawaited(_onRemoteEnded());
        });
      }
    };
    agora.onRemoteVideoMuted = (uid, muted) {
      final current = _ref.read(agoraRtcSessionProvider).remoteUid;
      if (current != null && uid != current) return;
      rtc.setRemoteCameraOn(!muted);
    };
    agora.onRemoteVideoUiChanged = ({
      required bool stopped,
      required bool frozen,
    }) {
      rtc.setRemoteVideoUi(stopped: stopped, frozen: frozen);
    };
    agora.onLocalCameraFailed = (failed, message) {
      rtc.setLocalCameraFailed(failed, message: message);
    };
    agora.onRtcUiConnectionChanged = rtc.setConnection;
    agora.onError = (message) {
      rtc.setUserFacingError(message);
    };
    agora.onNetworkQuality = (_, label) {
      rtc.setNetworkQuality(label);
    };
    agora.onRtcStatsUpdate = ({
      required int bitrateKbps,
      required int packetLossPercent,
    }) {
      rtc.setRtcStats(
        bitrateKbps: bitrateKbps,
        packetLossPercent: packetLossPercent,
      );
    };
    agora.onSpeakingChanged = ({
      int? remoteUid,
      required bool localSpeaking,
    }) {
      rtc.setSpeaking(remoteUid: remoteUid, localSpeaking: localSpeaking);
    };
    agora.onFirstRemoteVideoFrame = (uid, width, height) {
      rtc.setFirstRemoteVideoFrame();
    };
    agora.onAudioRouteChanged = (routing) {
      final previous = _ref.read(agoraRtcSessionProvider).audioRoute;
      rtc.setAudioRoute(routing);
      final preference = _ref.read(isSpeakerOnProvider);
      if (CallAudioRoute.shouldRestoreSpeakerPreference(
        previousRouting: previous,
        nextRouting: routing,
        speakerPreference: preference,
      )) {
        unawaited(agora.setSpeakerphoneEnabled(preference));
      }
    };
    agora.onTokenRefreshRequired = () async {
      final callId = state?.callId ?? 0;
      if (callId <= 0) return const CallTokenRefreshResult(token: '');
      try {
        final tokenData =
            await _ref.read(callSignalingServiceProvider).fetchAgoraToken(callId);
        return CallTokenRefreshResult(
          token: tokenData.token,
          expiresAt: tokenData.expiresAt,
        );
      } catch (e) {
        AppLogger.warning('Minimized token refresh failed', tag: _tag, error: e);
        return const CallTokenRefreshResult(token: '');
      }
    };
  }

  @override
  void dispose() {
    _tick?.cancel();
    _remoteLeft?.cancel();
    super.dispose();
  }
}
