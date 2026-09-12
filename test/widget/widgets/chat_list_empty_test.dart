import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_empty.dart';

void main() {
  test('inbox empty copy shows a Discover CTA; search misses do not', () {
    expect(ChatListEmpty.showsDiscoverCta(''), isTrue);
    expect(ChatListEmpty.showsDiscoverCta('alex'), isFalse);
    expect(ChatListEmpty.discoverLabel, 'Discover People');
  });

  testWidgets('empty inbox shows Discover People and search misses do not',
      (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: Scaffold(
            body: ChatListEmpty(
              onDiscover: () => tapped++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(ChatListEmpty.noneTitle), findsOneWidget);
    expect(find.text(ChatListEmpty.discoverLabel), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.text(ChatListEmpty.discoverLabel));
    expect(tapped, 1);
  });

  testWidgets('search empty state hides the Discover CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            );
          },
          home: const Scaffold(
            body: ChatListEmpty(
              title: ChatListEmpty.searchTitle,
              message: ChatListEmpty.searchMessage,
              onDiscover: _unusedDiscover,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(ChatListEmpty.searchTitle), findsOneWidget);
    expect(find.text(ChatListEmpty.discoverLabel), findsNothing);
  });
}

void _unusedDiscover() {}
