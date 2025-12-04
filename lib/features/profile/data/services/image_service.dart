import 'dart:io';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/models/api_response.dart';
import '../models/user_image.dart';

/// Image management service
class ImageService {
  final ApiService _apiService;

  ImageService(this._apiService);

  /// Upload image
  Future<UserImage> uploadImage(File imageFile, {String type = 'gallery'}) async {
    try {
      ApiResponse<Map<String, dynamic>> response;
      
      if (type == 'primary' || type == 'profile') {
        // Use profile pictures endpoint for primary/profile images
        response = await _apiService.uploadFile<Map<String, dynamic>>(
          ApiEndpoints.profilePicturesUpload,
          imageFile,
          fieldName: 'image',
          fields: {'is_primary': '1'}, // Send as string '1' for true (Laravel boolean validation accepts '1'/'0')
          fromJson: (json) => json as Map<String, dynamic>,
        );
        
        if (response.isSuccess && response.data != null) {
          // Profile picture response structure: {image: {id, sizes}}
          final imageData = response.data!['image'] as Map<String, dynamic>;
          final sizes = imageData['sizes'] as Map<String, dynamic>?;
          final imageUrl = sizes?['full'] ?? sizes?['250x250'] ?? '';
          return UserImage(
            id: imageData['id'] as int,
            userId: 0, // Will be set by backend
            path: imageUrl is String ? imageUrl : '',
            type: 'profile',
            order: 0,
            isPrimary: true,
            sizes: sizes,
          );
        } else {
          throw Exception(response.message);
        }
      } else {
        // Use images endpoint for gallery images (requires array)
        // Backend expects 'images' as an array, so we use uploadFiles even for single file
        response = await _apiService.uploadFiles<Map<String, dynamic>>(
          ApiEndpoints.imagesUpload,
          [imageFile], // Single file as array
          fieldName: 'images',
          fields: {'type': 'gallery'},
          fromJson: (json) => json as Map<String, dynamic>,
        );
        
        if (response.isSuccess && response.data != null) {
          // Images response structure: {images: [{id, url}]}
          final imagesList = response.data!['images'] as List<dynamic>;
          if (imagesList.isNotEmpty) {
            final imageData = imagesList.first as Map<String, dynamic>;
            return UserImage.fromJson({
              'id': imageData['id'],
              'url': imageData['url'],
              'type': 'gallery',
              'is_primary': false,
            });
          } else {
            throw Exception('No image returned from server');
          }
        } else {
          throw Exception(response.message);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete image
  Future<void> deleteImage(int imageId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.imagesById(imageId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reorder images
  Future<void> reorderImages(List<int> imageOrder) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.imagesReorder,
        data: {'image_order': imageOrder},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Set primary image
  /// [isProfilePicture] - true if this is a profile picture, false for gallery image
  Future<void> setPrimaryImage(int imageId, {bool isProfilePicture = false}) async {
    try {
      final endpoint = isProfilePicture 
          ? ApiEndpoints.profilePicturesSetPrimary(imageId)
          : ApiEndpoints.imagesSetPrimary(imageId);
      
      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}

