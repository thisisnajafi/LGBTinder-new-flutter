import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/data/models/chat_forward_result.dart';
import 'package:lgbtindernew/features/chat/utils/chat_forward_attribution.dart';
import 'package:lgbtindernew/widgets/chat/chat_forwarded_header.dart';

void main() {
  test('forward icon uses the forward glyph', () {
    expect(AppIcons.forward, contains('forward.svg'));
    expect(AppIcons.forward, isNot(contains('arrow-right')));
  });

  test('attribution copy includes the original name', () {
    expect(ChatForwardAttribution.label('Alex'), 'Forwarded from Alex');
    expect(ChatForwardAttribution.label('  '), 'Forwarded');
    expect(ChatForwardAttribution.label(null), 'Forwarded');
    expect(ChatForwardAttribution.maxRecipients, 20);
  });

  test('forward result parses forwarded rows and skips', () {
    final result = ChatForwardResult.fromJson({
      'data': {
        'forwarded': [
          {
            'id': 9,
            'sender_id': 1,
            'receiver_id': 4,
            'message': 'hi',
            'message_type': 'text',
            'created_at': '2026-09-12T01:00:00.000000Z',
            'forwarded_from_name': 'Alex',
            'forwarded_from_user_id': 2,
            'is_forwarded': true,
          },
        ],
        'skipped': [
          {'user_id': 8, 'reason': 'not_eligible'},
        ],
      },
    });
    expect(result.forwarded, hasLength(1));
    expect(result.forwarded.first.receiverId, 4);
    expect(result.forwarded.first.forwardedFromName, 'Alex');
    expect(result.forwarded.first.isForwarded, isTrue);
    expect(result.skipped, hasLength(1));
    expect(result.skipped.first.reason, 'not_eligible');
  });

  testWidgets('forwarded header shows attribution', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatForwardedHeader(name: 'Alex', isSent: false),
        ),
      ),
    );
    expect(find.text('Forwarded from Alex'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
