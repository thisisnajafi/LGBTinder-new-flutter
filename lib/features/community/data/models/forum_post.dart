import 'package:freezed_annotation/freezed_annotation.dart';

part 'forum_post.freezed.dart';
part 'forum_post.g.dart';

@freezed
class ForumPost with _$ForumPost {
  const factory ForumPost({
    required int id,
    required int userId,
    required String title,
    required String content,
    required String category,
    @Default(false) bool isPinned,
    @Default(false) bool isLocked,
    @Default(0) int viewsCount,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default('active') String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ForumUser user,
    @Default([]) List<ForumComment> comments,
    @Default(false) bool isLikedByUser,
  }) = _ForumPost;

  factory ForumPost.fromJson(Map<String, dynamic> json) =>
      _$ForumPostFromJson(json);
}

@freezed
class ForumUser with _$ForumUser {
  const factory ForumUser({
    required int id,
    required String firstName,
    String? lastName,
    String? avatarUrl,
    @Default(false) bool isVerified,
    @Default(false) bool isPremium,
  }) = _ForumUser;

  factory ForumUser.fromJson(Map<String, dynamic> json) =>
      _$ForumUserFromJson(json);
}

@freezed
class ForumComment with _$ForumComment {
  const factory ForumComment({
    required int id,
    required int forumPostId,
    required int userId,
    required String content,
    int? parentId,
    @Default('active') String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ForumUser user,
  }) = _ForumComment;

  factory ForumComment.fromJson(Map<String, dynamic> json) =>
      _$ForumCommentFromJson(json);
}

@freezed
class ForumCategory with _$ForumCategory {
  const factory ForumCategory({
    required String id,
    required String name,
    required String description,
  }) = _ForumCategory;

  factory ForumCategory.fromJson(Map<String, dynamic> json) =>
      _$ForumCategoryFromJson(json);
}
