// TESTING (Task 10.2.2): Flutter Widget Tests - Profile Card
//
// Tests for:
// - Widget rendering
// - User interactions
// - State changes

import 'package:flutter/material.dart';
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
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              profile: profile,
              onLike: () {},
              onDislike: () {},
              onSuperlike: () {},
            ),
          ),
        ),
      );

      // Verify profile information is displayed
      expect(find.text('John'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
    });

    testWidgets('calls onLike when like button is tapped', (WidgetTester tester) async {
      bool likeCalled = false;
      final profile = DiscoveryProfile(
        id: 1,
        firstName: 'John',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              profile: profile,
              onLike: () => likeCalled = true,
              onDislike: () {},
              onSuperlike: () {},
            ),
          ),
        ),
      );

      // Find and tap like button
      final likeButton = find.byIcon(Icons.favorite);
      expect(likeButton, findsOneWidget);
      
      await tester.tap(likeButton);
      await tester.pump();

      expect(likeCalled, true);
    });

    testWidgets('calls onDislike when dislike button is tapped', (WidgetTester tester) async {
      bool dislikeCalled = false;
      final profile = DiscoveryProfile(
        id: 1,
        firstName: 'John',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              profile: profile,
              onLike: () {},
              onDislike: () => dislikeCalled = true,
              onSuperlike: () {},
            ),
          ),
        ),
      );

      // Find and tap dislike button
      final dislikeButton = find.byIcon(Icons.close);
      expect(dislikeButton, findsOneWidget);
      
      await tester.tap(dislikeButton);
      await tester.pump();

      expect(dislikeCalled, true);
    });

    testWidgets('shows loading state when processing', (WidgetTester tester) async {
      final profile = DiscoveryProfile(
        id: 1,
        firstName: 'John',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCard(
              profile: profile,
              isLoading: true,
              onLike: () {},
              onDislike: () {},
              onSuperlike: () {},
            ),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

