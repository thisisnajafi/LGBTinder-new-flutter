import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/avatar_widget.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart'
    as app_models;
import 'package:lgbtindernew/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:lgbtindernew/widgets/badges/notification_badge.dart';

Finder _badgeScale() {
  return find.descendant(
    of: find.byType(NotificationBadge),
    matching: find.byType(ScaleTransition),
  );
}

void main() {
  group('NotificationTile', () {
    testWidgets('uses a thumbnail avatar inside a RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationTile(
                notification: app_models.Notification(
                  id: 1,
                  type: 'match',
                  title: "It's a Match!",
                  message: 'Alex matched with you',
                  createdAt: DateTime(2026, 1, 1),
                  userImageUrl: 'https://example.com/a.jpg',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(AvatarWidget), findsOneWidget);
      final image = tester.widget<OptimizedImage>(find.byType(OptimizedImage));
      expect(image.size, ImageSize.thumbnail);
    });
  });

  group('NotificationBadge', () {
    testWidgets('skips ScaleTransition until the count changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(count: 3),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      final first = tester.widget<ScaleTransition>(_badgeScale());
      expect(first.scale.value, 1.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBadge(count: 4),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 40));

      final pulsed = tester.widget<ScaleTransition>(_badgeScale());
      expect(pulsed.scale.value, isNot(1.0));
    });

    testWidgets('Reduce Motion skips ScaleTransition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            );
          },
          home: const Scaffold(
            body: NotificationBadge(count: 2),
          ),
        ),
      );

      expect(_badgeScale(), findsNothing);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
