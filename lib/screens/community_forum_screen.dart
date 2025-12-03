// Screen: CommunityForumScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/avatar/avatar_with_status.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';

/// Community forum screen - Community discussions
class CommunityForumScreen extends ConsumerStatefulWidget {
  const CommunityForumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends ConsumerState<CommunityForumScreen> {
  int _selectedCategory = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = [];

  final List<String> _categories = ['All', 'General', 'Dating Tips', 'Events', 'Support'];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load posts from API
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _posts = [
          {
            'id': 1,
            'title': 'Welcome to the Community!',
            'content': 'This is a safe space for our community to connect and share experiences.',
            'author': 'LGBTinder Team',
            'author_avatar': null,
            'category': 'General',
            'likes': 42,
            'comments': 12,
            'created_at': DateTime.now().subtract(const Duration(hours: 2)),
          },
          {
            'id': 2,
            'title': 'Dating Tips for First Dates',
            'content': 'Share your best tips for making a great first impression!',
            'author': 'Alex',
            'author_avatar': 'https://via.placeholder.com/100',
            'category': 'Dating Tips',
            'likes': 28,
            'comments': 8,
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
              // TODO: Open create post screen
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
                          // TODO: Open create post screen
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
