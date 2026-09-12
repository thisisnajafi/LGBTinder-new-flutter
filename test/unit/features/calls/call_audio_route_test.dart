import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/calls/utils/call_audio_route.dart';

void main() {
  test('voice starts on earpiece; video on speaker', () {
    expect(CallAudioRoute.defaultSpeakerOn(isVideoCall: false), isFalse);
    expect(CallAudioRoute.defaultSpeakerOn(isVideoCall: true), isTrue);
  });

  test('maps Agora routing integers to speaker / earpiece / BT', () {
    expect(
      CallAudioRoute.kind(
        CallAudioRoute.earpiece,
        fallbackSpeakerOn: true,
      ),
      CallAudioRouteKind.earpiece,
    );
    expect(
      CallAudioRoute.kind(
        CallAudioRoute.speakerphone,
        fallbackSpeakerOn: false,
      ),
      CallAudioRouteKind.speaker,
    );
    expect(
      CallAudioRoute.kind(
        CallAudioRoute.bluetoothHfp,
        fallbackSpeakerOn: true,
      ),
      CallAudioRouteKind.bluetooth,
    );
    expect(
      CallAudioRoute.kind(
        CallAudioRoute.headset,
        fallbackSpeakerOn: false,
      ),
      CallAudioRouteKind.headset,
    );
    expect(
      CallAudioRoute.speakerphoneFromRouting(CallAudioRoute.speakerphone),
      isTrue,
    );
    expect(
      CallAudioRoute.speakerphoneFromRouting(CallAudioRoute.bluetoothA2dp),
      isFalse,
    );
  });

  test('BT and headset use the headphone SVG', () {
    expect(
      CallAudioRoute.iconFor(CallAudioRouteKind.bluetooth),
      AppIcons.headphone,
    );
    expect(
      CallAudioRoute.labelFor(CallAudioRouteKind.bluetooth),
      'Headphones',
    );
    expect(
      CallAudioRoute.iconFor(CallAudioRouteKind.speaker),
      AppIcons.volumeHigh,
    );
    expect(
      CallAudioRoute.labelFor(CallAudioRouteKind.earpiece),
      'Earpiece',
    );
  });

  test('BT and wired headset lock the speaker toggle', () {
    expect(
      CallAudioRoute.canToggleSpeaker(CallAudioRouteKind.bluetooth),
      isFalse,
    );
    expect(
      CallAudioRoute.canToggleSpeaker(CallAudioRouteKind.headset),
      isFalse,
    );
    expect(
      CallAudioRoute.canToggleSpeaker(CallAudioRouteKind.speaker),
      isTrue,
    );
    expect(
      CallAudioRoute.canToggleSpeaker(CallAudioRouteKind.earpiece),
      isTrue,
    );
  });

  test('disconnecting BT restores the previous speaker preference', () {
    expect(
      CallAudioRoute.shouldRestoreSpeakerPreference(
        previousRouting: CallAudioRoute.bluetoothHfp,
        nextRouting: CallAudioRoute.earpiece,
        speakerPreference: true,
      ),
      isTrue,
    );
    expect(
      CallAudioRoute.shouldRestoreSpeakerPreference(
        previousRouting: CallAudioRoute.speakerphone,
        nextRouting: CallAudioRoute.bluetoothA2dp,
        speakerPreference: true,
      ),
      isFalse,
    );
    expect(
      CallAudioRoute.shouldRestoreSpeakerPreference(
        previousRouting: CallAudioRoute.headset,
        nextRouting: CallAudioRoute.speakerphone,
        speakerPreference: false,
      ),
      isTrue,
    );
    expect(
      CallAudioRoute.shouldRestoreSpeakerPreference(
        previousRouting: CallAudioRoute.earpiece,
        nextRouting: CallAudioRoute.speakerphone,
        speakerPreference: false,
      ),
      isFalse,
    );
  });
}
