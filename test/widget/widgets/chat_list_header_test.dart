import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_header.dart';

void main() {
  testWidgets('ChatListHeader reports search after 300ms', (tester) async {
    final queries = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChatListHeader(
            onSearchChanged: queries.add,
            onFilterTap: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Sam');
    expect(queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 299));
    expect(queries, isEmpty);

    await tester.pump(AppAnimations.searchDebounce);
    expect(queries, ['Sam']);
    expect(find.byType(Icon), findsNothing);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      containsAll([AppIcons.search, AppIcons.filter]),
    );
  });
}
