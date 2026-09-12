import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_voice_record_gesture.dart';
import 'package:lgbtindernew/widgets/chat/chat_voice_record_bar.dart';
import 'package:lgbtindernew/widgets/chat/message_input.dart';
import 'package:lgbtindernew/widgets/chat/voice_waveform_bars.dart';

void main() {
  test('live recording uses 30 waveform bars and 72px thresholds', () {
    expect(AppAnimations.chatVoiceRecordBars, 30);
    expect(ChatVoiceRecordGesture.cancelThreshold, 72);
    expect(ChatVoiceRecordGesture.lockThreshold, 72);
  });

  Widget host({
    required Future<bool> Function() onStart,
    Future<void> Function()? onSend,
    Future<void> Function()? onCancel,
    bool reduceMotion = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: reduceMotion
            ? (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                  ),
                  child: child!,
                );
              }
            : null,
        home: Scaffold(
          body: MessageInput(
            onSend: (_) {},
            onVoiceRecordStart: onStart,
            onVoiceRecordSend: onSend ?? () async {},
            onVoiceRecordCancel: onCancel ?? () async {},
          ),
        ),
      ),
    );
  }

  Future<TestGesture> startHold(WidgetTester tester) async {
    final mic = find.byKey(const ValueKey('chat-voice-mic'));
    final gesture = await tester.startGesture(tester.getCenter(mic));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();
    return gesture;
  }

  testWidgets('recording shows 30-bar waveform and lock affordance',
      (tester) async {
    await tester.pumpWidget(host(onStart: () async => true));
    await tester.pump();
    final gesture = await startHold(tester);

    expect(find.byType(ChatVoiceRecordBar), findsOneWidget);
    expect(find.byKey(ChatVoiceRecordBar.lockHintKey), findsOneWidget);
    expect(find.text('< Slide to cancel'), findsOneWidget);
    final bars = tester.widget<VoiceWaveformBars>(find.byType(VoiceWaveformBars));
    expect(bars.barCount, AppAnimations.chatVoiceRecordBars);
    expect(find.byIcon(Icons.mic), findsNothing);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('slide left cancels without sending', (tester) async {
    var sends = 0;
    var cancels = 0;
    await tester.pumpWidget(
      host(
        onStart: () async => true,
        onSend: () async => sends++,
        onCancel: () async => cancels++,
      ),
    );
    await tester.pump();
    final gesture = await startHold(tester);
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(cancels, 1);
    expect(sends, 0);
    expect(find.byType(ChatVoiceRecordBar), findsNothing);
  });

  testWidgets('lock sends on tap and trash discards', (tester) async {
    var sends = 0;
    var cancels = 0;
    await tester.pumpWidget(
      host(
        onStart: () async => true,
        onSend: () async => sends++,
        onCancel: () async => cancels++,
      ),
    );
    await tester.pump();
    final gesture = await startHold(tester);
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byKey(ChatVoiceRecordBar.discardKey), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-voice-locked-send')), findsOneWidget);
    expect(sends, 0);
    expect(cancels, 0);

    await tester.tap(find.byKey(const ValueKey('chat-voice-locked-send')));
    await tester.pump();
    expect(sends, 1);
    expect(cancels, 0);
  });

  testWidgets('locked trash discards without sending', (tester) async {
    var sends = 0;
    var cancels = 0;
    await tester.pumpWidget(
      host(
        onStart: () async => true,
        onSend: () async => sends++,
        onCancel: () async => cancels++,
      ),
    );
    await tester.pump();
    final gesture = await startHold(tester);
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byKey(ChatVoiceRecordBar.discardKey));
    await tester.pump();
    expect(cancels, 1);
    expect(sends, 0);
    expect(find.byType(ChatVoiceRecordBar), findsNothing);
  });

  testWidgets('denied microphone start does not look like recording',
      (tester) async {
    await tester.pumpWidget(host(onStart: () async => false));
    await tester.pump();
    final gesture = await startHold(tester);

    expect(find.byType(ChatVoiceRecordBar), findsNothing);
    expect(find.byKey(const ValueKey('chat-voice-mic')), findsOneWidget);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Reduce Motion keeps a static record pulse', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Scaffold(
          body: ChatVoiceRecordBar(
            seconds: 3,
            locked: false,
            onDiscard: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(VoiceWaveformBars), findsOneWidget);
    final bars = tester.widget<VoiceWaveformBars>(find.byType(VoiceWaveformBars));
    expect(bars.barCount, 30);
    expect(find.byType(AppSvgIcon), findsWidgets);
  });
}
