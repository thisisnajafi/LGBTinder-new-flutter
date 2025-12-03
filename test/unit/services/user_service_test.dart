/// Unit tests for UserService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/user/data/services/user_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/user/data/models/user_info.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'user_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late UserService userService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    userService = UserService(mockApiService);
  });

  group('UserService', () {
    group('getUserInfo', () {
      test('should return UserInfo on successful API call', () async {
        // Arrange
        final responseData = {
          'id': 1,
          'email': 'test@example.com',
          'first_name': 'Test',
          'last_name': 'User',
          'show_adult_content': true,
          'onesignal_player_id': 'player123',
          'notification_preferences': {
            'likes': true,
            'matches': true,
            'messages': true,
            'superlikes': false,
          },
        };

        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'User info retrieved',
        ));

        // Act
        final result = await userService.getUserInfo();

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(1));
        expect(result.email, equals('test@example.com'));
        expect(result.firstName, equals('Test'));
        expect(result.lastName, equals('User'));
        expect(result.showAdultContent, equals(true));
      });

      test('should throw exception on failed API call', () async {
        // Arrange
        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'User not found',
        ));

        // Act & Assert
        expect(
          () => userService.getUserInfo(),
          throwsException,
        );
      });
    });
  });
}

