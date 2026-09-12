import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';
import 'package:lgbtindernew/widgets/chat/chat_jump_to_bottom_fab.dart';
import 'package:lgbtindernew/widgets/chat/chat_thread_jump_fab_layer.dart';

void main() {
  test('jump FAB is 52px and scrolls to latest in 300ms', () {
    expect(ChatJumpToBottomFab.size, 52);
    expect(ChatThreadScroll.latestPixels, 0);
    expect(
      AppAnimations.chatJumpToBottomScroll,
      const Duration(milliseconds: 300),
    );
  });

  Widget host({
    required bool visible,
    int unseenCount = 0,
    VoidCallback? onPressed,
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
        body: Stack(
          children: [
            ChatJumpToBottomFab(
              visible: visible,
              unseenCount: unseenCount,
              onPressed: onPressed ?? () {},
            ),
          ],
        ),
      ),
    );
  }

  AnimatedScale scaleOf(WidgetTester tester) {
    return tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('chat-jump-to-bottom-scale')),
    );
  }

  testWidgets('scales in 0→1 over 200ms when scrolled up', (tester) async {
    await tester.pumpWidget(host(visible: false));
    expect(scaleOf(tester).scale, 0);
    expect(scaleOf(tester).duration, AppAnimations.chatJumpToBottomOut);

    await tester.pumpWidget(host(visible: true, unseenCount: 3));
    await tester.pump();
    expect(scaleOf(tester).scale, 1);
    expect(scaleOf(tester).duration, AppAnimations.chatJumpToBottomIn);
    expect(find.text('3'), findsOneWidget);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      [AppIcons.arrowDown],
    );
  });

  testWidgets('scales out over 150ms at the bottom', (tester) async {
    await tester.pumpWidget(host(visible: true, unseenCount: 2));
    await tester.pumpWidget(host(visible: false, unseenCount: 0));
    await tester.pump();
    expect(scaleOf(tester).scale, 0);
    expect(scaleOf(tester).duration, AppAnimations.chatJumpToBottomOut);
  });

  testWidgets('Reduce Motion snaps scale with Duration.zero', (tester) async {
    await tester.pumpWidget(host(visible: false, reduceMotion: true));
    await tester.pumpWidget(
      host(visible: true, unseenCount: 1, reduceMotion: true),
    );
    await tester.pump();
    expect(scaleOf(tester).duration, Duration.zero);
    expect(scaleOf(tester).scale, 1);
  });

  testWidgets('tap jumps and 99+ caps the badge', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(visible: true, unseenCount: 120, onPressed: () => taps++),
    );
    expect(find.text('99+'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    expect(taps, 1);

    final box = tester.getSize(find.byType(InkWell));
    expect(box.width, ChatJumpToBottomFab.size);
    expect(box.height, ChatJumpToBottomFab.size);
  });

  testWidgets('layer hides FAB at bottom and badges unseen incoming',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                ChatThreadJumpFabLayer(
                  peerUserId: 7,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(scaleOf(tester).scale, 0);
    expect(find.text('1'), findsNothing);

    container.read(chatThreadViewportProvider(7).notifier).incrementUnseen();
    await tester.pump();
    expect(scaleOf(tester).scale, 1);
    expect(find.text('1'), findsOneWidget);

    container.read(chatThreadViewportProvider(7).notifier).incrementUnseen();
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    container.read(chatThreadViewportProvider(7).notifier).applyScroll(
          showFab: false,
          atBottom: true,
        );
    await tester.pump();
    expect(scaleOf(tester).scale, 0);
    expect(find.text('2'), findsNothing);
  });
}
