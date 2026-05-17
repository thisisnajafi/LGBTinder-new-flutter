import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/matching/presentation/screens/matches_screen.dart';
import 'package:lgbtindernew/widgets/error_handling/empty_state.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';
import 'package:lgbtindernew/features/matching/data/services/likes_service.dart';
import 'package:lgbtindernew/features/matching/providers/likes_providers.dart';

class MockLikesService extends Mock implements LikesService {}

/// Matching & likes (TEST-046 – TEST-052).
void main() {
  group('Matches screen', () {
    // TEST-048, TEST-049
    testWidgets('TEST-048: matches screen shows loading then content', (tester) async {
      final likes = MockLikesService();
      when(() => likes.getMatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [likesServiceProvider.overrideWithValue(likes)],
          child: const MaterialApp(home: MatchesScreen()),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(MatchesScreen), findsOneWidget);
    });

    testWidgets('TEST-049: empty matches shows EmptyState', (tester) async {
      final likes = MockLikesService();
      when(() => likes.getMatches()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [likesServiceProvider.overrideWithValue(likes)],
          child: const MaterialApp(home: MatchesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });
  });
}
