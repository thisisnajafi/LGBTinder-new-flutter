import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/premium/premium_layout.dart';
import 'package:lgbtindernew/widgets/chat/chat_thread_list_view.dart';

void main() {
  testWidgets('chat thread list is a builder without keep-alives', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatThreadListView(
            itemCount: 200,
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

    expect(list.reverse, isTrue);
    expect(delegate.addAutomaticKeepAlives, isFalse);
    expect(delegate.addRepaintBoundaries, isTrue);
    expect(
      list.scrollCacheExtent?.value,
      AppScroll.chatThreadCacheExtentPixels,
    );
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
    expect(find.text('row 199'), findsNothing);

    await tester.fling(find.byType(ListView), const Offset(0, 4000), 4000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('android chat thread uses clamping physics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: ChatListView(
            itemCount: 4,
            itemBuilder: (context, index) => Text('row $index'),
          ),
        ),
      ),
    );

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.reverse, isTrue);
    expect(
      (list.physics as AlwaysScrollableScrollPhysics).parent,
      isA<ClampingScrollPhysics>(),
    );
  });

  testWidgets('iOS chat thread uses bouncing physics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: ChatThreadListView(
            itemCount: 4,
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
