// Discover empty state: the three recovery actions stay reachable and
// tappable, also on a small phone with large text in RTL.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_empty_state.dart';
import 'package:lgbtindernew/widgets/cards/card_stack_manager.dart';

import 'discover_test_host.dart';

void main() {
  late List<String> taps;

  setUp(() => taps = <String>[]);

  Widget emptyState() {
    return DiscoverEmptyState(
      title: 'Turn on location for nearby matches',
      subtitle:
          'Enable location so we can find people near you, or expand your '
          'search radius.',
      iconPath: AppIcons.locationSlash,
      primaryActionLabel: 'Enable location',
      primaryActionIconPath: AppIcons.location,
      onPrimaryAction: () => taps.add('primary'),
      secondaryActionLabel: 'Increase distance + retry',
      onSecondaryAction: () => taps.add('secondary'),
      tertiaryActionLabel: 'Adjust filters',
      onTertiaryAction: () => taps.add('tertiary'),
    );
  }

  Future<void> tapAction(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
    // The press-scale and the haptic are fire-and-forget; the pulse on the
    // illustration never settles, so pump a fixed time instead.
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows all three actions and each one fires its callback',
      (tester) async {
    await pumpDiscoverHost(tester, emptyState(), surface: const Size(390, 844));

    expect(find.text('Enable location'), findsOneWidget);
    expect(find.text('Increase distance + retry'), findsOneWidget);
    expect(find.text('Adjust filters'), findsOneWidget);

    await tapAction(tester, DiscoverEmptyState.primaryActionKey);
    await tapAction(tester, DiscoverEmptyState.secondaryActionKey);
    await tapAction(tester, DiscoverEmptyState.tertiaryActionKey);

    expect(taps, ['primary', 'secondary', 'tertiary']);
    expectNoLayoutErrors(tester);
  });

  testWidgets('every action is at least 48 dp tall', (tester) async {
    await pumpDiscoverHost(tester, emptyState(), surface: const Size(390, 844));

    for (final key in [
      DiscoverEmptyState.primaryActionKey,
      DiscoverEmptyState.secondaryActionKey,
      DiscoverEmptyState.tertiaryActionKey,
    ]) {
      expect(
        tester.getSize(find.byKey(key)).height,
        greaterThanOrEqualTo(48),
        reason: '$key',
      );
    }
  });

  testWidgets('actions are announced as buttons with their labels',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpDiscoverHost(tester, emptyState(), surface: const Size(390, 844));

    // Exact labels: each action is announced once, not label + visible text.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Increase distance + retry')),
      isSemantics(
        label: 'Increase distance + retry',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Adjust filters')),
      isSemantics(
        label: 'Adjust filters',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('Enable location')),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('small phone, RTL, 1.3x text: no overflow, actions still work',
      (tester) async {
    await pumpDiscoverHost(
      tester,
      emptyState(),
      textScale: 1.3,
      direction: TextDirection.rtl,
    );
    expectNoLayoutErrors(tester);

    await tapAction(tester, DiscoverEmptyState.primaryActionKey);
    await tapAction(tester, DiscoverEmptyState.secondaryActionKey);
    await tapAction(tester, DiscoverEmptyState.tertiaryActionKey);

    expect(taps, ['primary', 'secondary', 'tertiary']);
    expectNoLayoutErrors(tester);
  });

  testWidgets('dark mode with Reduce Motion renders without errors',
      (tester) async {
    await pumpDiscoverHost(
      tester,
      emptyState(),
      brightness: Brightness.dark,
      reduceMotion: true,
    );
    // With Reduce Motion nothing animates, so the tree settles.
    await tester.pumpAndSettle();
    expectNoLayoutErrors(tester);
  });

  testWidgets('the card stack passes its empty actions through',
      (tester) async {
    await pumpDiscoverHost(
      tester,
      CardStackManager(
        cards: const [],
        emptyTitle: "You've seen everyone nearby",
        emptySubtitle: 'Nobody is inside your current distance.',
        emptyActionLabel: 'Adjust filters',
        emptyActionIconPath: AppIcons.filter,
        onEmptyAction: () => taps.add('primary'),
        emptySecondaryActionLabel: 'Increase distance + retry',
        onEmptySecondaryAction: () => taps.add('secondary'),
        emptyTertiaryActionLabel: 'Update location',
        onEmptyTertiaryAction: () => taps.add('tertiary'),
      ),
      surface: const Size(390, 844),
    );

    await tapAction(tester, DiscoverEmptyState.primaryActionKey);
    await tapAction(tester, DiscoverEmptyState.secondaryActionKey);
    await tapAction(tester, DiscoverEmptyState.tertiaryActionKey);

    expect(taps, ['primary', 'secondary', 'tertiary']);
  });
}
