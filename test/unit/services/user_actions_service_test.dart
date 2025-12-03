/// Unit tests for UserActionsService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/safety/data/services/user_actions_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/safety/data/models/block.dart';
import 'package:lgbtindernew/features/safety/data/models/report.dart';
import 'package:lgbtindernew/features/safety/data/models/favorite.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'user_actions_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late UserActionsService userActionsService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    userActionsService = UserActionsService(mockApiService);
  });

  group('UserActionsService', () {
    group('blockUser', () {
      test('should complete successfully on block', () async {
        // Arrange
        final request = BlockUserRequest(blockedUserId: 123);

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'User blocked',
        ));

        // Act
        await userActionsService.blockUser(request);

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed block', () async {
        // Arrange
        final request = BlockUserRequest(blockedUserId: 123);

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Block failed',
        ));

        // Act & Assert
        expect(
          () => userActionsService.blockUser(request),
          throwsException,
        );
      });
    });

    group('unblockUser', () {
      test('should complete successfully on unblock', () async {
        // Arrange
        const blockedUserId = 123;

        when(mockApiService.delete<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'User unblocked',
        ));

        // Act
        await userActionsService.unblockUser(blockedUserId);

        // Assert
        verify(mockApiService.delete<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });
    });

    group('getBlockedUsers', () {
      test('should return list of blocked users on successful call', () async {
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
              'blocked_at': '2024-01-01T00:00:00Z',
            },
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: responseData,
              message: 'Blocked users retrieved',
            ));

        // Act
        final result = await userActionsService.getBlockedUsers();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(1));
        expect(result[0].id, equals(1));
      });

      test('should return empty list when no blocked users', () async {
        // Arrange
        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              isSuccess: true,
              data: {'data': []},
              message: 'No blocked users',
            ));

        // Act
        final result = await userActionsService.getBlockedUsers();

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });
    });

    group('reportUser', () {
      test('should return Report on successful report', () async {
        // Arrange
        final request = ReportUserRequest(
          reportedUserId: 123,
          reason: 'spam',
          description: 'User is spamming',
        );

        final responseData = {
          'id': 1,
          'reported_user_id': 123,
          'reason': 'spam',
          'description': 'User is spamming',
          'created_at': '2024-01-01T00:00:00Z',
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'User reported',
        ));

        // Act
        final result = await userActionsService.reportUser(request);

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(1));
        expect(result.reportedUserId, equals(123));
      });

      test('should throw exception on failed report', () async {
        // Arrange
        final request = ReportUserRequest(
          reportedUserId: 123,
          reason: 'spam',
        );

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Report failed',
        ));

        // Act & Assert
        expect(
          () => userActionsService.reportUser(request),
          throwsException,
        );
      });
    });

    group('muteUser', () {
      test('should complete successfully on mute', () async {
        // Arrange
        const mutedUserId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'User muted',
        ));

        // Act
        await userActionsService.muteUser(mutedUserId);

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });
    });

    group('addToFavorites', () {
      test('should return Favorite on successful add', () async {
        // Arrange
        final request = AddFavoriteRequest(favoriteUserId: 123);

        final responseData = {
          'id': 1,
          'favorite_user_id': 123,
          'created_at': '2024-01-01T00:00:00Z',
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Added to favorites',
        ));

        // Act
        final result = await userActionsService.addToFavorites(request);

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(1));
        expect(result.favoriteUserId, equals(123));
      });
    });
  });
}

