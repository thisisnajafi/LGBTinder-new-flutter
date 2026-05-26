import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_history_bubble.dart';

void main() {
  testWidgets('CallHistoryBubble shows ended call label', (tester) async {
    final call = Call(
      id: 7,
      callId: '7',
      callerId: 1,
      receiverId: 2,
      callType: 'audio',
      status: 'ended',
      startedAt: DateTime(2026, 5, 24),
      duration: const Duration(seconds: 90),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallHistoryBubble(
            call: call,
            currentUserId: 1,
          ),
        ),
      ),
    );

    expect(find.textContaining('Voice call'), findsOneWidget);
    expect(find.textContaining('01:30'), findsOneWidget);
  });

  testWidgets('CallHistoryBubble shows missed call in error styling context', (tester) async {
    final call = Call(
      id: 8,
      callId: '8',
      callerId: 3,
      receiverId: 2,
      callType: 'video',
      status: 'missed',
      startedAt: DateTime(2026, 5, 24),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallHistoryBubble(
            call: call,
            currentUserId: 2,
          ),
        ),
      ),
    );

    expect(find.text('Missed video call'), findsOneWidget);
  });
}
