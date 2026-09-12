import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_speaking_ring.dart';
import 'package:lgbtindernew/features/calls/providers/agora_rtc_session_provider.dart';
import 'package:lgbtindernew/features/calls/providers/live_call_ui_provider.dart';

void main() {
  testWidgets('active speaker shows Speaking semantics and a pulse painter',
      (tester) async {
    await tester.pumpWidget(_ring(active: true));

    expect(find.bySemanticsLabel('Speaking'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(RepaintBoundary), findsWidgets);

    await tester.pump(AppAnimations.callSpeakingPulse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('silence stops the speaking indicator', (tester) async {
    await tester.pumpWidget(_ring(active: true));
    expect(find.bySemanticsLabel('Speaking'), findsOneWidget);

    await tester.pumpWidget(_ring(active: false));
    await tester.pump();
    expect(find.bySemanticsLabel('Speaking'), findsNothing);
  });

  testWidgets('Reduce Motion shows a static speaking ring', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: Center(
            child: CallSpeakingRing(
              active: true,
              diameter: 48,
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Speaking'), findsOneWidget);
    await tester.pump(AppAnimations.callSpeakingPulse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('speaking ticks do not rebuild a video-style camera watcher',
      (tester) async {
    var videoBuilds = 0;

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
                    return const Text('video');
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final speaking = ref.watch(remoteSpeakingProvider);
                    return Text(speaking ? 'speaking' : 'quiet');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(videoBuilds, 1);
    expect(find.text('quiet'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.text('video')),
    );
    container.read(agoraRtcSessionProvider.notifier).setSpeaking(
          remoteUid: 42,
          localSpeaking: false,
        );
    await tester.pump();

    expect(find.text('speaking'), findsOneWidget);
    expect(videoBuilds, 1);

    container.read(agoraRtcSessionProvider.notifier).setSpeaking(
          remoteUid: null,
          localSpeaking: false,
        );
    await tester.pump();
    expect(find.text('quiet'), findsOneWidget);
    expect(videoBuilds, 1);
  });
}

Widget _ring({required bool active}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: CallSpeakingRing(
          active: active,
          diameter: 48,
          child: const SizedBox(width: 48, height: 48),
        ),
      ),
    ),
  );
}
