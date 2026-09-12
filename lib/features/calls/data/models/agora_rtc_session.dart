import '../../../../shared/services/agora_rtc_types.dart';

/// Live Agora RTC session snapshot for the active call screen.
class AgoraRtcSession {
  final CallRtcConnectionUi connection;
  final int? remoteUid;
  final CallRemoteLeaveReason? remoteLeaveReason;
  final bool remoteCameraOn;
  final bool remoteVideoFrozen;
  final bool localCameraFailed;
  final String? localCameraFailureMessage;
  final String networkQuality;
  final int? speakingUid;
  final bool localSpeaking;
  final int bitrateKbps;
  final int packetLossPercent;
  final String? userFacingError;
  final bool firstRemoteVideoFrameReceived;
  final int? audioRoute;
  final bool reconnectInFlight;

  const AgoraRtcSession({
    this.connection = CallRtcConnectionUi.disconnected,
    this.remoteUid,
    this.remoteLeaveReason,
    this.remoteCameraOn = true,
    this.remoteVideoFrozen = false,
    this.localCameraFailed = false,
    this.localCameraFailureMessage,
    this.networkQuality = AgoraNetworkQuality.unknown,
    this.speakingUid,
    this.localSpeaking = false,
    this.bitrateKbps = 0,
    this.packetLossPercent = 0,
    this.userFacingError,
    this.firstRemoteVideoFrameReceived = false,
    this.audioRoute,
    this.reconnectInFlight = false,
  });

  bool get isReconnecting =>
      connection == CallRtcConnectionUi.reconnecting ||
      remoteLeaveReason == CallRemoteLeaveReason.dropped ||
      reconnectInFlight;

  bool get isFailed => connection == CallRtcConnectionUi.failed;

  String get localCameraCaption => localCameraFailed
      ? (localCameraFailureMessage ?? 'Camera is unavailable')
      : 'Camera is off';

  String get remoteCameraCaption =>
      remoteVideoFrozen ? 'Unstable connection' : 'Camera is off';

  AgoraRtcSession copyWith({
    CallRtcConnectionUi? connection,
    int? remoteUid,
    bool clearRemoteUid = false,
    CallRemoteLeaveReason? remoteLeaveReason,
    bool clearRemoteLeaveReason = false,
    bool? remoteCameraOn,
    bool? remoteVideoFrozen,
    bool? localCameraFailed,
    String? localCameraFailureMessage,
    bool clearLocalCameraFailure = false,
    String? networkQuality,
    int? speakingUid,
    bool clearSpeakingUid = false,
    bool? localSpeaking,
    int? bitrateKbps,
    int? packetLossPercent,
    String? userFacingError,
    bool clearUserFacingError = false,
    bool? firstRemoteVideoFrameReceived,
    int? audioRoute,
    bool? reconnectInFlight,
  }) {
    return AgoraRtcSession(
      connection: connection ?? this.connection,
      remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
      remoteLeaveReason: clearRemoteLeaveReason
          ? null
          : (remoteLeaveReason ?? this.remoteLeaveReason),
      remoteCameraOn: remoteCameraOn ?? this.remoteCameraOn,
      remoteVideoFrozen: remoteVideoFrozen ?? this.remoteVideoFrozen,
      localCameraFailed: localCameraFailed ?? this.localCameraFailed,
      localCameraFailureMessage: clearLocalCameraFailure
          ? null
          : (localCameraFailureMessage ?? this.localCameraFailureMessage),
      networkQuality: networkQuality ?? this.networkQuality,
      speakingUid:
          clearSpeakingUid ? null : (speakingUid ?? this.speakingUid),
      localSpeaking: localSpeaking ?? this.localSpeaking,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      packetLossPercent: packetLossPercent ?? this.packetLossPercent,
      userFacingError: clearUserFacingError
          ? null
          : (userFacingError ?? this.userFacingError),
      firstRemoteVideoFrameReceived:
          firstRemoteVideoFrameReceived ?? this.firstRemoteVideoFrameReceived,
      audioRoute: audioRoute ?? this.audioRoute,
      reconnectInFlight: reconnectInFlight ?? this.reconnectInFlight,
    );
  }
}
