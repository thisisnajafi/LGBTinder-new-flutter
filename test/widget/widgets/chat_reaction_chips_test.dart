import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/theme/typography.dart';
import 'package:lgbtindernew/widgets/chat/chat_reaction_chips.dart';

void main() {
  testWidgets('renders count chips for both sides without Material Icons',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              ChatReactionChips(
                counts: {'❤️': 2, '👍': 1},
                mine: '❤️',
                isSent: true,
              ),
              ChatReactionChips(
                counts: {'😂': 1},
                isSent: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('❤️ 2'), findsOneWidget);
    expect(find.text('👍 1'), findsOneWidget);
    expect(find.text('😂 1'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(ScaleTransition), findsWidgets);

    final label = tester.widget<Text>(find.text('❤️ 2'));
    expect(label.style?.fontSize, AppTypography.labelSmall.fontSize);
  });

  testWidgets('tapping a chip reports the emoji', (tester) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatReactionChips(
            counts: const {'😮': 1},
            onTap: (emoji) => tapped = emoji,
          ),
        ),
      ),
    );

    await tester.tap(find.text('😮 1'));
    expect(tapped, '😮');
  });

  testWidgets('chips pop with easeOutBack and skip motion when reduced',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const Scaffold(
          body: ChatReactionChips(counts: {'👍': 1}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('👍 1'), findsOneWidget);
    final pop = find.byKey(const ValueKey('chat-reaction-pop-👍'));
    expect(pop, findsOneWidget);
    expect(tester.widget<ScaleTransition>(pop).scale.value, 1);
  });
}
