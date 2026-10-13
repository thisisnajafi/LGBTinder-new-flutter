// TESTING (Task 10.2.2): Flutter Widget Tests - Profile Card
//
// Tests for:
// - Widget rendering
// - Tap callback when interactive

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/discover/presentation/widgets/profile_card.dart';
import 'package:lgbtindernew/features/discover/data/models/discovery_profile.dart';

void main() {
  group('ProfileCard Widget Tests', () {
    testWidgets('renders profile information correctly', (WidgetTester tester) async {
      final profile = DiscoveryProfile(
        id: 1,
        firstName: 'John',
        age: 25,
        city: 'New York',
        profileBio: 'Test bio',
        primaryImageUrl: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileCard(profile: profile),
            ),
          ),
        ),
      );

      expect(find.textContaining('John'), findsWidgets);
      expect(find.textContaining('25'), findsWidgets);
      expect(find.textContaining('New York'), findsWidgets);
    });

    testWidgets('calls onTap when interactive', (WidgetTester tester) async {
      var tapped = false;
      final profile = DiscoveryProfile(
        id: 1,
        firstName: 'John',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileCard(
                profile: profile,
                isInteractive: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProfileCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
