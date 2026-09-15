import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/responsive/responsive_text.dart';
import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_history_bubble.dart';
import 'package:lgbtindernew/widgets/chat/chat_system_message.dart';

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
        theme: AppTheme.lightTheme,
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
    expect(find.byType(InkWell), findsNothing);
    expect(find.byKey(ChatSystemMessage.barKey), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    final label = tester.widget<AppText>(
      find.byWidgetPredicate(
        (widget) => widget is AppText && widget.text.contains('Voice call'),
      ),
    );
    expect(label.style?.color, AppColors.textSecondaryLight);
    final context = tester.element(find.byType(CallHistoryBubble));
    expect(label.style?.fontSize, Theme.of(context).textTheme.labelSmall?.fontSize);
  });

  testWidgets('CallHistoryBubble shows missed call in error styling context',
      (tester) async {
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
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CallHistoryBubble(
            call: call,
            currentUserId: 2,
          ),
        ),
      ),
    );

    expect(find.text('Missed video call'), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
    final label = tester.widget<AppText>(
      find.byWidgetPredicate(
        (widget) => widget is AppText && widget.text == 'Missed video call',
      ),
    );
    expect(label.style?.color, AppColors.feedbackError);
  });
}
