/// Unit tests for ProfileService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/profile/data/services/profile_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/features/profile/data/models/update_profile_request.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'profile_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late ProfileService profileService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    profileService = ProfileService(mockApiService);
  });

  group('ProfileService', () {
    group('getMyProfile', () {
      test('should return UserProfile on successful API call', () async {
        // Arrange
        final responseData = {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Doe',
          'profile_bio': 'Test bio',
          'birth_date': '1990-01-01',
          'images': [],
          'interests': [],
        };

        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: true,
          data: responseData,
          message: 'Profile retrieved',
        ));

        // Act
        final result = await profileService.getMyProfile();

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(1));
        expect(result.firstName, equals('John'));
        expect(result.lastName, equals('Doe'));
        verify(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed API call', () async {
        // Arrange
        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: false,
          data: null,
          message: 'Profile not found',
        ));

        // Act & Assert
        expect(
          () => profileService.getMyProfile(),
          throwsException,
        );
      });
    });

    group('getUserProfile', () {
      test('should return UserProfile for specific user ID', () async {
        // Arrange
        const userId = 123;
        final responseData = {
          'id': userId,
          'first_name': 'Jane',
          'last_name': 'Smith',
          'profile_bio': 'Another bio',
          'birth_date': '1995-05-15',
          'images': [],
          'interests': [],
        };

        when(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: true,
          data: responseData,
          message: 'Profile retrieved',
        ));

        // Act
        final result = await profileService.getUserProfile(userId);

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(userId));
        expect(result.firstName, equals('Jane'));
        verify(mockApiService.get<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });
    });

    group('updateProfile', () {
      test('should return updated UserProfile on successful update', () async {
        // Arrange
        final request = UpdateProfileRequest(
          profileBio: 'Updated bio',
          height: 180,
          weight: 75,
        );

        final responseData = {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Doe',
          'profile_bio': 'Updated bio',
          'height': 180,
          'weight': 75,
          'birth_date': '1990-01-01',
          'images': [],
          'interests': [],
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: true,
          data: responseData,
          message: 'Profile updated',
        ));

        // Act
        final result = await profileService.updateProfile(request);

        // Assert
        expect(result, isNotNull);
        expect(result.profileBio, equals('Updated bio'));
        expect(result.height, equals(180));
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed update', () async {
        // Arrange
        final request = UpdateProfileRequest(
          profileBio: 'Updated bio',
        );

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: false,
          data: null,
          message: 'Update failed',
        ));

        // Act & Assert
        expect(
          () => profileService.updateProfile(request),
          throwsException,
        );
      });
    });
  });
}

