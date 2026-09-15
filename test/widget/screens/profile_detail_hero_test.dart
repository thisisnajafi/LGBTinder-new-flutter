import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';
import 'package:lgbtindernew/features/profile/presentation/widgets/own_profile/profile_hero_section.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

void main() {
  testWidgets('hero carousel uses OptimizedImage inside a RepaintBoundary',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileHeroSection(
              fullName: 'Ada Lovelace',
              avatarUrl: 'https://example.com/a.jpg',
              photoUrls: const [
                'https://example.com/a.jpg',
                'https://example.com/b.jpg',
              ],
              age: 36,
              isVerified: false,
              tier: UserTier.basid,
              locationLabel: 'London',
              isOnline: true,
              viewsCount: 0,
              superlikesRemaining: null,
              onEditProfile: () {},
              onEditPhoto: () {},
              onViewProfile: () {},
              viewerMode: true,
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('profile_photo_carousel')), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(OptimizedImage), findsWidgets);
    expect(find.byType(BackdropFilter), findsNothing);
    final image = tester.widget<OptimizedImage>(find.byType(OptimizedImage).first);
    expect(image.size, ImageSize.small);
  });
}
