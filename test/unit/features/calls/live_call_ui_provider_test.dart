import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/providers/agora_rtc_session_provider.dart';
import 'package:lgbtindernew/features/calls/providers/call_provider.dart';
import 'package:lgbtindernew/features/calls/providers/live_call_ui_provider.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

Call _call({String status = 'active'}) {
  return Call(
    id: 1,
    callId: '1',
    callerId: 10,
    receiverId: 20,
    callType: 'video',
    status: status,
    startedAt: DateTime.utc(2026, 9, 11),
  );
}

void main() {
  group('Call.isActive', () {
    test('treats backend active and connected as live', () {
      expect(_call(status: 'active').isActive, isTrue);
      expect(_call(status: 'connected').isActive, isTrue);
      expect(_call(status: 'ACTIVE').isActive, isTrue);
      expect(_call(status: 'ringing').isActive, isFalse);
      expect(_call(status: 'ended').isActive, isFalse);
    });
  });

  group('CallState.copyWith', () {
    test('endCall can clear activeCall to null', () {
      final state = CallState(activeCall: _call(), error: 'old');
      final cleared = state.copyWith(activeCall: null, error: null);
      expect(cleared.activeCall, isNull);
      expect(cleared.error, isNull);
    });

    test('omitted nullables stay set', () {
      final state = CallState(activeCall: _call(), incomingCallId: '9');
      final next = state.copyWith(isEndingCall: true);
      expect(next.activeCall, isNotNull);
      expect(next.incomingCallId, '9');
      expect(next.isEndingCall, isTrue);
    });
  });

  group('LiveCallUiNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('timer ticks do not notify mute or camera listeners', () {
      container.read(liveCallUiProvider.notifier).setConnected(true);

      var muteNotifications = 0;
      var cameraNotifications = 0;
      var timerNotifications = 0;
      container.listen(isMutedProvider, (_, __) => muteNotifications++);
      container.listen(isCameraOnProvider, (_, __) => cameraNotifications++);
      container.listen(callTimerProvider, (_, __) => timerNotifications++);

      container.read(liveCallUiProvider.notifier).tick();

      expect(container.read(callTimerProvider), const Duration(seconds: 1));
      expect(timerNotifications, 1);
      expect(muteNotifications, 0);
      expect(cameraNotifications, 0);
    });

    test('mute does not notify the timer', () {
      container.read(liveCallUiProvider.notifier).setConnected(true);
      container.read(liveCallUiProvider.notifier).tick();

      var timerNotifications = 0;
      container.listen(callTimerProvider, (_, __) => timerNotifications++);

      container.read(liveCallUiProvider.notifier).setMuted(true);

      expect(container.read(isMutedProvider), isTrue);
      expect(container.read(callTimerProvider), const Duration(seconds: 1));
      expect(timerNotifications, 0);
    });

    test('tick is ignored until connected', () {
      container.read(liveCallUiProvider.notifier).tick();
      expect(container.read(callTimerProvider), Duration.zero);
      expect(container.read(callStatusProvider), isFalse);
    });

    test('reset uses earpiece unless video speakerOn is passed', () {
      container.read(liveCallUiProvider.notifier).setSpeakerOn(true);
      container.read(liveCallUiProvider.notifier).reset();
      expect(container.read(isSpeakerOnProvider), isFalse);

      container.read(liveCallUiProvider.notifier).reset(speakerOn: true);
      expect(container.read(isSpeakerOnProvider), isTrue);
    });
  });

  testWidgets('timer tick does not rebuild the video subtree', (tester) async {
    var videoBuilds = 0;
    var muteBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    videoBuilds++;
                    ref.watch(isCameraOnProvider);
                    ref.watch(
                      agoraRtcSessionProvider.select((s) => s.remoteUid),
                    );
                    return const Text('video');
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    muteBuilds++;
                    final muted = ref.watch(isMutedProvider);
                    return Text(muted ? 'muted' : 'open');
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final duration = ref.watch(callTimerProvider);
                    return Text('t${duration.inSeconds}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(videoBuilds, 1);
    expect(muteBuilds, 1);

    final container = ProviderScope.containerOf(
      tester.element(find.text('video')),
    );
    container.read(liveCallUiProvider.notifier).setConnected(true);
    container.read(liveCallUiProvider.notifier).tick();
    await tester.pump();

    expect(find.text('t1'), findsOneWidget);
    expect(videoBuilds, 1);
    expect(muteBuilds, 1);

    container.read(liveCallUiProvider.notifier).setMuted(true);
    await tester.pump();

    expect(find.text('muted'), findsOneWidget);
    expect(muteBuilds, 2);
    expect(videoBuilds, 1);
  });

  test('network quality select does not change remote-joined', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var remoteNotifications = 0;
    container.listen(remoteUserJoinedProvider, (_, __) => remoteNotifications++);

    container.read(agoraRtcSessionProvider.notifier).setNetworkQuality(
          AgoraNetworkQuality.poor,
        );
    expect(container.read(networkQualityProvider), AgoraNetworkQuality.poor);
    expect(remoteNotifications, 0);
  });
}
