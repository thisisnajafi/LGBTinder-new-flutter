import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart'
    as app_models;
import 'package:lgbtindernew/features/notifications/presentation/widgets/notification_tile.dart';

void main() {
  app_models.Notification notification({int id = 1, bool isRead = false}) {
    return app_models.Notification(
      id: id,
      type: 'match',
      title: "It's a Match!",
      message: 'alireza psh is now matched with you! 🎉',
      createdAt: DateTime(2026, 1, 1),
      isRead: isRead,
    );
  }

  test('copyWith preserves unread until marked read', () {
    final original = notification();
    expect(original.copyWith(isRead: true).isRead, isTrue);
    expect(original.copyWith(isRead: true).id, original.id);
    expect(original.isRead, isFalse);
  });

  testWidgets('swipe-left delete background is a Dismissible', (tester) async {
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              if (deleted) return const SizedBox.shrink();
              return NotificationTile(
                notification: notification(),
                onDelete: () => setState(() => deleted = true),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(Dismissible), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
    expect(find.byType(Dismissible), findsNothing);
  });
}
