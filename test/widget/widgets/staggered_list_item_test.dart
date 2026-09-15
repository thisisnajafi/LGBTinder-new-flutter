import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/staggered_list_item.dart';

void main() {
  testWidgets('Reduce Motion skips stagger AnimatedBuilder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: const StaggeredListItem(
          index: 0,
          animateAppear: true,
          child: Text('Row'),
        ),
      ),
    );

    expect(find.text('Row'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StaggeredListItem),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
  });
}
