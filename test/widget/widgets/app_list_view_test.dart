import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/app_list_view.dart';
import 'package:lgbtindernew/core/widgets/premium/premium_layout.dart';

void main() {
  testWidgets('AppListView uses 400px cache, keep-alives off, repaint on',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: AppListView.builder(
            itemCount: 80,
            itemBuilder: (context, index) => SizedBox(
              height: 48,
              child: Text('row $index'),
            ),
          ),
        ),
      ),
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    final delegate = list.childrenDelegate as SliverChildBuilderDelegate;

    expect(delegate.addAutomaticKeepAlives, isFalse);
    expect(delegate.addRepaintBoundaries, isTrue);
    expect(list.scrollCacheExtent?.value, AppListView.cacheExtentPixels);
    expect(list.scrollCacheExtent?.value, AppScroll.listCacheExtentPixels);
    expect(
      (list.physics as AlwaysScrollableScrollPhysics).parent,
      isA<ClampingScrollPhysics>(),
    );
  });

  testWidgets('AppListView bounces on iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: AppListView.separated(
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) => Text('row $index'),
          ),
        ),
      ),
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(
      (list.physics as AlwaysScrollableScrollPhysics).parent,
      isA<BouncingScrollPhysics>(),
    );
  });
}
