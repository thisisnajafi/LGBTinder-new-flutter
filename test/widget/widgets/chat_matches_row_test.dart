import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/matching/data/models/match.dart';
import 'package:lgbtindernew/widgets/chat/chat_matches_row.dart';

void main() {
  testWidgets('ChatMatchesRow reports the tapped match instead of routing itself',
      (tester) async {
    Match? tapped;
    final match = Match(
      id: 11,
      userId: 42,
      firstName: 'Alex',
      matchedAt: DateTime(2026, 1, 1),
      isRead: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ChatMatchesRow(
              matches: [match],
              onMatchTap: (value) => tapped = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Alex'));
    await tester.pump();

    expect(tapped, isNotNull);
    expect(tapped!.userId, 42);
    expect(tapped!.firstName, 'Alex');
  });
}
