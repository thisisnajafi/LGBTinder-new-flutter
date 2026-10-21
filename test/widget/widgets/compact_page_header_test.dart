import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/widgets/compact_page_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHeader(
    WidgetTester tester, {
    required Widget header,
    Size surface = const Size(400, 800),
    TextDirection direction = TextDirection.ltr,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: surface, padding: padding),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(body: header),
          ),
        ),
      ),
    );
  }

  testWidgets('row stays 56–64dp and 16dp off both edges', (tester) async {
    await pumpHeader(
      tester,
      header: const CompactPageHeader(title: 'Discover'),
    );

    final row = tester.getRect(find.byKey(CompactPageHeader.rowKey));
    final card = tester.getRect(find.byKey(CompactPageHeader.cardKey));
    final title = tester.getRect(find.text('Discover'));

    expect(row.height, inInclusiveRange(CompactPageHeader.minHeight, CompactPageHeader.maxHeight));
    expect(card.left, greaterThanOrEqualTo(CompactPageHeader.horizontalMargin));
    expect(card.right, lessThanOrEqualTo(400 - CompactPageHeader.horizontalMargin));
    expect((title.center.dy - row.center.dy).abs(), lessThan(1));
  });

  testWidgets('subtitle is smaller and dropped on a narrow width', (tester) async {
    await pumpHeader(
      tester,
      surface: const Size(320, 800),
      header: const CompactPageHeader(
        title: 'Notifications',
        subtitle: 'Your social activity hub',
      ),
    );

    expect(find.text('Your social activity hub'), findsNothing);
    expect(
      tester.getSize(find.byKey(CompactPageHeader.rowKey)).height,
      CompactPageHeader.minHeight,
    );

    await pumpHeader(
      tester,
      surface: const Size(800, 800),
      header: const CompactPageHeader(
        title: 'Notifications',
        subtitle: 'Your social activity hub',
      ),
    );

    expect(find.text('Your social activity hub'), findsOneWidget);
    final titleSize = tester.getSize(find.text('Notifications'));
    final subtitleSize = tester.getSize(find.text('Your social activity hub'));
    expect(subtitleSize.height, lessThan(titleSize.height));
    expect(
      tester.getSize(find.byKey(CompactPageHeader.rowKey)).height,
      CompactPageHeader.maxHeight,
    );

    final row = tester.getRect(find.byKey(CompactPageHeader.rowKey));
    final title = tester.getRect(find.text('Notifications'));
    final subtitle = tester.getRect(find.text('Your social activity hub'));
    final blockCenter = (title.top + subtitle.bottom) / 2;
    expect((blockCenter - row.center.dy).abs(), lessThan(2));
  });

  testWidgets('action icons are end-aligned with equal gaps', (tester) async {
    await pumpHeader(
      tester,
      header: CompactPageHeader(
        title: 'Discover',
        actions: const [
          SizedBox(key: Key('a'), width: 40, height: 40),
          SizedBox(key: Key('b'), width: 40, height: 40),
          SizedBox(key: Key('c'), width: 40, height: 40),
        ],
      ),
    );

    final rects = [
      tester.getRect(find.byKey(const Key('a'))),
      tester.getRect(find.byKey(const Key('b'))),
      tester.getRect(find.byKey(const Key('c'))),
    ]..sort((a, b) => a.left.compareTo(b.left));

    final gap1 = rects[1].left - rects[0].right;
    final gap2 = rects[2].left - rects[1].right;
    expect(gap1, CompactPageHeader.actionGap);
    expect(gap2, CompactPageHeader.actionGap);

    final card = tester.getRect(find.byKey(CompactPageHeader.cardKey));
    final title = tester.getRect(find.text('Discover'));
    expect(rects.last.right, lessThanOrEqualTo(card.right));
    expect(rects.last.right, greaterThan(title.right));
    expect((rects[0].center.dy - card.center.dy).abs(), lessThan(1));
  });

  testWidgets('RTL keeps the title at the start and actions at the end', (tester) async {
    await pumpHeader(
      tester,
      direction: TextDirection.rtl,
      header: const CompactPageHeader(
        title: 'Messenger',
        actions: [
          SizedBox(key: Key('search'), width: 40, height: 40),
        ],
      ),
    );

    final title = tester.getRect(find.text('Messenger'));
    final action = tester.getRect(find.byKey(const Key('search')));
    final card = tester.getRect(find.byKey(CompactPageHeader.cardKey));

    expect(title.center.dx, greaterThan(action.center.dx));
    expect(title.right, lessThanOrEqualTo(card.right));
    expect(action.left, greaterThanOrEqualTo(card.left));
    expect(card.left, greaterThanOrEqualTo(CompactPageHeader.horizontalMargin));
    expect(card.right, lessThanOrEqualTo(400 - CompactPageHeader.horizontalMargin));
  });

  testWidgets('respects a non-zero top safe area', (tester) async {
    const top = 40.0;
    await pumpHeader(
      tester,
      padding: const EdgeInsets.only(top: top),
      header: const CompactPageHeader(title: 'Discover'),
    );

    final card = tester.getRect(find.byKey(CompactPageHeader.cardKey));
    expect(card.top, greaterThanOrEqualTo(top));
    expect(
      tester.getSize(find.byKey(CompactPageHeader.rowKey)).height,
      CompactPageHeader.minHeight,
    );
  });
}
