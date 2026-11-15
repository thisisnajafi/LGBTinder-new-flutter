// Discover action bar: semantics, sizes, locked and disabled states.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_action_bar.dart';
import 'package:lgbtindernew/widgets/discovery/discovery_swipe_action_button.dart';

import 'discover_test_host.dart';

const _labels = <DiscoverySwipeActionType, String>{
  DiscoverySwipeActionType.rewind: 'Rewind last swipe',
  DiscoverySwipeActionType.dislike: 'Dislike profile',
  DiscoverySwipeActionType.superlike: 'Super like profile',
  DiscoverySwipeActionType.like: 'Like profile',
};

Finder _button(DiscoverySwipeActionType type) {
  return find.byWidgetPredicate(
    (w) => w is DiscoverySwipeActionButton && w.type == type,
  );
}

void main() {
  late List<String> taps;

  Widget bar({bool rewindLocked = false, bool enabled = true}) {
    return Center(
      child: DiscoverActionBar(
        rewindLocked: rewindLocked,
        onRewind: enabled ? () => taps.add('rewind') : null,
        onPass: enabled ? () => taps.add('pass') : null,
        onSuperlike: enabled ? () => taps.add('superlike') : null,
        onLike: enabled ? () => taps.add('like') : null,
      ),
    );
  }

  setUp(() => taps = <String>[]);

  testWidgets('every action is a labelled, enabled button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDiscoverHost(tester, bar());

    for (final label in _labels.values) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('order is rewind, pass, super like, like (mirrored in RTL)',
      (tester) async {
    const order = [
      DiscoverySwipeActionType.rewind,
      DiscoverySwipeActionType.dislike,
      DiscoverySwipeActionType.superlike,
      DiscoverySwipeActionType.like,
    ];

    await pumpDiscoverHost(tester, bar());
    final ltr = [for (final t in order) tester.getCenter(_button(t)).dx];
    expect(ltr, orderedEquals([...ltr]..sort()));

    await pumpDiscoverHost(tester, bar(), direction: TextDirection.rtl);
    final rtl = [for (final t in order) tester.getCenter(_button(t)).dx];
    expect(rtl, orderedEquals(([...rtl]..sort()).reversed));
  });

  testWidgets('like and pass are the largest; every target is at least 48 dp',
      (tester) async {
    await pumpDiscoverHost(tester, bar());

    double visual(DiscoverySwipeActionType type) =>
        tester.widget<DiscoverySwipeActionButton>(_button(type)).size;

    expect(visual(DiscoverySwipeActionType.like), DiscoverActionBar.primarySize);
    expect(
      visual(DiscoverySwipeActionType.dislike),
      DiscoverActionBar.primarySize,
    );
    expect(
      visual(DiscoverySwipeActionType.like),
      greaterThan(visual(DiscoverySwipeActionType.superlike)),
    );
    expect(
      visual(DiscoverySwipeActionType.superlike),
      greaterThan(visual(DiscoverySwipeActionType.rewind)),
    );

    for (final type in DiscoverySwipeActionType.values) {
      final size = tester.getSize(_button(type));
      expect(size.width, greaterThanOrEqualTo(48), reason: '$type width');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$type height');
    }
  });

  testWidgets('each button reports its own tap', (tester) async {
    await pumpDiscoverHost(tester, bar(), reduceMotion: true);

    await tester.tap(_button(DiscoverySwipeActionType.like));
    await tester.pump();
    await tester.tap(_button(DiscoverySwipeActionType.dislike));
    await tester.pump();
    await tester.tap(_button(DiscoverySwipeActionType.superlike));
    await tester.pump();
    await tester.tap(_button(DiscoverySwipeActionType.rewind));
    await tester.pump();

    expect(taps, ['like', 'pass', 'superlike', 'rewind']);
  });

  testWidgets('plan-locked rewind shows a lock, says so, and still opens',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDiscoverHost(tester, bar(rewindLocked: true), reduceMotion: true);

    expect(
      find.descendant(
        of: _button(DiscoverySwipeActionType.rewind),
        matching: find.byKey(DiscoverySwipeActionButton.lockBadgeKey),
      ),
      findsOneWidget,
    );
    // Only the gated action carries the badge.
    expect(find.byKey(DiscoverySwipeActionButton.lockBadgeKey), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Rewind last swipe')),
      isSemantics(
        isButton: true,
        isEnabled: true,
        hint: 'Locked. Upgrade to use.',
      ),
    );

    // Tappable: the page uses the tap to open the upgrade screen.
    await tester.tap(_button(DiscoverySwipeActionType.rewind));
    await tester.pump();
    expect(taps, ['rewind']);
    handle.dispose();
  });

  testWidgets('without callbacks the buttons are disabled and ignore taps',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDiscoverHost(tester, bar(enabled: false), reduceMotion: true);

    for (final entry in _labels.entries) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(entry.value)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        reason: entry.value,
      );
      await tester.tap(_button(entry.key), warnIfMissed: false);
      await tester.pump();
    }
    expect(taps, isEmpty);
    expect(find.byKey(DiscoverySwipeActionButton.lockBadgeKey), findsNothing);
    handle.dispose();
  });

  testWidgets('fits the narrowest phone in RTL at 1.3x text, no overflow',
      (tester) async {
    // 320 dp phone minus the page's 16 dp side padding.
    await pumpDiscoverHost(
      tester,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: bar(rewindLocked: true),
      ),
      surface: const Size(320, 568),
      textScale: 1.3,
      direction: TextDirection.rtl,
    );

    expectNoLayoutErrors(tester);
    for (final type in DiscoverySwipeActionType.values) {
      final rect = tester.getRect(_button(type));
      expect(rect.left, greaterThanOrEqualTo(16), reason: '$type left');
      expect(rect.right, lessThanOrEqualTo(320 - 16), reason: '$type right');
      // Not scaled down: targets keep their full size.
      expect(rect.width, greaterThanOrEqualTo(48), reason: '$type width');
    }
  });

  testWidgets('renders in dark mode', (tester) async {
    await pumpDiscoverHost(tester, bar(), brightness: Brightness.dark);
    expectNoLayoutErrors(tester);
    expect(find.byType(DiscoverySwipeActionButton), findsNWidgets(4));
  });
}
