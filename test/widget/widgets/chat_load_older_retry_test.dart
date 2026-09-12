import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_load_older.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';
import 'package:lgbtindernew/widgets/chat/chat_load_older_retry.dart';

void main() {
  test('reverse thread does not jump when older rows are prepended', () {
    expect(ChatThreadScroll.reversed, isTrue);
    expect(ChatThreadScroll.latestPixels, 0);
    expect(ChatLoadOlder.needsScrollCompensation, isFalse);
  });

  test('withoutExistingIds drops duplicate message ids', () {
    final kept = ChatLoadOlder.withoutExistingIds(
      incoming: [
        (id: 1, text: 'a'),
        (id: 2, text: 'b'),
        (id: 3, text: 'c'),
      ],
      idOf: (item) => item.id,
      existingIds: {2, 9},
    );

    expect(kept.map((item) => item.id), [1, 3]);
  });

  testWidgets('retry chip is tappable and uses SVG refresh', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatLoadOlderRetry(onRetry: () => taps += 1),
        ),
      ),
    );

    expect(find.text("Couldn't load older messages · Retry"), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(
      tester.widget<AppSvgIcon>(find.byType(AppSvgIcon)).assetPath,
      AppIcons.refreshOutline,
    );

    await tester.tap(find.byType(ChatLoadOlderRetry));
    expect(taps, 1);
  });
}
