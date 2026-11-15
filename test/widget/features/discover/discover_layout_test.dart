// Discover header, status chips and card: layout holds on a small phone in
// RTL at 1.3x text, labels and tap targets are intact.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/core/widgets/compact_page_header.dart';
import 'package:lgbtindernew/features/discover/widgets/discover_header.dart';
import 'package:lgbtindernew/shared/models/match_reason.dart';
import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';

import 'discover_test_host.dart';

const _actionLabels = [
  'Passport — change discovery location',
  'Notifications',
  'Open filters',
];

void main() {
  late List<String> taps;

  setUp(() => taps = <String>[]);

  Widget header({String? firstName = 'Alexandria-Maximiliana'}) {
    return DiscoverHeaderView(
      greeting: 'Good afternoon',
      firstName: firstName,
      isOnline: true,
      onAvatarTap: () => taps.add('avatar'),
      actions: [
        DiscoverHeader.action(
          iconPath: AppIcons.map,
          label: _actionLabels[0],
          onPressed: () => taps.add('passport'),
          showBadge: true,
        ),
        DiscoverHeader.action(
          iconPath: AppIcons.notification,
          label: _actionLabels[1],
          onPressed: () => taps.add('notifications'),
        ),
        DiscoverHeader.action(
          iconPath: AppIcons.filter,
          label: _actionLabels[2],
          onPressed: () => taps.add('filters'),
        ),
      ],
    );
  }

  Widget chips() {
    return DiscoverStatusChipsView(
      passportLabel: 'San Francisco de Macorís, Dominican Republic',
      onReturnHome: () => taps.add('return'),
      quota: const DiscoverSwipeQuota(remaining: 3, limit: 20, used: 17),
      onUpgrade: () => taps.add('upgrade'),
    );
  }

  Widget card({double width = 328, double height = 470}) {
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: SwipeableCard(
          userId: 7,
          name: 'Maximiliana-Alexandria Fitzgerald',
          age: 29,
          city: 'San Francisco de Macorís',
          country: 'Dominican Republic',
          distance: 12.4,
          isVerified: true,
          isPremium: true,
          isOnline: true,
          isSuperliked: true,
          matchPercentage: 45,
          matchReasons: [
            MatchReason(type: 'music', label: 'Loves the same indie bands'),
            MatchReason(type: 'same_city', label: 'Lives in your city'),
            MatchReason(type: 'job', label: 'Works in design'),
            MatchReason(type: 'age', label: 'In your age range'),
          ],
          bio: 'Coffee, long walks and far too many houseplants. Looking for '
              'someone to share playlists, bad puns and weekend markets with.',
          onProfileTap: () => taps.add('profile'),
          carouselEnabled: false,
        ),
      ),
    );
  }

  group('header', () {
    testWidgets('keeps the screen-reader labels and one 56 dp row',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDiscoverHost(tester, header());

      expect(find.bySemanticsLabel('View my profile'), findsOneWidget);
      for (final label in _actionLabels) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      // The bar is still announced as the Discover header.
      expect(find.bySemanticsLabel(RegExp('^Discover')), findsWidgets);
      expect(
        tester.getSize(find.byKey(CompactPageHeader.rowKey)).height,
        CompactPageHeader.minHeight,
      );
      handle.dispose();
    });

    testWidgets('avatar and actions are 48 dp targets and report taps',
        (tester) async {
      await pumpDiscoverHost(tester, header(), reduceMotion: true);

      final avatar = find.byKey(DiscoverHeader.avatarKey);
      expect(tester.getSize(avatar), const Size(48, 48));
      for (final button in tester
          .widgetList<CompactHeaderIconButton>(
            find.byType(CompactHeaderIconButton),
          )) {
        expect(button.touchTargetSize, 48);
      }
      for (final size in tester
          .renderObjectList<RenderBox>(find.byType(CompactHeaderIconFace))
          .map((box) => box.size)) {
        expect(size, const Size(48, 48));
      }

      await tester.tap(avatar);
      await tester.pump(const Duration(milliseconds: 200));
      for (final label in _actionLabels) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(taps, ['avatar', 'passport', 'notifications', 'filters']);
    });

    testWidgets('small phone, RTL, 1.3x text: no overflow, avatar leads',
        (tester) async {
      await pumpDiscoverHost(
        tester,
        header(),
        textScale: 1.3,
        direction: TextDirection.rtl,
      );
      expectNoLayoutErrors(tester);

      // RTL: avatar on the right, actions on the left.
      final avatarX = tester.getCenter(find.byKey(DiscoverHeader.avatarKey)).dx;
      final filterX =
          tester.getCenter(find.bySemanticsLabel('Open filters')).dx;
      expect(avatarX, greaterThan(filterX));
      // Greeting and name stay inside the bar.
      final bar = tester.getRect(find.byKey(CompactPageHeader.rowKey));
      final name = tester.getRect(find.text('Alexandria-Maximiliana'));
      expect(bar.contains(name.topLeft) && bar.contains(name.bottomRight),
          isTrue);
    });

    testWidgets('shows a placeholder, not a wrong name, while loading',
        (tester) async {
      await pumpDiscoverHost(tester, header(firstName: null));
      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('User'), findsNothing);
      expectNoLayoutErrors(tester);
    });
  });

  group('status chips', () {
    testWidgets('passport, quota and upgrade chips are labelled and tappable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDiscoverHost(tester, chips(), reduceMotion: true);

      expect(
        find.bySemanticsLabel('Return from passport location'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('3 of 20 swipes left today'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(DiscoverStatusChips.passportChipKey));
      await tester.pump(const Duration(milliseconds: 200));
      expect(taps, ['return']);

      // The row scrolls sideways; bring the last chip in before tapping.
      await tester.ensureVisible(find.byKey(DiscoverStatusChips.upgradeChipKey));
      await tester.pump();
      expect(
        find.bySemanticsLabel('Upgrade for more swipes'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(DiscoverStatusChips.upgradeChipKey));
      await tester.pump(const Duration(milliseconds: 200));
      expect(taps, ['return', 'upgrade']);
      handle.dispose();
    });

    testWidgets('tappable chips are 48 dp tall; the row is one line',
        (tester) async {
      await pumpDiscoverHost(tester, chips());

      expect(
        tester.getSize(find.byType(DiscoverStatusChipsView)).height,
        DiscoverStatusChips.height,
      );
      expect(
        tester.getSize(find.byKey(DiscoverStatusChips.passportChipKey)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(DiscoverStatusChips.upgradeChipKey)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('small phone, RTL, 1.3x text: no overflow', (tester) async {
      await pumpDiscoverHost(
        tester,
        chips(),
        textScale: 1.3,
        direction: TextDirection.rtl,
      );
      expectNoLayoutErrors(tester);
      expect(
        tester.getSize(find.byType(DiscoverStatusChipsView)).height,
        DiscoverStatusChips.height,
      );
    });

    testWidgets('takes only a small gap when there is nothing to show',
        (tester) async {
      await pumpDiscoverHost(
        tester,
        DiscoverStatusChipsView(onReturnHome: () {}),
      );
      expect(
        tester.getSize(find.byType(DiscoverStatusChipsView)).height,
        lessThan(DiscoverStatusChips.height / 2),
      );
    });
  });

  group('card', () {
    testWidgets('small phone, RTL, 1.3x text: no overflow', (tester) async {
      await pumpDiscoverHost(
        tester,
        card(),
        textScale: 1.3,
        direction: TextDirection.rtl,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('narrow, short card in LTR at 1.3x text: no overflow',
        (tester) async {
      await pumpDiscoverHost(
        tester,
        card(width: 288, height: 400),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('shows the match chip, two reasons and a +N overflow chip',
        (tester) async {
      await pumpDiscoverHost(tester, card());

      expect(find.text('Match 45%'), findsOneWidget);
      expect(find.text('Loves the same indie bands'), findsOneWidget);
      expect(find.text('Lives in your city'), findsOneWidget);
      // Reasons three and four collapse into one counter.
      expect(find.text('Works in design'), findsNothing);
      expect(find.text('In your age range'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('bio is cut to two lines with a "more" label', (tester) async {
      await pumpDiscoverHost(tester, card());

      final bio = tester.widget<Text>(
        find.textContaining('Coffee, long walks'),
      );
      expect(bio.maxLines, 2);
      expect(bio.overflow, TextOverflow.ellipsis);
      expect(find.text('more'), findsOneWidget);
    });

    testWidgets('name, verified and online keep their labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDiscoverHost(tester, card());

      expect(
        find.text('Maximiliana-Alexandria Fitzgerald, 29'),
        findsOneWidget,
      );
      // The text block is one tappable node: name and badges are read
      // together.
      expect(
        find.bySemanticsLabel(
          RegExp(r'Fitzgerald, 29[\s\S]*Verified profile[\s\S]*Premium member'
              r'[\s\S]*Online now'),
        ),
        findsWidgets,
      );
      expect(find.bySemanticsLabel('Superliked you'), findsOneWidget);
      expect(find.bySemanticsLabel('Photo 1 of 1'), findsNothing);
      handle.dispose();
    });

    testWidgets('tapping the text block opens the profile', (tester) async {
      await pumpDiscoverHost(tester, card());

      await tester.tap(find.text('Maximiliana-Alexandria Fitzgerald, 29'));
      await tester.pump();
      expect(taps, ['profile']);
    });
  });
}
