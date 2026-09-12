import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_send_celebration.dart';
import 'package:lgbtindernew/features/chat/utils/chat_voice_record_gesture.dart';
import 'package:lgbtindernew/widgets/chat/message_input.dart';

void main() {
  Widget host({
    required Future<bool> Function() onStart,
    required Future<void> Function() onSend,
    required Future<void> Function() onCancel,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MessageInput(
            onVoiceRecordStart: onStart,
            onVoiceRecordSend: onSend,
            onVoiceRecordCancel: onCancel,
          ),
        ),
      ),
    );
  }

  testWidgets('slide left cancels without sending', (tester) async {
    var starts = 0;
    var sends = 0;
    var cancels = 0;

    await tester.pumpWidget(
      host(
        onStart: () async {
          starts++;
          return true;
        },
        onSend: () async {
          sends++;
        },
        onCancel: () async {
          cancels++;
        },
      ),
    );
    await tester.pump();

    final center = tester.getCenter(
      find.byKey(ChatSendCelebration.sendOriginKey),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(
      const Offset(-ChatVoiceRecordGesture.cancelThreshold - 8, 0),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(starts, 1);
    expect(cancels, 1);
    expect(sends, 0);
    expect(find.byKey(const ValueKey('chat-voice-discard')), findsNothing);
  });

  testWidgets('slide up locks; tap sends; trash discards', (tester) async {
    var sends = 0;
    var cancels = 0;

    await tester.pumpWidget(
      host(
        onStart: () async => true,
        onSend: () async {
          sends++;
        },
        onCancel: () async {
          cancels++;
        },
      ),
    );
    await tester.pump();

    final center = tester.getCenter(
      find.byKey(ChatSendCelebration.sendOriginKey),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(
      const Offset(0, -ChatVoiceRecordGesture.lockThreshold - 8),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byKey(const ValueKey('chat-voice-locked')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-voice-discard')), findsOneWidget);
    expect(sends, 0);

    await tester.tap(find.byTooltip('Send recording'));
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
        onSend: () async {
          sends++;
        },
        onCancel: () async {
          cancels++;
        },
      ),
    );
    await tester.pump();

    final center = tester.getCenter(
      find.byKey(ChatSendCelebration.sendOriginKey),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(
      const Offset(0, -ChatVoiceRecordGesture.lockThreshold - 8),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('chat-voice-discard')));
    await tester.pump();
    expect(sends, 0);
    expect(cancels, 1);
  });
}
