import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/matching/data/models/match.dart';
import 'package:lgbtindernew/features/matching/data/services/likes_service.dart';

void main() {
  group('LikesService.parseCollection', () {
    test('reads matches after ApiResponse unwraps data', () {
      final rows = LikesService.parseCollection({
        'matches': [
          {'id': 10, 'user_id': 88, 'name': 'alireza psh'},
        ],
      });

      expect(rows, hasLength(1));
      expect(rows.first['user_id'], 88);
    });

    test('reads nested data.matches when envelope is not unwrapped', () {
      final rows = LikesService.parseCollection({
        'status': 'success',
        'data': {
          'matches': [
            {'id': 3, 'user_id': 9, 'name': 'Sam'},
          ],
        },
      });

      expect(rows, hasLength(1));
      expect(rows.first['user_id'], 9);
    });

    test('reads legacy data list', () {
      final rows = LikesService.parseCollection({
        'data': [
          {'id': 1, 'user_id': 123},
        ],
      });

      expect(rows, hasLength(1));
      expect(rows.first['id'], 1);
    });

    test('does not treat empty matches map as a missing list', () {
      final rows = LikesService.parseCollection({'matches': []});
      expect(rows, isEmpty);
    });
  });

  group('Match.fromJson', () {
    test('parses backend match list item', () {
      final match = Match.fromJson({
        'id': 10,
        'match_id': 10,
        'user_id': 88,
        'name': 'alireza psh',
        'first_name': 'alireza',
        'last_name': 'psh',
        'avatar': 'https://cdn.example/a.png',
        'matched_at': '2024-01-01T00:00:00Z',
      });

      expect(match.id, 10);
      expect(match.userId, 88);
      expect(match.firstName, 'alireza');
      expect(match.lastName, 'psh');
      expect(match.primaryImageUrl, 'https://cdn.example/a.png');
    });

    test('ignores default-avatar placeholders', () {
      final match = Match.fromJson({
        'id': 10,
        'user_id': 88,
        'first_name': 'alireza',
        'primary_image_url': 'https://cdn.example/images/default-avatar.png',
        'avatar_url': 'https://cdn.example/profiles/alireza.jpg',
      });

      expect(match.primaryImageUrl, 'https://cdn.example/profiles/alireza.jpg');
    });

    test('flattens nested user object', () {
      final match = Match.fromJson({
        'id': 1,
        'user': {
          'id': 123,
          'first_name': 'John',
          'last_name': 'Doe',
        },
        'matched_at': '2024-01-01T00:00:00Z',
      });

      expect(match.id, 1);
      expect(match.userId, 123);
      expect(match.firstName, 'John');
      expect(match.lastName, 'Doe');
    });
  });
}
