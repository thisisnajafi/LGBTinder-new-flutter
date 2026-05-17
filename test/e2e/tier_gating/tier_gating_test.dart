import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/feature_locked_screen.dart';
import 'package:lgbtindernew/screens/tier_comparison_screen.dart';
import 'package:lgbtindernew/shared/models/page_tier_rules.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

/// Tier gating and upgrade flows (TEST-064 – TEST-075).
void main() {
  group('TierGatedFeature matrix', () {
    // TEST-064
    test('TEST-064: basid cannot access likesYou', () {
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.likesYou), isFalse);
    });

    // TEST-065
    test('TEST-065: basid cannot access advancedFilters', () {
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.advancedFilters), isFalse);
    });

    // TEST-066
    test('TEST-066: basid cannot access videoCalls', () {
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.videoCalls), isFalse);
    });

    // TEST-067
    test('TEST-067: basid cannot access boost', () {
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.boost), isFalse);
    });

    // TEST-068
    test('TEST-068: silder unlocks mid-tier features, not boost', () {
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.likesYou), isTrue);
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.advancedFilters), isTrue);
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.videoCalls), isTrue);
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.boost), isFalse);
    });

    // TEST-069
    test('TEST-069: golden unlocks all features', () {
      for (final feature in TierGatedFeature.values) {
        expect(canAccessFeature(UserTier.golden, feature), isTrue);
      }
    });
  });

  group('FeatureLockedScreen widget', () {
    // TEST-070
    testWidgets('TEST-070: renders title, tier label, and bullets', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FeatureLockedScreen(
              featureTitle: 'Video calls',
              minTier: UserTier.silder,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upgrade required'), findsOneWidget);
      expect(find.text('Video calls'), findsOneWidget);
      expect(find.textContaining('Silder'), findsOneWidget);
      expect(find.text('View plans'), findsOneWidget);
      expect(find.text('Compare tiers'), findsOneWidget);
    });

    // TEST-071
    testWidgets('TEST-071: View plans navigates to subscription-plans', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => FeatureLockedScreen(
              featureTitle: 'Boost',
              minTier: UserTier.golden,
            ),
          ),
          GoRoute(
            path: AppRoutes.subscriptionPlans,
            builder: (_, __) => const Scaffold(body: Text('Plans Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View plans'));
      await tester.pumpAndSettle();

      expect(find.text('Plans Screen'), findsOneWidget);
    });

    // TEST-072
    testWidgets('TEST-072: Compare tiers navigates to tier-comparison', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => FeatureLockedScreen(
              featureTitle: 'Likes you',
              minTier: UserTier.silder,
            ),
          ),
          GoRoute(
            path: AppRoutes.tierComparison,
            builder: (_, __) => const TierComparisonScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Compare tiers'));
      await tester.pumpAndSettle();

      expect(find.byType(TierComparisonScreen), findsOneWidget);
    });

    // TEST-073
    testWidgets('TEST-073: tier comparison screen renders', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: TierComparisonScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TierComparisonScreen), findsOneWidget);
    });
  });

  group('FeatureLockedScreen.fromQueryParams', () {
    test('parses minTier golden from query', () {
      final screen = FeatureLockedScreen.fromQueryParams({
        'title': 'Boost',
        'minTier': 'golden',
      });
      expect(screen.minTier, UserTier.golden);
      expect(screen.featureTitle, 'Boost');
    });
  });
}
