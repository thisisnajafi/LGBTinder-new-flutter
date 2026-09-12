import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// UI-facing Agora connection state (SDK [ConnectionStateType] mapped).
enum CallRtcConnectionUi {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Why a remote user left the channel.
enum CallRemoteLeaveReason {
  quit,
  dropped,
  other,
}

/// Network quality labels used by the call UI and [CallQualityMonitor].
///
/// Agora [QualityType] documented values:
/// 0 unknown, 1 excellent, 2 good, 3 poor, 4 bad, 5 vbad, 6 down,
/// 7 unsupported, 8 detecting.
///
/// The warning chip is shown only for [poor] and [bad]. Excellent and good
/// must never be treated as degraded.
class AgoraNetworkQuality {
  AgoraNetworkQuality._();

  static const String unknown = 'unknown';
  static const String excellent = 'excellent';
  static const String good = 'good';
  static const String poor = 'poor';
  static const String bad = 'bad';

  /// Map by enum name so [QualityType.index] cannot invert labels.
  static String fromType(QualityType type) {
    switch (type) {
      case QualityType.qualityExcellent:
        return excellent;
      case QualityType.qualityGood:
        return good;
      case QualityType.qualityPoor:
        return poor;
      case QualityType.qualityBad:
      case QualityType.qualityVbad:
      case QualityType.qualityDown:
        return bad;
      case QualityType.qualityUnknown:
      case QualityType.qualityUnsupported:
      case QualityType.qualityDetecting:
        return unknown;
    }
  }

  /// Documented Agora integer values (same as [QualityType.value]).
  static String fromScore(int score) {
    switch (score) {
      case 1:
        return excellent;
      case 2:
        return good;
      case 3:
        return poor;
      case 4:
      case 5:
      case 6:
        return bad;
      default:
        return unknown;
    }
  }

  static bool isDegraded(String label) =>
      label == poor || label == bad;

  /// Agora quality 4–5 (`bad` / `vbad` / `down`). Poor (3) uses bars only.
  static bool shouldToast(String label) => label == bad;

  /// Heuristic from bitrate/loss. Returns null when stats must not overwrite
  /// an Agora [onNetworkQuality] label (including dummy 0/0).
  static String? fromRtcStats({
    required int bitrateKbps,
    required int packetLossPercent,
    required String currentQuality,
  }) {
    if (currentQuality != unknown) return null;
    if (bitrateKbps == 0 && packetLossPercent == 0) return null;
    if (packetLossPercent < 1 && bitrateKbps > 500) return excellent;
    if (packetLossPercent < 3 && bitrateKbps > 200) return good;
    if (packetLossPercent < 10 && bitrateKbps > 50) return poor;
    return bad;
  }
}

/// Volume / VAD floor for [RtcEngine.enableAudioVolumeIndication].
class AgoraSpeaking {
  AgoraSpeaking._();

  static const int volumeThreshold = 15;

  static bool isActive({required int volume, int vad = 0}) =>
      vad == 1 || volume > volumeThreshold;
}

class AgoraErrorMessages {
  AgoraErrorMessages._();

  /// User-facing copy only — never return raw SDK strings.
  static String fromErrorCode(ErrorCodeType err) {
    switch (err) {
      case ErrorCodeType.errNoPermission:
      case ErrorCodeType.errVdmCameraNotAuthorized:
        return 'Camera or microphone permission is required';
      case ErrorCodeType.errInvalidToken:
      case ErrorCodeType.errTokenExpired:
        return 'Call session expired';
      case ErrorCodeType.errInvalidAppId:
      case ErrorCodeType.errNoServerResources:
        return 'Call service is unavailable';
      case ErrorCodeType.errJoinChannelRejected:
      case ErrorCodeType.errInvalidChannelName:
        return 'Could not join the call';
      case ErrorCodeType.errNetDown:
      case ErrorCodeType.errTimedout:
      case ErrorCodeType.errInitNetEngine:
        return 'Connection failed';
      case ErrorCodeType.errAdmInitRecording:
      case ErrorCodeType.errAdmStartRecording:
        return 'Microphone is unavailable';
      case ErrorCodeType.errResourceLimited:
        return 'This device cannot start the call';
      default:
        return 'Connection failed';
    }
  }

  static String fromLocalVideoReason(LocalVideoStreamReason reason) {
    switch (reason) {
      case LocalVideoStreamReason.localVideoStreamReasonDeviceNoPermission:
        return 'Camera permission is required';
      case LocalVideoStreamReason.localVideoStreamReasonDeviceBusy:
        return 'Camera is in use by another app';
      case LocalVideoStreamReason.localVideoStreamReasonDeviceNotFound:
      case LocalVideoStreamReason.localVideoStreamReasonDeviceDisconnected:
        return 'Camera is unavailable';
      case LocalVideoStreamReason.localVideoStreamReasonCaptureFailure:
      case LocalVideoStreamReason.localVideoStreamReasonCaptureInbackground:
        return 'Camera could not start';
      default:
        return 'Camera is unavailable';
    }
  }

  static CallRtcConnectionUi fromConnectionState(ConnectionStateType state) {
    switch (state) {
      case ConnectionStateType.connectionStateConnecting:
        return CallRtcConnectionUi.connecting;
      case ConnectionStateType.connectionStateConnected:
        return CallRtcConnectionUi.connected;
      case ConnectionStateType.connectionStateReconnecting:
        return CallRtcConnectionUi.reconnecting;
      case ConnectionStateType.connectionStateFailed:
        return CallRtcConnectionUi.failed;
      case ConnectionStateType.connectionStateDisconnected:
        return CallRtcConnectionUi.disconnected;
    }
  }

  static CallRemoteLeaveReason fromOfflineReason(
    UserOfflineReasonType reason,
  ) {
    switch (reason) {
      case UserOfflineReasonType.userOfflineQuit:
        return CallRemoteLeaveReason.quit;
      case UserOfflineReasonType.userOfflineDropped:
        return CallRemoteLeaveReason.dropped;
      case UserOfflineReasonType.userOfflineBecomeAudience:
        return CallRemoteLeaveReason.other;
    }
  }
}
