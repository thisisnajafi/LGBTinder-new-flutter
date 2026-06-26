// Screen: LikesReceivedScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/providers/api_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../features/profile/widgets/tier_badge.dart';
import '../../routes/app_router.dart';
import '../../shared/utils/plan_guard.dart';
import '../../widgets/badges/verification_badge.dart';
import '../../widgets/discovery/discovery_swipe_action_button.dart';
import '../../widgets/error_handling/empty_state.dart';
import '../../widgets/loading/skeleton_loader.dart';
import 'profile_detail_screen.dart';

/// Likes received — premium list of users who liked you (accept / pass).
class LikesReceivedScreen extends ConsumerStatefulWidget {
  const LikesReceivedScreen({super.key});

  @override
  ConsumerState<LikesReceivedScreen> createState() =>
      _LikesReceivedScreenState();
}

class _LikesReceivedScreenState extends ConsumerState<LikesReceivedScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _likes = [];

  @override
  void initState() {
    super.initState();
    _guardAndLoad();
  }

  Future<void> _guardAndLoad() async {
    try {
      final service = ref.read(planLimitsServiceProvider);
      final guard = PlanGuard(service);
      final result = await guard.canSeeWhoLikedMe();
      if (!mounted) return;
      if (!result.isAllowed) {
        final target = Uri(
          path: AppRoutes.featureLocked,
          queryParameters: {
            'title': 'See who liked you',
            'desc':
                'Unlock this feature to view everyone who has liked your profile.',
            'minTier': 'silder',
          },
        ).toString();
        context.push(target);
        return;
      }
    } catch (_) {
      // If guard fails, do not block the user.
    }
    await _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.likesPending,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        final pendingLikes = data?['pending_likes'] as List<dynamic>? ?? [];

        setState(() {
          _likes = pendingLikes.map((like) {
            final user = like['user'] as Map<String, dynamic>;
            return {
              'id': like['id'],
              'user_id': user['id'],
              'name': user['name'],
              'avatar_url': user['avatar_url'],
              'is_verified': user['is_verified'] ?? false,
              'is_premium': user['is_premium'] ?? false,
              'liked_at': DateTime.parse(like['created_at'] as String),
              'age': user['age'],
              'distance': user['distance'],
              'bio': user['bio'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _likes = [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _likes = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLike(int likeId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesRespond,
        data: {'like_id': likeId, 'action': 'accept'},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        setState(() => _likes.removeWhere((like) => like['id'] == likeId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('It\'s a match!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept like: ${response.message}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept like: $e'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    }
  }

  Future<void> _handleDislike(int likeId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesRespond,
        data: {'like_id': likeId, 'action': 'reject'},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        setState(() => _likes.removeWhere((like) => like['id'] == likeId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject like: ${response.message}'),
            backgroundColor: AppColors.feedbackError,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject like: $e'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    }
  }

  void _handleProfileTap(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProfileDetailScreen(
          userId: userId,
          showInteractionActions: true,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSettingsDetailScaffold(
      title: 'Likes you',
      subtitle: 'People who liked your profile',
      action: IconButton(
        icon: AppSvgIcon(
          assetPath: AppIcons.getIconPath('refresh'),
          size: 22,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: _guardAndLoad,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
              child: SkeletonLoader(
                width: double.infinity,
                height: 168,
                borderRadius: BorderRadius.circular(AppRadius.radiusXL),
              ),
            ),
        ],
      );
    }

    if (_likes.isEmpty) {
      return EmptyState(
        title: 'No likes yet',
        message: 'Keep swiping to get more likes!',
        iconPath: AppIcons.heart,
        actionLabel: 'Start discovering',
        onAction: () => context.go('${AppRoutes.home}/discovery'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLikes,
      child: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Pending likes',
            subtitle:
                '${_likes.length} ${_likes.length == 1 ? 'person' : 'people'}',
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            children: [
              for (final like in _likes)
                _LikeCard(
                  like: like,
                  formatTime: _formatTime,
                  onProfileTap: () =>
                      _handleProfileTap(like['user_id'] as int),
                  onPass: () => _handleDislike(like['id'] as int),
                  onAccept: () => _handleLike(like['id'] as int),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.like,
    required this.formatTime,
    required this.onProfileTap,
    required this.onPass,
    required this.onAccept,
  });

  final Map<String, dynamic> like;
  final String Function(DateTime) formatTime;
  final VoidCallback onProfileTap;
  final VoidCallback onPass;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = like['name']?.toString() ?? 'User';
    final age = like['age'];
    final title = age != null ? '$name, $age' : name;
    final bio = like['bio']?.toString();
    final distance = like['distance'];
    final likedAt = like['liked_at'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: AppColors.accentPink.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTapScale(
              onTap: onProfileTap,
              semanticLabel: 'View $name\'s profile',
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacingMD),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipOval(
                          child: ProfileImageWidget(
                            imageUrl: like['avatar_url'] as String?,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (like['is_verified'] == true)
                          const Positioned(
                            right: -2,
                            top: -2,
                            child: VerificationBadge(isVerified: true, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (like['is_premium'] == true)
                                TierBadge.fromPremium(true),
                            ],
                          ),
                          if (distance != null) ...[
                            const SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              '${(distance as num).toStringAsFixed(1)} km away',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.spacingXS),
                          Text(
                            'Liked you ${formatTime(likedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.accentRose,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSvgIcon(
                      assetPath: AppIcons.getIconPath('arrow-right-3'),
                      size: 18,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
            if (bio != null && bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacingMD,
                  0,
                  AppSpacing.spacingMD,
                  AppSpacing.spacingSM,
                ),
                child: Text(
                  bio,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Divider(
              height: 1,
              color: AppColors.accentViolet.withValues(alpha: 0.12),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingLG,
                vertical: AppSpacing.spacingMD,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DiscoverySwipeActionButton(
                    type: DiscoverySwipeActionType.dislike,
                    size: 52,
                    onPressed: onPass,
                  ),
                  const SizedBox(width: AppSpacing.spacingXL),
                  DiscoverySwipeActionButton(
                    type: DiscoverySwipeActionType.like,
                    size: 52,
                    onPressed: onAccept,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
