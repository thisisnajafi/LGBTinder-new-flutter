import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/features/community/data/models/forum_post.dart';
import 'package:lgbtindernew/features/community/data/services/forum_service.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

// State for forum posts
class ForumPostsState {
  final List<ForumPost> posts;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ForumPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ForumPostsState copyWith({
    List<ForumPost>? posts,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ForumPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

// Notifier for forum posts
class ForumPostsNotifier extends StateNotifier<ForumPostsState> {
  final ForumService _forumService;

  ForumPostsNotifier(this._forumService) : super(const ForumPostsState());

  Future<void> loadPosts({String? category, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        posts: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      );
    }

    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _forumService.getForumPosts(
        category: category,
        page: refresh ? 1 : state.currentPage,
        perPage: 20,
      );

      if (response.isSuccess && response.data != null) {
        final postsData = response.data!['posts']['data'] as List;
        final posts = postsData.map((json) => ForumPost.fromJson(json)).toList();

        final hasMore = response.data!['posts']['current_page'] <
                       response.data!['posts']['last_page'];

        state = state.copyWith(
          posts: refresh ? posts : [...state.posts, ...posts],
          currentPage: refresh ? 2 : state.currentPage + 1,
          hasMore: hasMore,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final response = await _forumService.createForumPost(
        title: title,
        content: content,
        category: category,
      );

      if (response.isSuccess && response.data != null) {
        final newPost = ForumPost.fromJson(response.data!['post']);
        state = state.copyWith(
          posts: [newPost, ...state.posts],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleLike(int postId) async {
    try {
      final response = await _forumService.toggleLike(postId);

      if (response.isSuccess && response.data != null) {
        final updatedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isLikedByUser: response.data!['liked'],
              likesCount: response.data!['likes_count'],
            );
          }
          return post;
        }).toList();

        state = state.copyWith(posts: updatedPosts);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// State for forum categories
class ForumCategoriesState {
  final List<ForumCategory> categories;
  final bool isLoading;
  final String? error;

  const ForumCategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  ForumCategoriesState copyWith({
    List<ForumCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return ForumCategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier for forum categories
class ForumCategoriesNotifier extends StateNotifier<ForumCategoriesState> {
  final ForumService _forumService;

  ForumCategoriesNotifier(this._forumService) : super(const ForumCategoriesState());

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _forumService.getCategories();

      if (response.isSuccess && response.data != null) {
        final categoriesData = response.data!['categories'] as List;
        final categories = categoriesData
            .map((json) => ForumCategory.fromJson(json))
            .toList();

        state = state.copyWith(
          categories: categories,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Providers
final forumPostsProvider =
    StateNotifierProvider<ForumPostsNotifier, ForumPostsState>((ref) {
  final forumService = ref.watch(forumServiceProvider);
  return ForumPostsNotifier(forumService);
});

final forumCategoriesProvider =
    StateNotifierProvider<ForumCategoriesNotifier, ForumCategoriesState>((ref) {
  final forumService = ref.watch(forumServiceProvider);
  return ForumCategoriesNotifier(forumService);
});

// Filtered posts provider
final filteredForumPostsProvider = Provider<List<ForumPost>>((ref) {
  final state = ref.watch(forumPostsProvider);
  return state.posts;
});

// Categories provider
final forumCategoriesListProvider = Provider<List<ForumCategory>>((ref) {
  final state = ref.watch(forumCategoriesProvider);
  return state.categories;
});
