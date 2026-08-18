import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/cards/card_stack_manager.dart';
import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';

void main() {
  group('discoverCardWasVisibleInStack', () {
    final cards = [
      {'id': 1},
      {'id': 2},
      {'id': 3},
      {'id': 4},
    ];

    test('is true for cards already painted behind the front card', () {
      expect(discoverCardWasVisibleInStack(2, cards), isTrue);
      expect(discoverCardWasVisibleInStack(3, cards), isTrue);
    });

    test('is false for the next unseen card and missing ids', () {
      expect(discoverCardWasVisibleInStack(4, cards), isFalse);
      expect(discoverCardWasVisibleInStack(99, cards), isFalse);
      expect(discoverCardWasVisibleInStack(null, cards), isFalse);
    });
  });

  group('SwipeableCard.photoDecodeWidth', () {
    testWidgets('uses the same decode size for every card in the stack',
        (tester) async {
      late int frontWidth;
      late int backWidth;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800), devicePixelRatio: 2),
          child: Builder(
            builder: (context) {
              frontWidth = SwipeableCard.photoDecodeWidth(context);
              backWidth = SwipeableCard.photoDecodeWidth(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(frontWidth, backWidth);
      expect(frontWidth, 800);
    });
  });
}
