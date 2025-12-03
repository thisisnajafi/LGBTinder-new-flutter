/// Unit tests for NotificationService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/notifications/data/services/notification_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late NotificationService notificationService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    notificationService = NotificationService(mockApiService);
  });

  group('NotificationService', () {
    group('getNotifications', () {
      test('should return list of notifications on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'type': 'like',
              'title': 'New Like',
              'message': 'John liked your profile',
              'is_read': false,
              'created_at': '2024-01-01T00:00:00Z',
            },
            {
              'id': 2,
              'type': 'match',
              'title': 'New Match',
              'message': 'You matched with Jane',
              'is_read': true,
              'created_at': '2024-01-01T01:00:00Z',
            },
          ],
        };

        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          isSuccess: true,
          data: responseData,
          message: 'Notifications retrieved',
        ));

        // Act
        final result = await notificationService.getNotifications();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].id, equals(1));
        expect(result[0].type, equals('like'));
        expect(result[1].id, equals(2));
        expect(result[1].type, equals('match'));
      });

      test('should return empty list when no notifications', () async {
        // Arrange
        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          isSuccess: true,
          data: {'data': []},
          message: 'No notifications',
        ));

        // Act
        final result = await notificationService.getNotifications();

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });

      test('should handle pagination parameters', () async {
        // Arrange
        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          isSuccess: true,
          data: {'data': []},
          message: 'Notifications retrieved',
        ));

        // Act
        await notificationService.getNotifications(page: 2, limit: 20);

        // Assert
        verify(mockApiService.get<dynamic>(
          any,
          queryParameters: argThat(
            predicate<Map<String, dynamic>?>(
              (params) => params?['page'] == 2 && params?['limit'] == 20,
            ),
          ),
        )).called(1);
      });
    });

    group('getUnreadCount', () {
      test('should return unread count on successful call', () async {
        // Arrange
        final responseData = {
          'count': 5,
        };

        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Count retrieved',
        ));

        // Act
        final result = await notificationService.getUnreadCount();

        // Assert
        expect(result, equals(5));
      });

      test('should return 0 when no unread notifications', () async {
        // Arrange
        final responseData = {
          'count': 0,
        };

        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Count retrieved',
        ));

        // Act
        final result = await notificationService.getUnreadCount();

        // Assert
        expect(result, equals(0));
      });

      test('should return 0 on failed call', () async {
        // Arrange
        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Failed',
        ));

        // Act
        final result = await notificationService.getUnreadCount();

        // Assert
        expect(result, equals(0));
      });
    });

    group('markAsRead', () {
      test('should complete successfully on mark as read', () async {
        // Arrange
        const notificationId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'Marked as read',
        ));

        // Act
        await notificationService.markAsRead(notificationId);

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed mark as read', () async {
        // Arrange
        const notificationId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Failed',
        ));

        // Act & Assert
        expect(
          () => notificationService.markAsRead(notificationId),
          throwsException,
        );
      });
    });

    group('markAllAsRead', () {
      test('should complete successfully on mark all as read', () async {
        // Arrange
        when(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'All marked as read',
        ));

        // Act
        await notificationService.markAllAsRead();

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });
    });

    group('deleteNotification', () {
      test('should complete successfully on delete', () async {
        // Arrange
        const notificationId = 123;

        when(mockApiService.delete<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'Deleted',
        ));

        // Act
        await notificationService.deleteNotification(notificationId);

        // Assert
        verify(mockApiService.delete<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed delete', () async {
        // Arrange
        const notificationId = 123;

        when(mockApiService.delete<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Failed',
        ));

        // Act & Assert
        expect(
          () => notificationService.deleteNotification(notificationId),
          throwsException,
        );
      });
    });
  });
}

