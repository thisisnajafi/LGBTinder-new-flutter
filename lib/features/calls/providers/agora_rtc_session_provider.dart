import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/agora_rtc_types.dart';
import '../data/models/agora_rtc_session.dart';

final agoraRtcSessionProvider =
    StateNotifierProvider<AgoraRtcSessionNotifier, AgoraRtcSession>((ref) {
  return AgoraRtcSessionNotifier();
});

final networkQualityProvider = Provider<String>((ref) {
  return ref.watch(
    agoraRtcSessionProvider.select((state) => state.networkQuality),
  );
});

final remoteUserJoinedProvider = Provider<bool>((ref) {
  return ref.watch(
    agoraRtcSessionProvider.select((state) => state.remoteUid != null),
  );
});

final localSpeakingProvider = Provider<bool>((ref) {
  return ref.watch(
    agoraRtcSessionProvider.select((state) => state.localSpeaking),
  );
});

final remoteSpeakingProvider = Provider<bool>((ref) {
  return ref.watch(
    agoraRtcSessionProvider.select((state) => state.speakingUid != null),
  );
});

class AgoraRtcSessionNotifier extends StateNotifier<AgoraRtcSession> {
  AgoraRtcSessionNotifier() : super(const AgoraRtcSession());

  void reset() {
    state = const AgoraRtcSession();
  }

  void setConnection(CallRtcConnectionUi connection) {
    if (state.connection == connection &&
        !(connection == CallRtcConnectionUi.connected && state.reconnectInFlight)) {
      return;
    }
    state = state.copyWith(
      connection: connection,
      clearUserFacingError: connection == CallRtcConnectionUi.connected,
      reconnectInFlight: connection == CallRtcConnectionUi.connected
          ? false
          : state.reconnectInFlight,
    );
  }

  void remoteUserJoined(int uid) {
    state = state.copyWith(
      remoteUid: uid,
      clearRemoteLeaveReason: true,
      remoteCameraOn: true,
      remoteVideoFrozen: false,
    );
  }

  void remoteUserLeft(int uid, CallRemoteLeaveReason reason) {
    if (state.remoteUid != null && state.remoteUid != uid) return;
    state = state.copyWith(
      clearRemoteUid: true,
      remoteLeaveReason: reason,
      remoteCameraOn: false,
    );
  }

  void setRemoteCameraOn(bool on) {
    if (state.remoteCameraOn == on && !state.remoteVideoFrozen) return;
    state = state.copyWith(remoteCameraOn: on, remoteVideoFrozen: false);
  }

  void setRemoteVideoUi({required bool stopped, required bool frozen}) {
    state = state.copyWith(
      remoteCameraOn: !stopped,
      remoteVideoFrozen: frozen && !stopped,
    );
  }

  void setLocalCameraFailed(bool failed, {String? message}) {
    state = state.copyWith(
      localCameraFailed: failed,
      localCameraFailureMessage: failed ? message : null,
      clearLocalCameraFailure: !failed,
    );
  }

  void setNetworkQuality(String label) {
    if (state.networkQuality == label) return;
    state = state.copyWith(networkQuality: label);
  }

  void setRtcStats({required int bitrateKbps, required int packetLossPercent}) {
    if (state.bitrateKbps == bitrateKbps &&
        state.packetLossPercent == packetLossPercent) {
      return;
    }
    state = state.copyWith(
      bitrateKbps: bitrateKbps,
      packetLossPercent: packetLossPercent,
    );
  }

  void setSpeaking({int? remoteUid, required bool localSpeaking}) {
    if (state.speakingUid == remoteUid && state.localSpeaking == localSpeaking) {
      return;
    }
    state = state.copyWith(
      speakingUid: remoteUid,
      clearSpeakingUid: remoteUid == null,
      localSpeaking: localSpeaking,
    );
  }

  void setFirstRemoteVideoFrame() {
    if (state.firstRemoteVideoFrameReceived) return;
    state = state.copyWith(firstRemoteVideoFrameReceived: true);
  }

  void setAudioRoute(int routing) {
    if (state.audioRoute == routing) return;
    state = state.copyWith(audioRoute: routing);
  }

  void setReconnectInFlight(bool value) {
    if (state.reconnectInFlight == value) return;
    state = state.copyWith(reconnectInFlight: value);
  }

  void setUserFacingError(String? message) {
    if (message == null) {
      if (state.userFacingError == null) return;
      state = state.copyWith(clearUserFacingError: true);
      return;
    }
    if (state.userFacingError == message) return;
    state = state.copyWith(userFacingError: message);
  }
}
