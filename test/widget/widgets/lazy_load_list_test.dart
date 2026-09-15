import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/premium/premium_layout.dart';
import 'package:lgbtindernew/shared/widgets/lazy_load_list.dart';

void main() {
  testWidgets('LazyLoadList uses AppListView cacheExtent', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: LazyLoadList<int>(
              items: List<int>.generate(40, (i) => i),
              itemBuilder: (context, item, index) => SizedBox(
                height: 48,
                child: Text('row $item'),
              ),
            ),
          ),
        ),
      ),
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollCacheExtent?.value, AppScroll.listCacheExtentPixels);
  });

  testWidgets('LazyLoadGrid uses sliver cacheExtent', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LazyLoadGrid<int>(
              items: List<int>.generate(8, (i) => i),
              itemBuilder: (context, item, index) => Text('cell $item'),
            ),
          ),
        ),
      ),
    );

    final scroll = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    expect(scroll.scrollCacheExtent?.value, AppScroll.listCacheExtentPixels);
  });

  testWidgets('LazyLoadItem renders child without a visibility detector',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LazyLoadItem(child: Text('ready')),
      ),
    );

    expect(find.text('ready'), findsOneWidget);
    expect(find.byType(NotificationListener<ScrollNotification>), findsNothing);
  });
}
