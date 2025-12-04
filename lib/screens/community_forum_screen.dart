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
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumCategoriesProvider.notifier).loadCategories();
      ref.read(forumPostsProvider.notifier).loadPosts();
    });

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

    final filteredPosts = _selectedCategory == 0
        ? _posts
        : _posts.where((post) => post['category'] == _categories[_selectedCategory]).toList();

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
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Create Post',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  content: Text(
                    'Community forums are coming soon! This feature will allow you to share experiences, ask questions, and connect with the LGBTinder community.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.spacingSM),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = index;
                      });
                    },
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
                        _categories[index],
                        style: AppTypography.body.copyWith(
                          color: isSelected
                              ? AppColors.accentPurple
                              : textColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          DividerCustom(),
          // Posts list
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 5,
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 150,
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        ),
                      );
                    },
                  )
                : filteredPosts.isEmpty
                    ? EmptyState(
                        title: 'No Posts',
                        message: 'Be the first to start a discussion!',
                        icon: Icons.forum,
                        actionLabel: 'Create Post',
                        onAction: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'Create Post',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              content: Text(
                                'Community forums are coming soon! This feature will allow you to share experiences, ask questions, and connect with the LGBTinder community.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                            padding: EdgeInsets.all(AppSpacing.spacingLG),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    AvatarWithStatus(
                                      imageUrl: post['author_avatar'],
                                      name: post['author'],
                                      isOnline: false,
                                      size: 40.0,
                                    ),
                                    SizedBox(width: AppSpacing.spacingMD),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post['author'],
                                            style: AppTypography.body.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _formatTime(post['created_at']),
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
                                        post['category'],
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.accentPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.spacingMD),
                                // Title
                                Text(
                                  post['title'],
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.spacingSM),
                                // Content
                                Text(
                                  post['content'],
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
                                    Icon(
                                      Icons.favorite_border,
                                      size: 20,
                                      color: secondaryTextColor,
                                    ),
                                    SizedBox(width: AppSpacing.spacingXS),
                                    Text(
                                      '${post['likes']}',
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
                                      '${post['comments']}',
                                      style: AppTypography.caption.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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
