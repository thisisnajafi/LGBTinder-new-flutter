/// Unit tests for ImageService
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/profile/data/services/image_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'image_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late ImageService imageService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    imageService = ImageService(mockApiService);
  });

  group('ImageService', () {
    group('uploadImage', () {
      test('should return UserImage on successful upload', () async {
        // Arrange
        final imageFile = File('test_image.jpg');
        final responseData = {
          'id': 1,
          'image_url': 'https://example.com/image.jpg',
          'is_primary': false,
          'order': 1,
        };

        when(mockApiService.uploadFile<Map<String, dynamic>>(
          any,
          any,
          fieldName: anyNamed('fieldName'),
          fields: anyNamed('fields'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: responseData,
          message: 'Image uploaded',
        ));

        // Act
        final result = await imageService.uploadImage(imageFile, type: 'gallery');

        // Assert
        expect(result, isNotNull);
        expect(result.id, equals(1));
        expect(result.imageUrl, equals('https://example.com/image.jpg'));
        verify(mockApiService.uploadFile<Map<String, dynamic>>(
          any,
          any,
          fieldName: anyNamed('fieldName'),
          fields: anyNamed('fields'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed upload', () async {
        // Arrange
        final imageFile = File('test_image.jpg');

        when(mockApiService.uploadFile<Map<String, dynamic>>(
          any,
          any,
          fieldName: anyNamed('fieldName'),
          fields: anyNamed('fields'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Upload failed',
        ));

        // Act & Assert
        expect(
          () => imageService.uploadImage(imageFile),
          throwsException,
        );
      });
    });

    group('deleteImage', () {
      test('should complete successfully on delete', () async {
        // Arrange
        const imageId = 123;

        when(mockApiService.delete<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'Image deleted',
        ));

        // Act
        await imageService.deleteImage(imageId);

        // Assert
        verify(mockApiService.delete<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed delete', () async {
        // Arrange
        const imageId = 123;

        when(mockApiService.delete<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Delete failed',
        ));

        // Act & Assert
        expect(
          () => imageService.deleteImage(imageId),
          throwsException,
        );
      });
    });

    group('reorderImages', () {
      test('should complete successfully on reorder', () async {
        // Arrange
        final imageOrder = [3, 1, 2, 4];

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'Images reordered',
        ));

        // Act
        await imageService.reorderImages(imageOrder);

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed reorder', () async {
        // Arrange
        final imageOrder = [3, 1, 2, 4];

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Reorder failed',
        ));

        // Act & Assert
        expect(
          () => imageService.reorderImages(imageOrder),
          throwsException,
        );
      });
    });

    group('setPrimaryImage', () {
      test('should complete successfully on set primary', () async {
        // Arrange
        const imageId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: true,
          data: {},
          message: 'Primary image set',
        ));

        // Act
        await imageService.setPrimaryImage(imageId);

        // Assert
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed set primary', () async {
        // Arrange
        const imageId = 123;

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          isSuccess: false,
          data: null,
          message: 'Set primary failed',
        ));

        // Act & Assert
        expect(
          () => imageService.setPrimaryImage(imageId),
          throwsException,
        );
      });
    });
  });
}

