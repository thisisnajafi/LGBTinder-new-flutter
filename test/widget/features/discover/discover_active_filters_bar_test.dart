import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_active_filters_bar.dart';

void main() {
  Widget host({
    required List<String> labels,
    VoidCallback? onEdit,
    VoidCallback? onClear,
    bool reduceMotion = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: DiscoverActiveFiltersBar(
            labels: labels,
            onEdit: onEdit ?? () {},
            onClear: onClear ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('hidden bar is 0px then opens over 250ms', (tester) async {
    var labels = <String>[];
    late void Function(void Function()) setLabels;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setLabels = setState;
              return DiscoverActiveFiltersBar(
                labels: labels,
                onEdit: () {},
                onClear: () {},
              );
            },
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(DiscoverActiveFiltersBar.barKey)).height,
      0,
    );

    setLabels(() => labels = ['25km', 'Online']);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    final mid =
        tester.getSize(find.byKey(DiscoverActiveFiltersBar.barKey)).height;
    expect(mid, greaterThan(0));

    await tester.pump(AppAnimations.transitionModal);
    expect(find.text('25km'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(AppSvgIcon), findsWidgets);
    expect(
      tester.getSize(find.byKey(DiscoverActiveFiltersBar.barKey)).height,
      greaterThan(mid),
    );

    setLabels(() => labels = []);
    await tester.pump();
    await tester.pump(AppAnimations.transitionModal);
    expect(
      tester.getSize(find.byKey(DiscoverActiveFiltersBar.barKey)).height,
      0,
    );
  });

  testWidgets('Edit uses primary fill; Clear and Edit fire callbacks',
      (tester) async {
    var edits = 0;
    var clears = 0;
    await tester.pumpWidget(
      host(
        labels: const ['Verified'],
        onEdit: () => edits++,
        onClear: () => clears++,
      ),
    );
    await tester.pumpAndSettle();

    final editText = tester.widget<Text>(find.text('Edit'));
    expect(editText.style?.color, AppTheme.lightTheme.colorScheme.onPrimary);

    await tester.tap(find.text('Edit'));
    await tester.tap(find.text('Clear'));
    expect(edits, 1);
    expect(clears, 1);
  });

  testWidgets('Reduce Motion skips the height animation', (tester) async {
    await tester.pumpWidget(
      host(labels: const ['25km'], reduceMotion: true),
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(DiscoverActiveFiltersBar.barKey)).height,
      greaterThan(0),
    );
    expect(find.text('25km'), findsOneWidget);
  });
}
