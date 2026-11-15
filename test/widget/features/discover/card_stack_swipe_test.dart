// Discover card stack: drag feedback, spring-back, commit, button exits and
// Reduce Motion. Cards have no photos, so nothing touches the network.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/cards/card_stack_manager.dart';
import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';

import 'discover_test_host.dart';

const Size _phone = Size(390, 844);

/// 22 % of the screen width, as in the stack.
const double _threshold = 390 * 0.22;

Map<String, dynamic> _card(int id) => <String, dynamic>{
      'id': id,
      'name': 'Person $id',
      'age': 20 + id,
      'bio': '',
    };

class _Harness {
  final swipes = <(int, String)>[];
  final sheetRequests = <bool>[];
  final stackKey = GlobalKey<CardStackManagerState>();
  List<Map<String, dynamic>> cards = [_card(1), _card(2), _card(3)];

  Widget build() {
    return CardStackManager(
      key: stackKey,
      cards: cards,
      onSwipe: (id, action) => swipes.add((id, action)),
      onSheetOpenChanged: sheetRequests.add,
      carouselEnabled: false,
    );
  }

  Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) async {
    await pumpDiscoverHost(
      tester,
      build(),
      surface: _phone,
      reduceMotion: reduceMotion,
    );
    // Photo prefetch (nothing to fetch) and the reveal animation.
    await tester.pumpAndSettle();
  }
}

/// The front card is painted last.
Finder get _frontCard => find.byType(SwipeableCard).last;

int _frontId(WidgetTester tester) =>
    tester.widget<SwipeableCard>(_frontCard).userId;

double _stamp(WidgetTester tester, Key key) =>
    tester.widget<FadeTransition>(find.byKey(key)).opacity.value;

/// Starts a pan on the front card and moves it by [delta] past the touch
/// slop. Returns the gesture, still down.
Future<TestGesture> _dragBy(WidgetTester tester, Offset delta) async {
  final gesture = await tester.startGesture(tester.getCenter(_frontCard));
  // First move only wins the gesture arena; it is not applied to the card.
  final slop = Offset(delta.dx.sign * 20, delta.dy.sign * 20);
  await gesture.moveBy(slop);
  await tester.pump();
  // Then in steps, like a finger.
  const steps = 4;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(delta / steps.toDouble());
    await tester.pump();
  }
  return gesture;
}

void main() {
  group('drag feedback', () {
    testWidgets('dragging right fades in LIKE, tilts and moves the card',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final rest = tester.getCenter(_frontCard);

      final gesture = await _dragBy(tester, const Offset(50, 0));

      final like = _stamp(tester, CardStackManager.likeStampKey);
      expect(like, greaterThan(0));
      expect(like, lessThan(1), reason: 'follows the drag, not all-or-nothing');
      expect(_stamp(tester, CardStackManager.nopeStampKey), 0);
      expect(_stamp(tester, CardStackManager.superStampKey), 0);
      expect(tester.getCenter(_frontCard).dx, greaterThan(rest.dx + 30));
      // Rides a shallow arc upwards.
      expect(tester.getCenter(_frontCard).dy, lessThan(rest.dy));
      expect(h.swipes, isEmpty);

      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(
        _stamp(tester, CardStackManager.likeStampKey),
        1,
        reason: 'full strength well before the commit distance',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('dragging left fades in NOPE only', (tester) async {
      final h = _Harness();
      await h.pump(tester);

      final gesture = await _dragBy(tester, const Offset(-50, 0));

      expect(_stamp(tester, CardStackManager.nopeStampKey), greaterThan(0));
      expect(_stamp(tester, CardStackManager.likeStampKey), 0);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the next card grows towards the front during the drag',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);
      // Painted order: third, second, front.
      final second = find.byType(SwipeableCard).at(1);
      final before = tester.getRect(second);

      final gesture = await _dragBy(tester, const Offset(_threshold, 0));
      final during = tester.getRect(second);

      expect(during.width, greaterThan(before.width + 4));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a drag does not rebuild the cards', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final before = tester.widgetList<SwipeableCard>(
        find.byType(SwipeableCard),
      ).toList();

      final gesture = await _dragBy(tester, const Offset(60, 0));

      final during = tester.widgetList<SwipeableCard>(
        find.byType(SwipeableCard),
      ).toList();
      // Same widget instances: the stack did not run build() for the drag.
      expect(during.length, before.length);
      for (var i = 0; i < before.length; i++) {
        expect(identical(during[i], before[i]), isTrue, reason: 'card $i');
      }

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('release', () {
    testWidgets('below the commit distance the card springs back',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final rest = tester.getCenter(_frontCard);

      final gesture = await _dragBy(tester, const Offset(50, 0));
      final released = tester.getCenter(_frontCard);
      await gesture.up();

      // Not a snap: one frame later it is on its way, not home yet.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final midway = tester.getCenter(_frontCard).dx;
      expect(midway, lessThan(released.dx));
      expect(midway, greaterThan(rest.dx));

      await tester.pumpAndSettle();
      expect(tester.getCenter(_frontCard), rest);
      expect(_stamp(tester, CardStackManager.likeStampKey), 0);
      expect(h.swipes, isEmpty);
      expect(_frontId(tester), 1);
    });

    testWidgets('past the commit distance it likes once and flies on',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);

      final gesture = await _dragBy(tester, const Offset(_threshold + 20, 0));
      final released = tester.getCenter(_frontCard).dx;
      await gesture.up();
      await tester.pump();

      expect(h.swipes, [(1, 'like')]);
      // The fly-out starts where the finger left the card. It must never
      // jump back to the centre first.
      final exiting = find.byKey(const ValueKey<String>('exiting_1'));
      expect(exiting, findsOneWidget);
      final flying = find.descendant(
        of: exiting,
        matching: find.byType(SwipeableCard),
      );
      expect(tester.getCenter(flying).dx, greaterThanOrEqualTo(released - 1));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getCenter(flying).dx, greaterThan(released));
      expect(_stamp(tester, CardStackManager.likeStampKey), 1);

      // The page removes the liked profile; the next card is the front one.
      h.cards = [_card(2), _card(3)];
      await pumpDiscoverHost(tester, h.build(), surface: _phone);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('exiting_1')), findsNothing);
      expect(_frontId(tester), 2);
      expect(h.swipes, hasLength(1));
      expect(_stamp(tester, CardStackManager.likeStampKey), 0);
    });

    testWidgets('past the commit distance to the left it passes',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);

      final gesture = await _dragBy(tester, const Offset(-_threshold - 20, 0));
      await gesture.up();
      await tester.pump();

      expect(h.swipes, [(1, 'dislike')]);
      expect(_stamp(tester, CardStackManager.nopeStampKey), 1);
      await tester.pumpAndSettle();
    });

    testWidgets('a quick flick commits even when the drag was short',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);

      await tester.fling(_frontCard, const Offset(60, 0), 2000);
      await tester.pump();

      expect(h.swipes, [(1, 'like')]);
      await tester.pumpAndSettle();
    });

    testWidgets('dragging up asks for the profile sheet and settles back',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final rest = tester.getCenter(_frontCard);

      final gesture = await _dragBy(tester, const Offset(0, -100));
      // Vertical lane: no sideways movement, no stamps.
      expect(tester.getCenter(_frontCard).dx, rest.dx);
      expect(_stamp(tester, CardStackManager.likeStampKey), 0);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(h.sheetRequests, [true]);
      expect(h.swipes, isEmpty);
      expect(tester.getCenter(_frontCard), rest);
    });
  });

  group('button-driven exits', () {
    testWidgets('beginSwipeExit plays the stamp and fly-out, reports nothing',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final rest = tester.getCenter(_frontCard).dx;

      h.stackKey.currentState!.beginSwipeExit('dislike');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final exiting = find.byKey(const ValueKey<String>('exiting_1'));
      expect(exiting, findsOneWidget);
      expect(
        tester
            .getCenter(
              find.descendant(of: exiting, matching: find.byType(SwipeableCard)),
            )
            .dx,
        lessThan(rest),
      );
      expect(_stamp(tester, CardStackManager.nopeStampKey), greaterThan(0));
      // The caller records the swipe; the stack must not report it twice.
      expect(h.swipes, isEmpty);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('exiting_1')), findsNothing);
    });

    testWidgets('beginSuperlikeExit sends the card up with SUPER',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final rest = tester.getCenter(_frontCard).dy;

      h.stackKey.currentState!.beginSuperlikeExit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final exiting = find.byKey(const ValueKey<String>('exiting_1'));
      expect(
        tester
            .getCenter(
              find.descendant(of: exiting, matching: find.byType(SwipeableCard)),
            )
            .dy,
        lessThan(rest),
      );
      expect(_stamp(tester, CardStackManager.superStampKey), greaterThan(0));
      expect(_stamp(tester, CardStackManager.likeStampKey), 0);
      await tester.pumpAndSettle();
    });

    testWidgets('unknown actions are ignored', (tester) async {
      final h = _Harness();
      await h.pump(tester);

      h.stackKey.currentState!.beginSwipeExit('superlike');
      await tester.pump();

      expect(find.byKey(const ValueKey<String>('exiting_1')), findsNothing);
    });
  });

  group('Reduce Motion', () {
    testWidgets('a short drag snaps back at once, no spring', (tester) async {
      final h = _Harness();
      await h.pump(tester, reduceMotion: true);
      final rest = tester.getCenter(_frontCard);

      final gesture = await _dragBy(tester, const Offset(50, 0));
      // Stamps still follow the finger: feedback, not motion.
      expect(_stamp(tester, CardStackManager.likeStampKey), greaterThan(0));
      await gesture.up();
      await tester.pump();

      expect(tester.getCenter(_frontCard), rest);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a committed swipe is reported without a fly-out',
        (tester) async {
      final h = _Harness();
      await h.pump(tester, reduceMotion: true);

      final gesture = await _dragBy(tester, const Offset(_threshold + 20, 0));
      await gesture.up();
      await tester.pump();

      expect(h.swipes, [(1, 'like')]);
      expect(find.byKey(const ValueKey<String>('exiting_1')), findsNothing);
      expect(_stamp(tester, CardStackManager.likeStampKey), 0);
    });

    testWidgets('the cards behind stay still during a drag', (tester) async {
      final h = _Harness();
      await h.pump(tester, reduceMotion: true);
      final second = find.byType(SwipeableCard).at(1);
      final before = tester.getRect(second);

      final gesture = await _dragBy(tester, const Offset(_threshold, 0));

      expect(tester.getRect(second), before);
      await gesture.up();
      await tester.pump();
    });
  });

  group('layout', () {
    testWidgets('small phone, RTL, 1.3x text: no overflow, swipe still works',
        (tester) async {
      final h = _Harness();
      await pumpDiscoverHost(
        tester,
        h.build(),
        textScale: 1.3,
        direction: TextDirection.rtl,
      );
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);

      // Swipe directions are physical: right is still "like" in RTL.
      await tester.fling(_frontCard, const Offset(60, 0), 2000);
      await tester.pump();
      expect(h.swipes, [(1, 'like')]);
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);
    });
  });

  group('performance guards (source)', () {
    String read(String path) => File(path).readAsStringSync();

    test('the card stack keeps drag frames off setState and Opacity', () {
      final source = read('lib/widgets/cards/card_stack_manager.dart');

      final panUpdate = source.substring(
        source.indexOf('void _onPanUpdate('),
        source.indexOf('void _onPanEnd('),
      );
      expect(panUpdate, isNot(contains('setState')));
      expect(panUpdate, contains('_drag.value = next'));

      // Fades go through FadeTransition; no Opacity widget, no blur.
      expect(RegExp(r'\bOpacity\(').hasMatch(source), isFalse);
      expect(source, isNot(contains('BackdropFilter')));
      expect(source, isNot(contains('ImageFiltered')));
      // Haptics honour the user's setting.
      expect(source, isNot(contains('HapticFeedback.')));
      expect(source, contains('AppHaptics.'));
    });

    test('the card has no leaking recognizer and no broad MediaQuery lookup',
        () {
      final source = read('lib/widgets/cards/swipeable_card.dart');

      expect(source, isNot(contains('TapGestureRecognizer')));
      expect(source, isNot(contains('MediaQuery.of(context)')));
      expect(source, isNot(contains('BackdropFilter')));
      expect(source, contains('precacheCardPhoto'));
    });

    test('the page isolates the stack and never blurs over the card', () {
      final source = read('lib/pages/discovery_page.dart');

      expect(source, isNot(contains('BackdropFilter')));
      expect(source, isNot(contains('ImageFiltered')));
      expect(
        RegExp(r'RepaintBoundary\(\s*child: CardStackManager\(')
            .hasMatch(source),
        isTrue,
      );
      // Off-tab pause of the photo carousel is still wired.
      expect(source, contains('carouselEnabled:'));
      // The next cards are decoded at the size the card shows them.
      expect(source, contains('SwipeableCard.photoDecodeWidth(context)'));
    });
  });
}
