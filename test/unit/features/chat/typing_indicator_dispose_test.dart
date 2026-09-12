import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/providers/chat_typing_providers.dart';
import 'package:lgbtindernew/widgets/chat/chat_peer_typing_indicator.dart';
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

  testWidgets('peer typing switcher shows then hides only the indicator',
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
            body: ChatPeerTypingIndicator(
              peerUserId: 9,
              displayName: 'Alex',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TypingIndicator), findsNothing);

    final context = tester.element(find.byType(ChatPeerTypingIndicator));
    ProviderScope.containerOf(context).read(_typingFlagProvider.notifier).state =
        true;
    await tester.pump();
    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('Alex is typing'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsOneWidget);

    ProviderScope.containerOf(tester.element(find.byType(ChatPeerTypingIndicator)))
        .read(_typingFlagProvider.notifier)
        .state = false;
    await tester.pump();
    await tester.pump(AppAnimations.chatTypingExit);
    expect(find.byType(TypingIndicator), findsNothing);
  });
}
