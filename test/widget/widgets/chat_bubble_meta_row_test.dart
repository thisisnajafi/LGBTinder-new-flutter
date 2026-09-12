import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/utils/chat_send_retry.dart';
import 'package:lgbtindernew/widgets/chat/chat_bubble_meta_row.dart';

void main() {
  Widget host({VoidCallback? onRetry}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: ChatBubbleMetaRow(
          timestamp: DateTime(2026, 9, 12, 1, 2),
          isSent: true,
          deliveryStatus: MessageDeliveryStatus.failed,
          onRetry: onRetry,
          color: Colors.white,
        ),
      ),
    );
  }

  testWidgets('shows Retry while taps are allowed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(onRetry: () => taps++));

    expect(find.text(ChatSendRetry.retryLabel), findsOneWidget);
    expect(find.text(ChatSendRetry.lockedLabel), findsNothing);
    await tester.tap(find.text(ChatSendRetry.retryLabel));
    expect(taps, 1);
  });

  testWidgets('locks with Failed to send after max retries', (tester) async {
    await tester.pumpWidget(host());

    expect(find.text(ChatSendRetry.lockedLabel), findsOneWidget);
    expect(find.text(ChatSendRetry.retryLabel), findsNothing);
  });

  testWidgets('edited is italic muted next to the time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatBubbleMetaRow(
            timestamp: DateTime(2026, 9, 12, 1, 2),
            isSent: false,
            isEdited: true,
            color: Colors.white,
          ),
        ),
      ),
    );

    final edited = tester.widget<Text>(find.text(ChatBubbleMetaRow.editedLabel));
    expect(edited.style?.fontStyle, FontStyle.italic);
    expect(edited.style?.color?.a, lessThan(1));
    expect(find.text('01:02'), findsOneWidget);
  });
}
