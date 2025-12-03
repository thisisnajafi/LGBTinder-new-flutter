/// Unit tests for model serialization (fromJson/toJson)
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/features/reference_data/data/models/reference_item.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/matching/data/models/match.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

void main() {
  group('Model Serialization Tests', () {
    group('UserProfile', () {
      test('should serialize and deserialize correctly', () {
        // Arrange
        final json = {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Doe',
          'email': 'john@example.com',
          'country_id': 1,
          'country': 'USA',
          'city_id': 1,
          'city': 'New York',
          'gender_id': 1,
          'gender': 'Male',
          'birth_date': '1990-01-01',
          'profile_bio': 'Test bio',
          'height': 180,
          'weight': 75,
          'smoke': false,
          'drink': true,
          'gym': true,
          'images': [
            {
              'id': 1,
              'image_url': 'https://example.com/image.jpg',
              'is_primary': true,
              'order': 1,
            }
          ],
          'interests': [1, 2, 3],
          'min_age_preference': 18,
          'max_age_preference': 35,
        };

        // Act
        final profile = UserProfile.fromJson(json);
        final serialized = profile.toJson();

        // Assert
        expect(profile.id, equals(1));
        expect(profile.firstName, equals('John'));
        expect(profile.lastName, equals('Doe'));
        expect(profile.email, equals('john@example.com'));
        expect(profile.countryId, equals(1));
        expect(profile.cityId, equals(1));
        expect(profile.genderId, equals(1));
        expect(profile.birthDate, equals('1990-01-01'));
        expect(profile.profileBio, equals('Test bio'));
        expect(profile.height, equals(180));
        expect(profile.weight, equals(75));
        expect(profile.smoke, equals(false));
        expect(profile.drink, equals(true));
        expect(profile.gym, equals(true));
        expect(profile.interests, equals([1, 2, 3]));
        expect(profile.minAgePreference, equals(18));
        expect(profile.maxAgePreference, equals(35));
        expect(profile.images?.length, equals(1));
        expect(serialized['id'], equals(1));
        expect(serialized['first_name'], equals('John'));
      });

      test('should handle null values correctly', () {
        // Arrange
        final json = {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Doe',
          'email': 'john@example.com',
        };

        // Act
        final profile = UserProfile.fromJson(json);
        final serialized = profile.toJson();

        // Assert
        expect(profile.countryId, isNull);
        expect(profile.cityId, isNull);
        expect(profile.genderId, isNull);
        expect(profile.birthDate, isNull);
        expect(serialized.containsKey('country_id'), isFalse);
        expect(serialized.containsKey('city_id'), isFalse);
      });
    });

    group('ReferenceItem', () {
      test('should serialize and deserialize correctly', () {
        // Arrange
        final json = {
          'id': 1,
          'title': 'United States',
          'code': 'US',
          'phone_code': '+1',
          'status': 'active',
        };

        // Act
        final item = ReferenceItem.fromJson(json);
        final serialized = item.toJson();

        // Assert
        expect(item.id, equals(1));
        expect(item.title, equals('United States'));
        expect(item.code, equals('US'));
        expect(item.phoneCode, equals('+1'));
        expect(item.status, equals('active'));
        expect(serialized['id'], equals(1));
        expect(serialized['title'], equals('United States'));
      });

      test('should handle name field as title fallback', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'United States',
        };

        // Act
        final item = ReferenceItem.fromJson(json);

        // Assert
        expect(item.title, equals('United States'));
      });
    });

    group('Message', () {
      test('should serialize and deserialize correctly', () {
        // Arrange
        final json = {
          'id': 1,
          'user_id': 123,
          'message': 'Hello',
          'type': 'text',
          'created_at': '2024-01-01T00:00:00Z',
          'is_read': false,
        };

        // Act
        final message = Message.fromJson(json);
        final serialized = message.toJson();

        // Assert
        expect(message.id, equals(1));
        expect(message.userId, equals(123));
        expect(message.message, equals('Hello'));
        expect(message.type, equals('text'));
        expect(message.isRead, equals(false));
        expect(serialized['id'], equals(1));
        expect(serialized['message'], equals('Hello'));
      });
    });

    group('Match', () {
      test('should serialize and deserialize correctly', () {
        // Arrange
        final json = {
          'id': 1,
          'user': {
            'id': 123,
            'first_name': 'Jane',
            'last_name': 'Doe',
          },
          'matched_at': '2024-01-01T00:00:00Z',
        };

        // Act
        final match = Match.fromJson(json);
        final serialized = match.toJson();

        // Assert
        expect(match.id, equals(1));
        expect(match.user?.id, equals(123));
        expect(match.user?.firstName, equals('Jane'));
        expect(serialized['id'], equals(1));
      });
    });

    group('ApiResponse', () {
      test('should serialize and deserialize correctly', () {
        // Arrange
        final json = {
          'status': true,
          'message': 'Success',
          'data': {'id': 1, 'name': 'Test'},
        };

        // Act
        final response = ApiResponse.fromJson(
          json,
          (data) => data as Map<String, dynamic>,
        );

        // Assert
        expect(response.isSuccess, isTrue);
        expect(response.message, equals('Success'));
        expect(response.data, isNotNull);
        expect(response.data?['id'], equals(1));
      });

      test('should handle error response correctly', () {
        // Arrange
        final json = {
          'status': false,
          'message': 'Error occurred',
          'errors': {'field': ['Error message']},
        };

        // Act
        final response = ApiResponse.fromJson(
          json,
          (data) => data as Map<String, dynamic>,
        );

        // Assert
        expect(response.isSuccess, isFalse);
        expect(response.message, equals('Error occurred'));
        expect(response.errors, isNotNull);
      });
    });
  });
}

