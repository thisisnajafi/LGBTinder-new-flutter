// Run 6 deep smoothness pass: guards for the fixes listed in
// docs/pm/logs/06B-smoothness-deep-REPORT.md.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/image_decode_size.dart';
import 'package:lgbtindernew/core/utils/optimistic_action.dart';
import 'package:lgbtindernew/core/widgets/frosted_placeholders.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';
import 'package:lgbtindernew/core/widgets/premium/premium_hero_header.dart';
import 'package:lgbtindernew/features/profile/presentation/widgets/own_profile/profile_hero_section.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

void main() {
  group('ImageDecodeSize.cover', () {
    test('scales the box width by the device pixel ratio', () {
      expect(
        ImageDecodeSize.cover(width: 100, height: 100, devicePixelRatio: 3),
        300,
      );
    });

    test('covers a tall box so a 4:3 photo is not stretched', () {
      // 100 wide, 400 tall: 400 * 0.75 = 300 logical px wins over 100.
      expect(
        ImageDecodeSize.cover(width: 100, height: 400, devicePixelRatio: 2),
        600,
      );
    });

    test('never goes below the minimum or above the cap', () {
      expect(
        ImageDecodeSize.cover(width: 10, height: 10, devicePixelRatio: 1),
        ImageDecodeSize.minDecode,
      );
      expect(
        ImageDecodeSize.cover(width: 2000, height: 3000, devicePixelRatio: 3),
        ImageDecodeSize.maxDecode,
      );
      expect(
        ImageDecodeSize.cover(
          width: 2000,
          height: 3000,
          devicePixelRatio: 3,
          max: 800,
        ),
        800,
      );
    });

    test('survives unbounded or invalid input', () {
      expect(
        ImageDecodeSize.cover(
          width: double.infinity,
          height: double.nan,
          devicePixelRatio: 0,
        ),
        ImageDecodeSize.minDecode,
      );
    });
  });

  group('OptimisticGate', () {
    test('applies at once and keeps the change when the commit succeeds',
        () async {
      final gate = OptimisticGate();
      final commit = Completer<String>();
      var liked = false;
      var rolledBack = false;

      final pending = gate.run<String>(
        apply: () => liked = true,
        commit: () => commit.future,
        rollback: () => rolledBack = true,
      );

      // Visible before the request finishes.
      expect(liked, isTrue);
      expect(gate.isBusy, isTrue);

      commit.complete('ok');
      expect(await pending, 'ok');
      expect(liked, isTrue);
      expect(rolledBack, isFalse);
      expect(gate.isBusy, isFalse);
    });

    test('rolls back and rethrows when the commit fails', () async {
      final gate = OptimisticGate();
      var liked = false;

      await expectLater(
        gate.run<String>(
          apply: () => liked = true,
          commit: () async => throw StateError('offline'),
          rollback: () => liked = false,
        ),
        throwsStateError,
      );

      expect(liked, isFalse);
      expect(gate.isBusy, isFalse);
    });

    test('ignores a second tap while the first request is running', () async {
      final gate = OptimisticGate();
      final commit = Completer<String>();
      var commits = 0;
      var applies = 0;

      final first = gate.run<String>(
        apply: () => applies++,
        commit: () {
          commits++;
          return commit.future;
        },
        rollback: () {},
      );
      final second = await gate.run<String>(
        apply: () => applies++,
        commit: () async {
          commits++;
          return 'second';
        },
        rollback: () {},
      );

      expect(second, isNull);
      commit.complete('first');
      expect(await first, 'first');
      expect(commits, 1);
      expect(applies, 1);
    });

    test('can run again after a failure', () async {
      final gate = OptimisticGate();
      await expectLater(
        gate.run<String>(
          apply: () {},
          commit: () async => throw StateError('offline'),
          rollback: () {},
        ),
        throwsStateError,
      );
      expect(
        await gate.run<String>(
          apply: () {},
          commit: () async => 'ok',
          rollback: () {},
        ),
        'ok',
      );
    });
  });

  group('FrostedTextPlaceholder', () {
    test('rhythm follows word lengths without keeping the words', () {
      expect(FrostedTextPlaceholder.rhythmOf('hey there you'), [3, 5, 3]);
    });

    test('rhythm is bounded for long or empty text', () {
      expect(FrostedTextPlaceholder.rhythmOf(''), isNotEmpty);
      expect(FrostedTextPlaceholder.rhythmOf('   '), isNotEmpty);
      final long = FrostedTextPlaceholder.rhythmOf(
        List.filled(40, 'supercalifragilisticexpialidocious').join(' '),
      );
      expect(long.length, lessThanOrEqualTo(12));
      expect(long.every((chars) => chars >= 1 && chars <= 14), isTrue);
    });

    testWidgets('paints no text and no blur layer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: FrostedTextPlaceholder(
                text: 'my secret message',
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('secret'), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.getSize(find.byType(FrostedTextPlaceholder)).width, 200);
    });
  });

  group('PremiumHeroHeader', () {
    Widget host(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('glass capsule (chat header) uses no live blur',
        (tester) async {
      await tester.pumpWidget(
        host(
          const PremiumHeroHeader(
            transparentSides: true,
            overAmbientBackground: true,
            coverImageUrl: 'https://example.com/a.jpg',
            child: Text('Alex'),
          ),
        ),
      );

      expect(find.text('Alex'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      // Over a wallpaper the cover photo is not drawn at all.
      expect(find.byType(OptimizedImage), findsNothing);
    });

    testWidgets('profile hero cover is a tiny decode, not a blur pass',
        (tester) async {
      await tester.pumpWidget(
        host(
          const PremiumHeroHeader(
            coverImageUrl: 'https://example.com/a.jpg',
            child: SizedBox(height: 120, child: Text('Alex')),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      final image = tester.widget<OptimizedImage>(find.byType(OptimizedImage));
      expect(image.memoryCacheWidth, lessThanOrEqualTo(16));
    });

    testWidgets('profile hero without a cover shows the brand gradient',
        (tester) async {
      await tester.pumpWidget(
        host(
          const PremiumHeroHeader(
            child: SizedBox(height: 120, child: Text('Alex')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(OptimizedImage), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });

  group('ProfileHeroSection viewer like button', () {
    Widget host({required bool isLiked, required VoidCallback onLike}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileHeroSection(
                fullName: 'Alex Doe',
                avatarUrl: null,
                photoUrls: const [],
                age: 27,
                isVerified: false,
                isOfficial: false,
                tier: UserTier.basid,
                planLabel: null,
                locationLabel: 'Berlin',
                isOnline: true,
                viewsCount: 0,
                superlikesRemaining: null,
                onEditProfile: () {},
                onEditPhoto: () {},
                onViewProfile: () {},
                viewerMode: true,
                onLike: onLike,
                isLiked: isLiked,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows Like, then Liked once the like is applied',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(isLiked: false, onLike: () => taps++));
      await tester.pump();

      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Liked'), findsNothing);

      await tester.tap(find.byKey(ProfileHeroSection.likeButtonKey));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);

      await tester.pumpWidget(host(isLiked: true, onLike: () => taps++));
      await tester.pump();

      expect(find.text('Liked'), findsOneWidget);
      expect(find.text('Like'), findsNothing);
    });
  });

  group('source guards', () {
    test('home shell mutes tickers of hidden tabs', () {
      final source = File('lib/pages/home_page.dart').readAsStringSync();
      expect(source, contains('TickerMode('));
      expect(source, contains('enabled: i == currentIndex'));
    });

    test('scroll items and headers no longer blur per frame', () {
      for (final path in const [
        'lib/widgets/chat/chat_bubble_photo.dart',
        'lib/core/widgets/premium/premium_hero_header.dart',
        'lib/widgets/chat/chat_list_item.dart',
        'lib/features/notifications/presentation/widgets/notification_tile.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('ImageFiltered(')), reason: path);
        expect(source, isNot(contains('BackdropFilter(')), reason: path);
      }
    });

    test('profile and chat photo grids cap their decode size', () {
      for (final path in const [
        'lib/widgets/cards/profile_detail_sheet.dart',
        'lib/features/profile/presentation/widgets/other_user_profile/other_user_profile_sections.dart',
        'lib/features/profile/widgets/profile_photo_carousel.dart',
        'lib/widgets/chat/chat_user_info_panel.dart',
        'lib/pages/chat_conversation_info_page.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('ImageDecodeSize.'), reason: path);
        expect(source, contains('memCacheWidth:'), reason: path);
      }
    });
  });
}
