import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/app_date_time.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart';

void main() {
  group('AppDateTime.parseApi', () {
    test('treats naive server timestamps as UTC then converts to local', () {
      final parsed = AppDateTime.parseApi('2026-08-18 16:23:00');

      expect(parsed, isNotNull);
      expect(parsed!.toUtc(), DateTime.utc(2026, 8, 18, 16, 23));
    });

    test('keeps explicit UTC timestamps as the same instant', () {
      final parsed = AppDateTime.parseApi('2026-08-18T16:23:00.000000Z');

      expect(parsed, isNotNull);
      expect(parsed!.toUtc(), DateTime.utc(2026, 8, 18, 16, 23));
    });

    test('keeps offset timestamps as the same instant', () {
      final parsed = AppDateTime.parseApi('2026-08-18T19:53:00+03:30');

      expect(parsed, isNotNull);
      expect(parsed!.toUtc(), DateTime.utc(2026, 8, 18, 16, 23));
    });
  });

  group('AppDateTime.formatRelative', () {
    final now = DateTime(2026, 8, 18, 20, 0);

    test('shows Just now for timestamps under a minute', () {
      expect(
        AppDateTime.formatRelative(
          now.subtract(const Duration(seconds: 20)),
          now: now,
        ),
        'Just now',
      );
    });

    test('shows minutes and hours in local time', () {
      expect(
        AppDateTime.formatRelative(
          now.subtract(const Duration(minutes: 3)),
          now: now,
        ),
        '3m ago',
      );
      expect(
        AppDateTime.formatRelative(
          now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3h ago',
      );
    });
  });

  group('Notification.fromJson', () {
    test('localizes a naive UTC created_at from the notifications API', () {
      final notification = Notification.fromJson({
        'id': 1,
        'type': 'like',
        'title': 'New Like',
        'message': 'Someone liked your profile',
        'created_at': '2026-08-18 16:23:00',
      });

      expect(
        notification.createdAt.toUtc(),
        DateTime.utc(2026, 8, 18, 16, 23),
      );
    });

    test('round-trips created_at through cache JSON without shifting timezone', () {
      final original = Notification.fromJson({
        'id': 1,
        'type': 'like',
        'title': 'New Like',
        'message': 'Someone liked your profile',
        'created_at': '2026-08-18 16:23:00',
      });

      final restored = Notification.fromJson(original.toJson());

      expect(restored.createdAt.toUtc(), original.createdAt.toUtc());
      expect(original.toJson()['created_at'].toString(), contains('Z'));
    });
  });
}
