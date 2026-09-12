import '../../../core/utils/app_icons.dart';

/// Agora [AudioRoute] integers (SDK 6.3.2).
enum CallAudioRouteKind {
  earpiece,
  speaker,
  headset,
  bluetooth,
}

/// Voice vs video defaults and live-route chrome (CALL-PERF-004 / CALL-NATIVE-003).
class CallAudioRoute {
  CallAudioRoute._();

  static const int headset = 0;
  static const int earpiece = 1;
  static const int headsetNoMic = 2;
  static const int speakerphone = 3;
  static const int loudspeaker = 4;
  static const int bluetoothHfp = 5;
  static const int bluetoothA2dp = 10;

  static bool defaultSpeakerOn({required bool isVideoCall}) => isVideoCall;

  static CallAudioRouteKind kind(
    int? routing, {
    required bool fallbackSpeakerOn,
  }) {
    switch (routing) {
      case headset:
      case headsetNoMic:
        return CallAudioRouteKind.headset;
      case bluetoothHfp:
      case bluetoothA2dp:
        return CallAudioRouteKind.bluetooth;
      case speakerphone:
      case loudspeaker:
        return CallAudioRouteKind.speaker;
      case earpiece:
        return CallAudioRouteKind.earpiece;
      default:
        return fallbackSpeakerOn
            ? CallAudioRouteKind.speaker
            : CallAudioRouteKind.earpiece;
    }
  }

  static bool speakerphoneFromRouting(int routing) =>
      kind(routing, fallbackSpeakerOn: false) == CallAudioRouteKind.speaker;

  static bool isExternalRoute(CallAudioRouteKind kind) =>
      kind == CallAudioRouteKind.bluetooth || kind == CallAudioRouteKind.headset;

  /// Speaker toggle is ignored while Agora is on BT or a wired headset.
  static bool canToggleSpeaker(CallAudioRouteKind kind) =>
      !isExternalRoute(kind);

  /// After BT/headset unplug, re-apply the user's speaker/earpiece choice.
  static bool shouldRestoreSpeakerPreference({
    required int? previousRouting,
    required int nextRouting,
    required bool speakerPreference,
  }) {
    final prev = kind(previousRouting, fallbackSpeakerOn: speakerPreference);
    final next = kind(nextRouting, fallbackSpeakerOn: speakerPreference);
    return isExternalRoute(prev) && !isExternalRoute(next);
  }

  static String iconFor(CallAudioRouteKind kind) {
    switch (kind) {
      case CallAudioRouteKind.bluetooth:
      case CallAudioRouteKind.headset:
        return AppIcons.headphone;
      case CallAudioRouteKind.speaker:
      case CallAudioRouteKind.earpiece:
        return AppIcons.volumeHigh;
    }
  }

  static String labelFor(CallAudioRouteKind kind) {
    switch (kind) {
      case CallAudioRouteKind.bluetooth:
      case CallAudioRouteKind.headset:
        return 'Headphones';
      case CallAudioRouteKind.speaker:
        return 'Speaker';
      case CallAudioRouteKind.earpiece:
        return 'Earpiece';
    }
  }
}
