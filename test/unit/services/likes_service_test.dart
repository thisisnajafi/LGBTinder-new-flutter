/// Unit tests for LikesService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/matching/data/services/likes_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/matching/data/models/like.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'likes_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late LikesService likesService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    likesService = LikesService(mockApiService);
  });

  group('LikesService', () {
    group('likeUser', () {
      test('should return LikeResponse with match on successful like', () async {
        // Arrange
        const likedUserId = 123;
        final responseData = {
          'is_match': true,
          'match_id': 456,
          'message': 'It\'s a match!',
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Like sent',
        ));

        // Act
        final result = await likesService.likeUser(likedUserId);

        // Assert
        expect(result, isNotNull);
        expect(result.isMatch, equals(true));
        expect(result.matchId, equals(456));
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should return LikeResponse without match when no match', () async {
        // Arrange
        const likedUserId = 123;
        final responseData = {
          'is_match': false,
          'match_id': null,
          'message': 'Like sent',
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Like sent',
        ));

        // Act
        final result = await likesService.likeUser(likedUserId);

        // Assert
        expect(result, isNotNull);
        expect(result.isMatch, equals(false));
        expect(result.matchId, isNull);
      });

      test('should throw exception on failed like', () async {
        // Arrange
        const likedUserId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Like failed',
        ));

        // Act & Assert
        expect(
          () => likesService.likeUser(likedUserId),
          throwsException,
        );
      });
    });

    group('dislikeUser', () {
      test('should complete successfully on dislike', () async {
        // Arrange
        const likedUserId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'Dislike sent',
        ));

        // Act
        await likesService.dislikeUser(likedUserId);

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed dislike', () async {
        // Arrange
        const likedUserId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Dislike failed',
        ));

        // Act & Assert
        expect(
          () => likesService.dislikeUser(likedUserId),
          throwsException,
        );
      });
    });

    group('superlikeUser', () {
      test('should return LikeResponse on successful superlike', () async {
        // Arrange
        const likedUserId = 123;
        final responseData = {
          'is_match': true,
          'match_id': 789,
          'message': 'Superlike sent!',
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Superlike sent',
        ));

        // Act
        final result = await likesService.superlikeUser(likedUserId);

        // Assert
        expect(result, isNotNull);
        expect(result.isMatch, equals(true));
        expect(result.matchId, equals(789));
      });
    });

    group('getMatches', () {
      test('should return list of matches on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'user': {
                'id': 123,
                'first_name': 'John',
                'last_name': 'Doe',
              },
              'matched_at': '2024-01-01T00:00:00Z',
            },
            {
              'id': 2,
              'user': {
                'id': 456,
                'first_name': 'Jane',
                'last_name': 'Smith',
              },
              'matched_at': '2024-01-02T00:00:00Z',
            },
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Matches retrieved',
            ));

        // Act
        final result = await likesService.getMatches();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[1].id, equals(2));
      });

      test('should return empty list when no matches', () async {
        // Arrange
        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: {'data': []},
              message: 'No matches',
            ));

        // Act
        final result = await likesService.getMatches();

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });
    });
  });
}

