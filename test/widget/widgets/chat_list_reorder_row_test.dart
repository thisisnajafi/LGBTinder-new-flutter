import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/utils/chat_list_reorder.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_reorder_row.dart';

void main() {
  Widget host({
    required List<int> ids,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      builder: disableAnimations
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: ChatListReorderList(
          itemCount: ids.length,
          itemIdAt: (index) => ids[index],
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) => SizedBox(
            height: 52,
            child: Text('row-${ids[index]}'),
          ),
        ),
      ),
    );
  }

  Offset slideOffset(WidgetTester tester, int id) {
    final transform = tester.widget<Transform>(
      find.byKey(ValueKey('chat-list-reorder-slide-$id')),
    );
    final translation = transform.transform.getTranslation();
    return Offset(translation.x, translation.y);
  }

  testWidgets('promoting a row slides it from its old slot then settles',
      (tester) async {
    await tester.pumpWidget(host(ids: const [1, 2, 3]));
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(host(ids: const [3, 1, 2]));
    await tester.pump();

    expect(slideOffset(tester, 3).dy, ChatListReorder.rowStride * 2);

    await tester.pump(AppAnimations.chatListReorder);
    expect(slideOffset(tester, 3).dy, 0);
  });

  testWidgets('Reduce Motion jumps without a slide', (tester) async {
    await tester.pumpWidget(
      host(ids: const [1, 2, 3], disableAnimations: true),
    );
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(
      host(ids: const [3, 1, 2], disableAnimations: true),
    );
    await tester.pump();

    expect(slideOffset(tester, 3).dy, 0);
  });

  testWidgets('first hydrate does not slide rows', (tester) async {
    await tester.pumpWidget(host(ids: const [1, 2, 3]));
    await tester.pump();

    expect(slideOffset(tester, 1).dy, 0);
    expect(slideOffset(tester, 2).dy, 0);
    expect(slideOffset(tester, 3).dy, 0);
  });
}
