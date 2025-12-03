// Screen: LikesReceivedScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/avatar/avatar_with_status.dart';
import '../../widgets/badges/verification_badge.dart';
import '../../widgets/badges/premium_badge.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/buttons/like_button.dart';
import '../../widgets/buttons/dislike_button.dart';
import '../../widgets/error_handling/empty_state.dart';
import '../../widgets/loading/skeleton_loader.dart';
import '../../widgets/modals/bottom_sheet_custom.dart';
import '../discovery/profile_detail_screen.dart';

/// Likes received screen - View users who liked you
class LikesReceivedScreen extends ConsumerStatefulWidget {
  const LikesReceivedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LikesReceivedScreen> createState() => _LikesReceivedScreenState();
}

class _LikesReceivedScreenState extends ConsumerState<LikesReceivedScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _likes = [];

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load likes from API
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _likes = [
          {
            'id': 1,
            'name': 'Alex',
            'age': 28,
            'avatar_url': 'https://via.placeholder.com/200',
            'bio': 'Love traveling and exploring new places!',
            'is_verified': true,
            'is_premium': false,
            'distance': 5.2,
            'liked_at': DateTime.now().subtract(const Duration(hours: 2)),
          },
          {
            'id': 2,
            'name': 'Jordan',
            'age': 25,
            'avatar_url': 'https://via.placeholder.com/200',
            'bio': 'Music lover and coffee enthusiast',
            'is_verified': false,
            'is_premium': true,
            'distance': 12.5,
            'liked_at': DateTime.now().subtract(const Duration(days: 1)),
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

  void _handleLike(int userId) {
    // TODO: Send like action to API
    setState(() {
      _likes.removeWhere((like) => like['id'] == userId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('It\'s a match!')),
    );
  }

  void _handleDislike(int userId) {
    // TODO: Send dislike action to API
    setState(() {
      _likes.removeWhere((like) => like['id'] == userId);
    });
  }

  void _handleProfileTap(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(userId: userId),
      ),
    );
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Likes You',
        showBackButton: true,
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 5,
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 200,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                );
              },
            )
          : _likes.isEmpty
              ? EmptyState(
                  title: 'No Likes Yet',
                  message: 'Keep swiping to get more likes!',
                  icon: Icons.favorite_border,
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  itemCount: _likes.length,
                  itemBuilder: (context, index) {
                    final like = _likes[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User info
                          InkWell(
                            onTap: () => _handleProfileTap(like['id']),
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.spacingLG),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      AvatarWithStatus(
                                        imageUrl: like['avatar_url'],
                                        name: like['name'],
                                        isOnline: false,
                                        size: 64.0,
                                      ),
                                      if (like['is_verified'] == true)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: VerificationBadge(
                                            isVerified: true,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(width: AppSpacing.spacingMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${like['name']}, ${like['age']}',
                                                style: AppTypography.h3.copyWith(
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            if (like['is_premium'] == true)
                                              PremiumBadge(
                                                isPremium: true,
                                                fontSize: 10,
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: AppSpacing.spacingXS),
                                        if (like['distance'] != null)
                                          Text(
                                            '${like['distance'].toStringAsFixed(1)} km away',
                                            style: AppTypography.caption.copyWith(
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        SizedBox(height: AppSpacing.spacingXS),
                                        Text(
                                          'Liked you ${_formatTime(like['liked_at'])}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.accentPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Bio preview
                          if (like['bio'] != null && like['bio'].toString().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacingLG,
                                vertical: AppSpacing.spacingSM,
                              ),
                              child: Text(
                                like['bio'],
                                style: AppTypography.body.copyWith(
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          DividerCustom(),
                          // Action buttons
                          Padding(
                            padding: EdgeInsets.all(AppSpacing.spacingMD),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: DislikeButton(
                                    onTap: () => _handleDislike(like['id']),
                                    size: 56.0,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.spacingMD),
                                Expanded(
                                  child: LikeButton(
                                    onTap: () => _handleLike(like['id']),
                                    size: 56.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
