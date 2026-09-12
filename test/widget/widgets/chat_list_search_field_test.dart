import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_empty.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_search_field.dart';

void main() {
  test('search empty copy is distinct from the inbox empty copy', () {
    expect(ChatListEmpty.titleFor(''), ChatListEmpty.noneTitle);
    expect(ChatListEmpty.titleFor('alex'), ChatListEmpty.searchTitle);
    expect(ChatListEmpty.searchTitle, 'No conversations found');
    expect(ChatListEmpty.showsDiscoverCta(''), isTrue);
    expect(ChatListEmpty.showsDiscoverCta('alex'), isFalse);
    expect(ChatListEmpty.discoverLabel, 'Discover People');
  });

  testWidgets('search field height is 56 when open and 0 when closed',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var closed = 0;
    var query = '';
    var submitted = '';

    Widget host({required bool visible}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatListSearchField(
            visible: visible,
            controller: controller,
            hintText: 'Search conversations...',
            onChanged: (value) => query = value,
            onSubmitted: (value) => submitted = value,
            onClose: () => closed++,
          ),
        ),
      );
    }

    await tester.pumpWidget(host(visible: false));
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-list-search-field'))).height,
      0,
    );

    await tester.pumpWidget(host(visible: true));
    await tester.pump();
    await tester.pump(AppAnimations.chatSearchField);
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-list-search-field'))).height,
      AppAnimations.chatSearchFieldHeight,
    );
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('chat-list-search-field')),
          )
          .duration,
      AppAnimations.chatSearchField,
    );
    expect(find.byType(Icon), findsNothing);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      contains(AppIcons.close),
    );

    await tester.enterText(find.byType(TextField), 'Sam');
    expect(query, isEmpty);
    await tester.pump(AppAnimations.searchDebounce);
    expect(query, 'Sam');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, 'Sam');

    await tester.tap(find.byTooltip('Close search'));
    expect(closed, 1);
  });

  testWidgets('Reduce Motion snaps the search field with Duration.zero',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Scaffold(
          body: ChatListSearchField(
            visible: true,
            controller: controller,
            hintText: 'Search conversations...',
            onChanged: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('chat-list-search-field')),
          )
          .duration,
      Duration.zero,
    );
  });
}
