// Screen: CommunityForumScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/error_handling/empty_state.dart';
import '../features/community/providers/forum_provider.dart';
import '../features/community/data/models/forum_post.dart';

/// Community forum screen - Community discussions
class CommunityForumScreen extends ConsumerStatefulWidget {
  const CommunityForumScreen({super.key});

  @override
  ConsumerState<CommunityForumScreen> createState() =>
      _CommunityForumScreenState();
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = ref.read(forumPostsProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(forumPostsProvider.notifier).loadPosts(
              category: _selectedCategoryId,
            );
      }
    }
  }

  void _onCategorySelected(int index) {
    final categories = ref.read(forumCategoriesListProvider);
    final categoryId = index == 0 ? null : categories[index - 1].id;
    setState(() {
      _selectedCategoryId = categoryId;
    });
    ref.read(forumPostsProvider.notifier).loadPosts(
          category: categoryId,
          refresh: true,
        );
  }

  int _selectedCategoryIndex(List<ForumCategory> categories) {
    if (_selectedCategoryId == null) return 0;
    final idx = categories.indexWhere((c) => c.id == _selectedCategoryId);
    return idx < 0 ? 0 : idx + 1;
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
          const SnackBar(
            content: Text('Failed to create post. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(ForumPost post) async {
    final success =
        await ref.read(forumPostsProvider.notifier).toggleLike(post.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like. Please try again.'),
        ),
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
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    final postsState = ref.watch(forumPostsProvider);
    final categoriesState = ref.watch(forumCategoriesProvider);
    final categories = ref.watch(forumCategoriesListProvider);
    final categoryLabels = ['All', ...categories.map((c) => c.name)];

    return PremiumDetailScaffold(
      title: 'Community Forum',
      subtitle: 'Join the conversation',
      action: PremiumTapScale(
        onTap: _showCreatePostDialog,
        semanticLabel: 'Create post',
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingSM),
          child: AppSvgIcon(
            assetPath: AppIcons.add,
            size: 22,
            color: textColor,
          ),
        ),
      ),
      body: Column(
        children: [
          if (categoriesState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
              child: PremiumCategoryChips(
                labels: categoryLabels,
                selectedIndex: _selectedCategoryIndex(categories),
                onSelected: _onCategorySelected,
              ),
            ),
          Expanded(
            child: postsState.isLoading && postsState.posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : postsState.posts.isEmpty
                    ? EmptyState(
                        title: 'No Posts',
                        message: 'Be the first to start a discussion!',
                        iconPath: AppIcons.messageCircle,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingLG,
                            vertical: AppSpacing.spacingSM,
                          ),
                          itemCount: postsState.posts.length +
                              (postsState.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == postsState.posts.length) {
                              return const Center(
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(AppSpacing.spacingLG),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final post = postsState.posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.spacingMD,
                              ),
                              child: PremiumShell(
                                margin: EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage:
                                              post.user.avatarUrl != null
                                                  ? CachedNetworkImageProvider(
                                                      post.user.avatarUrl!,
                                                    )
                                                  : null,
                                          child: post.user.avatarUrl == null
                                              ? Text(
                                                  post.user.firstName[0]
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: textColor,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.spacingMD,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      '${post.user.firstName} ${post.user.lastName ?? ''}'
                                                          .trim(),
                                                      style: AppTypography.body
                                                          .copyWith(
                                                        color: textColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (post.user.isVerified) ...[
                                                    const SizedBox(
                                                      width:
                                                          AppSpacing.spacingXS,
                                                    ),
                                                    AppSvgIcon(
                                                      assetPath:
                                                          AppIcons.verify,
                                                      size: 16,
                                                      color:
                                                          AppColors.onlineGreen,
                                                    ),
                                                  ],
                                                  if (post.user.isPremium) ...[
                                                    const SizedBox(
                                                      width:
                                                          AppSpacing.spacingXS,
                                                    ),
                                                    AppSvgIcon(
                                                      assetPath: AppIcons.star,
                                                      size: 16,
                                                      color: AppColors
                                                          .feedbackWarning,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                _formatTime(post.createdAt),
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.spacingSM,
                                            vertical: AppSpacing.spacingXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentViolet
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.radiusSM,
                                            ),
                                          ),
                                          child: Text(
                                            post.category,
                                            style: AppTypography.caption
                                                .copyWith(
                                              color: AppColors.accentViolet,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.spacingMD,
                                    ),
                                    Text(
                                      post.title,
                                      style: AppTypography.h3.copyWith(
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.spacingSM,
                                    ),
                                    Text(
                                      post.content,
                                      style: AppTypography.body.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.spacingMD,
                                    ),
                                    const DividerCustom(),
                                    Row(
                                      children: [
                                        PremiumTapScale(
                                          onTap: () => _toggleLike(post),
                                          semanticLabel: post.isLikedByUser
                                              ? 'Unlike post'
                                              : 'Like post',
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                              AppSpacing.spacingSM,
                                            ),
                                            child: AppSvgIcon(
                                              assetPath: AppIcons.heart,
                                              size: 20,
                                              color: post.isLikedByUser
                                                  ? AppColors.feedbackError
                                                  : secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${post.likesCount}',
                                          style: AppTypography.caption.copyWith(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.spacingLG,
                                        ),
                                        AppSvgIcon(
                                          assetPath: AppIcons.commentOutlined,
                                          size: 20,
                                          color: secondaryTextColor,
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.spacingXS,
                                        ),
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
  const CreatePostDialog({super.key});

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
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final categories = ref.watch(forumCategoriesListProvider);

    return AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      title: Text(
        'Create New Post',
        style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
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
                    borderRadius:
                        BorderRadius.circular(AppRadius.radiusSM),
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
              const SizedBox(height: AppSpacing.spacingMD),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.radiusSM),
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
              const SizedBox(height: AppSpacing.spacingMD),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Content',
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.radiusSM),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitPost,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post'),
        ),
      ],
    );
  }
}
