import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/core/widgets/app_action_bottom_sheet.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_message_sheet_actions.dart';
import 'package:lgbtindernew/widgets/chat/chat_message_context_menu.dart';
import 'package:lgbtindernew/widgets/chat/chat_message_list_tile.dart';

void main() {
  test('bubble lift scale is 1.05', () {
    expect(AppAnimations.chatContextMenuBubbleScale, 1.05);
    expect(AppAnimations.chatContextMenuBlur, 3);
  });

  test('sent menus grow left of the press; received grow to the right', () {
    const screen = Size(400, 800);
    const padding = EdgeInsets.all(12);
    const height = 200.0;
    final sent = ChatMessageContextMenu.clampOrigin(
      screen: screen,
      anchor: const Offset(360, 500),
      isSent: true,
      menuHeight: height,
      padding: padding,
    );
    expect(sent.dx, 360 - ChatMessageContextMenu.menuWidth);

    final received = ChatMessageContextMenu.clampOrigin(
      screen: screen,
      anchor: const Offset(40, 500),
      isSent: false,
      menuHeight: height,
      padding: padding,
    );
    expect(received.dx, 40);
  });

  test('origin stays inside the padded screen', () {
    const screen = Size(400, 800);
    const padding = EdgeInsets.all(12);
    final origin = ChatMessageContextMenu.clampOrigin(
      screen: screen,
      anchor: const Offset(10, 10),
      isSent: true,
      menuHeight: 400,
      padding: padding,
    );
    expect(origin.dx, greaterThanOrEqualTo(padding.left));
    expect(origin.dy, greaterThanOrEqualTo(padding.top));
    expect(
      origin.dx + ChatMessageContextMenu.menuWidth,
      lessThanOrEqualTo(screen.width - padding.right),
    );
  });

  testWidgets('own message menu shows Reply Copy Edit Pin Delete and reacts',
      (tester) async {
    await _openMenu(
      tester,
      isSent: true,
      showReact: true,
      actions: [
        _item('Reply', AppIcons.reply),
        _item('Copy', AppIcons.copy),
        _item('Edit', AppIcons.edit2),
        _item('Pin', AppIcons.bookmark),
        _item('Delete', AppIcons.delete),
      ],
    );

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Pin'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Report'), findsNothing);
    for (final emoji in ChatMessageSheetActions.reactEmojis) {
      expect(find.text(emoji), findsOneWidget);
    }
    expect(find.byType(AppSvgIcon), findsNWidgets(5));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('incoming menu shows Reply Copy Report, not Delete',
      (tester) async {
    await _openMenu(
      tester,
      isSent: false,
      showReact: true,
      actions: [
        _item('Reply', AppIcons.reply),
        _item('Copy', AppIcons.copy),
        _item('Report', AppIcons.flag),
      ],
    );

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('outside tap reverse-animates then dismisses', (tester) async {
    await _openMenu(
      tester,
      isSent: true,
      actions: [_item('Reply', AppIcons.reply)],
    );
    expect(find.text('Reply'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(find.text('Reply'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing);
  });

  testWidgets('Reduce Motion still shows the menu without blur',
      (tester) async {
    await _openMenu(
      tester,
      isSent: true,
      reduceMotion: true,
      actions: [_item('Reply', AppIcons.reply)],
    );
    expect(find.text('Reply'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('long-press lifts the bubble to 1.05 until the menu closes',
      (tester) async {
    final hold = Completer<void>();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: ChatMessageListTile(
                peerUserId: 7,
                rowKey: 'c-c1',
                onLongPress: (message, {at}) => hold.future,
              ),
            ),
          ),
        ),
      ),
    );
    container.read(chatThreadMessagesProvider(7).notifier).setRows([
      {
        'id': 1,
        'client_id': 'c1',
        'text': 'hi',
        'is_sent': false,
        'type': 'text',
      },
    ]);
    await tester.pump();

    AnimatedScale scaleOf() {
      return tester.widget<AnimatedScale>(
        find.byKey(const ValueKey('chat-context-menu-bubble-scale')),
      );
    }

    expect(scaleOf().scale, 1);

    await tester.longPress(find.text('hi'));
    await tester.pump();
    expect(scaleOf().scale, AppAnimations.chatContextMenuBubbleScale);
    expect(find.byType(Icon), findsNothing);

    hold.complete();
    await tester.pump();
    await tester.pump();
    expect(scaleOf().scale, 1);
  });
}

AppActionSheetItem _item(String label, String iconPath) {
  return AppActionSheetItem(
    iconPath: iconPath,
    label: label,
    onTap: () {},
  );
}

Future<void> _openMenu(
  WidgetTester tester, {
  required bool isSent,
  required List<AppActionSheetItem> actions,
  bool showReact = false,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                ChatMessageContextMenu.show(
                  context: context,
                  anchor: const Offset(200, 400),
                  isSent: isSent,
                  actions: actions,
                  showReact: showReact,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
