import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/providers/chat_typing_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_presence_copy.dart';
import 'package:lgbtindernew/widgets/chat/chat_header.dart';
import 'package:lgbtindernew/widgets/chat/last_seen_widget.dart';
import 'package:lgbtindernew/widgets/chat/typing_indicator.dart';

final _typingFlagProvider = StateProvider<bool>((ref) => false);

void main() {
  testWidgets('TypingIndicator can be disposed before the bounce loop starts',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TypingIndicator())),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dots are 7px primary and bounce vertically', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: TypingIndicator())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    final first = tester.widget<Transform>(
      find.byKey(const ValueKey('chat-typing-dot-0')),
    );
    expect(first.transform.getTranslation().y, lessThan(0));
    expect(
      first.transform.getTranslation().y,
      greaterThanOrEqualTo(-AppAnimations.chatTypingDotBounce),
    );

    final box = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('chat-typing-dot-0')),
    );
    expect(box.size.height, AppAnimations.chatTypingDotSize);

    final decoration = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('chat-typing-dot-0')),
        matching: find.byType(Container),
      ),
    );
    expect(
      (decoration.decoration as BoxDecoration).color,
      AppTheme.lightTheme.colorScheme.primary,
    );
  });

  testWidgets('Reduce Motion keeps static dots at translateY 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(body: Center(child: TypingIndicator())),
      ),
    );
    await tester.pump();
    await tester.pump(AppAnimations.chatTypingDot);

    for (var i = 0; i < 3; i++) {
      final transform = tester.widget<Transform>(
        find.byKey(ValueKey('chat-typing-dot-$i')),
      );
      expect(transform.transform.getTranslation().y, 0);
    }
  });

  testWidgets('LastSeenWidget typing replaces Offline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: LastSeenWidget(),
        ),
      ),
    );
    expect(find.text(ChatPresenceCopy.offline), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: LastSeenWidget(isTyping: true),
        ),
      ),
    );
    expect(find.text(ChatPresenceCopy.isTyping), findsOneWidget);
    expect(find.text(ChatPresenceCopy.offline), findsNothing);
  });

  testWidgets('chat header subtitle shows is typing instead of Offline',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isUserTypingProvider.overrideWith(
            (ref, userId) =>
                userId == 9 && ref.watch(_typingFlagProvider),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChatHeader(
              userId: 9,
              name: 'Alex',
            ),
          ),
        ),
      ),
    );

    expect(find.text(ChatPresenceCopy.offline), findsOneWidget);
    expect(find.text(ChatPresenceCopy.isTyping), findsNothing);
    expect(find.byType(TypingIndicator), findsNothing);

    final context = tester.element(find.byType(ChatHeader));
    ProviderScope.containerOf(context).read(_typingFlagProvider.notifier).state =
        true;
    await tester.pump();
    expect(
      tester.widget<LastSeenWidget>(find.byType(LastSeenWidget)).isTyping,
      isTrue,
    );
    expect(find.text(ChatPresenceCopy.isTyping), findsOneWidget);
    expect(find.byType(TypingIndicator), findsNothing);

    ProviderScope.containerOf(tester.element(find.byType(ChatHeader)))
        .read(_typingFlagProvider.notifier)
        .state = false;
    await tester.pump();
    expect(
      tester.widget<LastSeenWidget>(find.byType(LastSeenWidget)).isTyping,
      isFalse,
    );
    expect(find.byType(TypingIndicator), findsNothing);
  });
}
