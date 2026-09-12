import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/chat_send_morph_icon.dart';

void main() {
  Widget host({
    required bool hasText,
    bool isEditing = false,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: reduceMotion
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: Center(
          child: ChatSendMorphIcon(
            hasText: hasText,
            isEditing: isEditing,
            color: AppTheme.lightTheme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  List<String> iconPaths(WidgetTester tester) {
    return tester
        .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
        .map((icon) => icon.assetPath)
        .toList();
  }

  test('send morph uses 180ms easeOutBack', () {
    expect(AppAnimations.chatSendMorph, const Duration(milliseconds: 180));
    expect(AppAnimations.chatSendMorphCurve, Curves.easeOutBack);
    expect(AppAnimations.chatSendMorphScaleBegin, 0.8);
  });

  testWidgets('empty field shows mic; text shows send', (tester) async {
    await tester.pumpWidget(host(hasText: false));
    expect(iconPaths(tester), [AppIcons.microphone]);

    await tester.pumpWidget(host(hasText: true));
    await tester.pump();
    expect(iconPaths(tester), contains(AppIcons.send));

    await tester.pumpAndSettle();
    expect(iconPaths(tester), [AppIcons.send]);
  });

  testWidgets('morph fades and scales over 180ms', (tester) async {
    await tester.pumpWidget(host(hasText: false));
    await tester.pumpWidget(host(hasText: true));
    await tester.pump();

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      AppAnimations.chatSendMorph,
    );
    expect(
      find.descendant(
        of: find.byType(ChatSendMorphIcon),
        matching: find.byType(FadeTransition),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(ChatSendMorphIcon),
        matching: find.byType(ScaleTransition),
      ),
      findsWidgets,
    );

    await tester.pumpAndSettle();
    expect(iconPaths(tester), [AppIcons.send]);
  });

  testWidgets('Reduce Motion swaps instantly without scale or fade',
      (tester) async {
    await tester.pumpWidget(host(hasText: false, reduceMotion: true));
    await tester.pumpWidget(host(hasText: true, reduceMotion: true));
    await tester.pump();

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(
      find.descendant(
        of: find.byType(ChatSendMorphIcon),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ChatSendMorphIcon),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(iconPaths(tester), [AppIcons.send]);
  });

  testWidgets('edit mode morphs send to the check SVG', (tester) async {
    await tester.pumpWidget(host(hasText: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(hasText: true, isEditing: true));
    await tester.pumpAndSettle();
    expect(iconPaths(tester), [AppIcons.tickCircle]);
  });
}
