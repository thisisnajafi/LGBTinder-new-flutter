// Screen: CommunityForumScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../widgets/buttons/gradient_button.dart';
import '../features/community/providers/forum_provider.dart';
import '../features/community/data/models/forum_post.dart';

/// Community forum screen - Community discussions
class CommunityForumScreen extends ConsumerStatefulWidget {
  const CommunityForumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends ConsumerState<CommunityForumScreen> {
  String? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final state = ref.read(forumPostsProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(forumPostsProvider.notifier).loadPosts(
          category: _selectedCategoryId,
        );
      }
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    ref.read(forumPostsProvider.notifier).loadPosts(
      category: categoryId,
      refresh: true,
    );
  }

  Future<void> _showCreatePostDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreatePostDialog(),
    );

    if (result != null) {
      final success = await ref.read(forumPostsProvider.notifier).createPost(
        title: result['title']!,
        content: result['content']!,
        category: result['category']!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post. Please try again.')),
        );
      }
    }
  }

  Future<void> _toggleLike(ForumPost post) async {
    final success = await ref.read(forumPostsProvider.notifier).toggleLike(post.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like. Please try again.')),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final postsState = ref.watch(forumPostsProvider);
    final categoriesState = ref.watch(forumCategoriesProvider);
    final categories = ref.watch(forumCategoriesListProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Community Forum',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: _showCreatePostDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          if (categoriesState.isLoading)
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (categories.isNotEmpty)
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                itemCount: categories.length + 1, // +1 for "All" category
                itemBuilder: (context, index) {
                  final categoryId = index == 0 ? null : categories[index - 1].id;
                  final categoryName = index == 0 ? 'All' : categories[index - 1].name;
                  final isSelected = _selectedCategoryId == categoryId;

                  return Padding(
                    padding: EdgeInsets.only(right: AppSpacing.spacingSM),
                    child: GestureDetector(
                      onTap: () => _onCategorySelected(categoryId),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingMD,
                          vertical: AppSpacing.spacingSM,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentPurple.withOpacity(0.2)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentPurple
                                : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          categoryName,
                          style: AppTypography.body.copyWith(
                            color: isSelected
                                ? AppColors.accentPurple
                                : textColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: postsState.isLoading && postsState.posts.isEmpty
                ? Center(child: CircularProgressIndicator())
                : postsState.posts.isEmpty
                    ? EmptyState(
                        title: 'No Posts',
                        message: 'Be the first to start a discussion!',
                        icon: Icons.forum,
                        actionLabel: 'Create Post',
                        onAction: _showCreatePostDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(forumPostsProvider.notifier).loadPosts(
                            category: _selectedCategoryId,
                            refresh: true,
                          );
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(AppSpacing.spacingLG),
                          itemCount: postsState.posts.length + (postsState.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == postsState.posts.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final post = postsState.posts[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.spacingLG),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: post.user.avatarUrl != null
                                                ? CachedNetworkImageProvider(post.user.avatarUrl!)
                                                : null,
                                            child: post.user.avatarUrl == null
                                                ? Text(
                                                    post.user.firstName[0].toUpperCase(),
                                                    style: TextStyle(color: textColor),
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: AppSpacing.spacingMD),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${post.user.firstName} ${post.user.lastName ?? ''}'.trim(),
                                                      style: AppTypography.bodyBold.copyWith(
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    if (post.user.isVerified) ...[
                                                      SizedBox(width: AppSpacing.spacingXS),
                                                      Icon(
                                                        Icons.verified,
                                                        size: 16,
                                                        color: AppColors.onlineGreen,
                                                      ),
                                                    ],
                                                    if (post.user.isPremium) ...[
                                                      SizedBox(width: AppSpacing.spacingXS),
                                                      Icon(
                                                        Icons.star,
                                                        size: 16,
                                                        color: AppColors.warningYellow,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Text(
                                                  _formatTime(post.createdAt),
                                                  style: AppTypography.caption.copyWith(
                                                    color: secondaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.spacingSM,
                                              vertical: AppSpacing.spacingXS,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentPurple.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                            ),
                                            child: Text(
                                              post.category,
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.accentPurple,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: AppSpacing.spacingMD),
                                      // Title
                                      Text(
                                        post.title,
                                        style: AppTypography.headline.copyWith(
                                          color: textColor,
                                        ),
                                      ),
                                      SizedBox(height: AppSpacing.spacingSM),
                                      // Content
                                      Text(
                                        post.content,
                                        style: AppTypography.body.copyWith(
                                          color: secondaryTextColor,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: AppSpacing.spacingMD),
                                      DividerCustom(),
                                      // Actions
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                                              size: 20,
                                              color: post.isLikedByUser ? AppColors.notificationRed : secondaryTextColor,
                                            ),
                                            onPressed: () => _toggleLike(post),
                                          ),
                                          Text(
                                            '${post.likesCount}',
                                            style: AppTypography.caption.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.spacingLG),
                                          Icon(
                                            Icons.comment_outlined,
                                            size: 20,
                                            color: secondaryTextColor,
                                          ),
                                          SizedBox(width: AppSpacing.spacingXS),
                                          Text(
                                            '${post.commentsCount}',
                                            style: AppTypography.caption.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for creating a new forum post
class CreatePostDialog extends ConsumerStatefulWidget {
  const CreatePostDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends ConsumerState<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Return the form data
    if (mounted) {
      Navigator.of(context).pop({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategoryId!,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final categories = ref.watch(forumCategoriesListProvider);

    return AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Create New Post',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: textColor,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter your post title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Title is required';
                  }
                  if (value!.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Content',
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Content is required';
                  }
                  if (value!.length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitPost,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Post'),
        ),
      ],
    );
  }
}