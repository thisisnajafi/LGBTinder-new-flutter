import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/core/widgets/debounced_search_field.dart';

void main() {
  testWidgets('DebouncedSearchField reports onChanged after 300ms',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final queries = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DebouncedSearchField(
            controller: controller,
            hintText: 'Search people...',
            onChanged: queries.add,
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
      containsAll([AppIcons.search, AppIcons.close]),
    );
  });

  testWidgets('clearing the field emits immediately', (tester) async {
    final controller = TextEditingController(text: 'Sam');
    addTearDown(controller.dispose);
    final queries = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DebouncedSearchField(
            controller: controller,
            hintText: 'Search people...',
            onChanged: queries.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(queries, ['']);
    expect(controller.text, isEmpty);
  });

  testWidgets('submit flushes the pending query', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final queries = <String>[];
    var submitted = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DebouncedSearchField(
            controller: controller,
            hintText: 'Search people...',
            onChanged: queries.add,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(queries, ['Alex']);
    expect(submitted, 'Alex');
  });
}
