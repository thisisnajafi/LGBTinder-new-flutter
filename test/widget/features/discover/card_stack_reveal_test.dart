// Discover card stack: when the front card stops being a skeleton.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/discover/utils/discovery_image_prefetch.dart';
import 'package:lgbtindernew/widgets/cards/card_stack_manager.dart';
import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';

import 'discover_test_host.dart';

const Size _phone = Size(390, 844);

Map<String, dynamic> _card(int id, {int photos = 0}) => <String, dynamic>{
      'id': id,
      'name': 'Person $id',
      'age': 20 + id,
      'bio': '',
      if (photos > 0)
        'image_urls': [
          for (var i = 0; i < photos; i++) 'https://example.com/$id-$i.jpg',
        ],
    };

bool _frontCardShown(WidgetTester tester, int id) => tester
    .widgetList<SwipeableCard>(find.byType(SwipeableCard))
    .any((card) => card.userId == id);

void main() {
  final requested = <String>[];
  late Map<String, Completer<void>> pending;

  setUp(() {
    requested.clear();
    pending = <String, Completer<void>>{};
    DiscoveryImagePrefetch.debugFetch = (url) {
      requested.add(url);
      return pending.putIfAbsent(url, Completer<void>.new).future;
    };
  });

  tearDown(() {
    DiscoveryImagePrefetch.debugFetch = null;
  });

  Future<void> pumpStack(
    WidgetTester tester,
    List<Map<String, dynamic>> cards,
  ) async {
    await pumpDiscoverHost(
      tester,
      CardStackManager(cards: cards, carouselEnabled: false),
      surface: _phone,
      reduceMotion: true,
    );
    await tester.pump();
  }

  test('frontPhotoUrl is the first photo of the first card', () {
    expect(DiscoveryImagePrefetch.frontPhotoUrl(const []), isNull);
    expect(DiscoveryImagePrefetch.frontPhotoUrl([_card(1)]), isNull);
    expect(
      DiscoveryImagePrefetch.frontPhotoUrl([
        _card(1, photos: 3),
        _card(2, photos: 1),
      ]),
      'https://example.com/1-0.jpg',
    );
  });

  testWidgets('a card without photos is shown at once', (tester) async {
    await pumpStack(tester, [_card(1), _card(2)]);

    expect(_frontCardShown(tester, 1), isTrue);
    expect(requested, isEmpty);
  });

  testWidgets('the front card waits for its first photo only', (tester) async {
    await pumpStack(tester, [_card(1, photos: 3), _card(2, photos: 2)]);

    expect(_frontCardShown(tester, 1), isFalse, reason: 'skeleton first');
    expect(requested, ['https://example.com/1-0.jpg']);

    pending['https://example.com/1-0.jpg']!.complete();
    await tester.pump();
    await tester.pump();

    // Shown, although photos 2 and 3 and the next card are still loading.
    expect(_frontCardShown(tester, 1), isTrue);
    expect(pending['https://example.com/1-1.jpg']?.isCompleted, isNot(true));

    // The rest follows in the background, front card first.
    for (final url in const [
      'https://example.com/1-1.jpg',
      'https://example.com/1-2.jpg',
      'https://example.com/2-0.jpg',
    ]) {
      for (var i = 0; i < 4 && !pending.containsKey(url); i++) {
        await tester.pump();
      }
      expect(pending.containsKey(url), isTrue, reason: url);
      pending[url]!.complete();
      await tester.pump();
    }
    expect(
      requested,
      isNot(contains('https://example.com/2-1.jpg')),
      reason: 'only the first photo of a card behind is warmed',
    );
  });

  testWidgets('a photo that never arrives does not hold the card back',
      (tester) async {
    await pumpStack(tester, [_card(1, photos: 1), _card(2)]);
    expect(_frontCardShown(tester, 1), isFalse);

    await tester.pump(
      DiscoveryImagePrefetch.frontPhotoWait - const Duration(milliseconds: 100),
    );
    expect(_frontCardShown(tester, 1), isFalse);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(_frontCardShown(tester, 1), isTrue);
  });

  testWidgets('a photo that fails to load does not hold the card back',
      (tester) async {
    await pumpStack(tester, [_card(1, photos: 1), _card(2)]);
    expect(_frontCardShown(tester, 1), isFalse);

    pending['https://example.com/1-0.jpg']!.completeError(StateError('404'));
    await tester.pump();
    await tester.pump();

    expect(_frontCardShown(tester, 1), isTrue);
  });
}
