import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/core/services/api_service.dart';
import 'package:lgbtindernew/core/services/token_storage_service.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';
import '../models/forum_post.dart';

class ForumService {
  final ApiService _apiService;
  final TokenStorageService _tokenStorage;

  ForumService(this._apiService, this._tokenStorage);

  /// Get forum posts with pagination and optional category filter
  Future<ApiResponse<Map<String, dynamic>>> getForumPosts({
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
    if (category != null && category != 'all') {
      queryParams['category'] = category;
    }

    return _apiService.get<Map<String, dynamic>>(
      '/community-forums',
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get a specific forum post with comments
  Future<ApiResponse<Map<String, dynamic>>> getForumPost(int postId) async {
    return _apiService.get<Map<String, dynamic>>(
      '/community-forums/$postId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Create a new forum post
  Future<ApiResponse<Map<String, dynamic>>> createForumPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'category': category,
    };

    return _apiService.post<Map<String, dynamic>>(
      '/community-forums',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Update a forum post
  Future<ApiResponse<Map<String, dynamic>>> updateForumPost({
    required int postId,
    required String title,
    required String content,
    required String category,
  }) async {
    final data = {
      'title': title,
      'content': content,
      'category': category,
    };

    return _apiService.put<Map<String, dynamic>>(
      '/community-forums/$postId',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Delete a forum post
  Future<ApiResponse<Map<String, dynamic>>> deleteForumPost(int postId) async {
    return _apiService.delete<Map<String, dynamic>>(
      '/community-forums/$postId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Toggle like on a forum post
  Future<ApiResponse<Map<String, dynamic>>> toggleLike(int postId) async {
    return _apiService.post<Map<String, dynamic>>(
      '/community-forums/$postId/like',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Add a comment to a forum post
  Future<ApiResponse<Map<String, dynamic>>> addComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    final data = {'content': content};
    if (parentId != null) {
      data['parent_id'] = parentId;
    }

    return _apiService.post<Map<String, dynamic>>(
      '/community-forums/$postId/comments',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get forum categories
  Future<ApiResponse<Map<String, dynamic>>> getCategories() async {
    return _apiService.get<Map<String, dynamic>>(
      '/community-forums/categories',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}

// Provider for ForumService
final forumServiceProvider = Provider<ForumService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return ForumService(apiService, tokenStorage);
});
