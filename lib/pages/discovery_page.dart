// Screen: DiscoveryPage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/cards/card_stack_manager.dart';
import '../core/widgets/loading_indicator.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_discovery.dart';
import '../features/discover/providers/discover_cache_provider.dart';
import '../features/discover/providers/discovery_providers.dart';
import '../features/discover/data/models/discovery_profile.dart';
import '../features/profile/providers/profile_page_cache_provider.dart';
import '../features/matching/providers/likes_providers.dart';
import '../features/matching/data/models/match.dart' as match_models;
import '../features/payments/providers/payment_providers.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../widgets/premium/upgrade_dialog.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../screens/discovery/profile_detail_screen.dart';
import '../screens/discovery/filter_screen.dart';
import '../screens/premium/superlike_packs_screen.dart';
import '../pages/chat_page.dart';
import '../features/chat/providers/chat_providers.dart';
import '../core/utils/app_icons.dart';
import '../widgets/buttons/scale_tap_feedback.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/user/providers/user_providers.dart';

/// Discovery page - Main swiping/discovery screen
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({
    Key? key,
    this.selectedTabIndex,
    this.discoveryTabIndex,
  }) : super(key: key);

  /// When used inside a tab shell (e.g. HomePage), pass current tab index so we call nearby-suggestions when user switches to this tab.
  final int? selectedTabIndex;
  final int? discoveryTabIndex;

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  // Filter state
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profilePageCacheProvider.notifier).refresh();
      ref.read(discoverCacheProvider.notifier).refresh(filters: _activeFilters);
    });
  }

  @override
  void didUpdateWidget(DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowSelected = widget.selectedTabIndex != null &&
        widget.discoveryTabIndex != null &&
        widget.selectedTabIndex == widget.discoveryTabIndex;
    final wasSelected = oldWidget.selectedTabIndex != null &&
        oldWidget.discoveryTabIndex != null &&
        oldWidget.selectedTabIndex == oldWidget.discoveryTabIndex;
    if (nowSelected && !wasSelected) {
      ref.read(profilePageCacheProvider.notifier).refresh();
      ref.read(discoverCacheProvider.notifier).refresh(filters: _activeFilters);
      ref.read(discoverCacheProvider.notifier).fetchMoreIfNeeded(
        threshold: kDiscoverStackBufferThreshold,
        filters: _activeFilters,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildAvatarPlaceholder(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Icon(
        Icons.person,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        size: 24,
      ),
    );
  }

  Widget _buildAvatarFrame(Color backgroundColor, bool isDark, {required Widget child}) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.prideGradient,
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  /// App bar user row (used when cached user is loading/error — fallback to auth user)
  Widget _buildAppBarUserRow(
    BuildContext context,
    Color backgroundColor,
    bool isDark, {
    String? avatarUrl,
    required String name,
  }) {
    return Row(
      children: [
        _buildAvatarFrame(
          backgroundColor,
          isDark,
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarPlaceholder(isDark);
                  },
                )
              : _buildAvatarPlaceholder(isDark),
        ),
        SizedBox(width: AppSpacing.spacingMD),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              name,
              style: AppTypography.h3.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required List<Color> gradientColors,
    required String icon,
    required VoidCallback onPressed,
  }) {
    final baseColor = gradientColors.first;
    return ScaleTapFeedback(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AppSvgIcon(
            assetPath: icon,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _handleAction(String action) {
    final stack = ref.read(discoverCacheProvider).stack;
    if (stack.isEmpty) return;

    final userId = stack.first.id;

    switch (action) {
      case 'like':
      case 'dislike':
        _handleSwipe(userId, action, fromRow: true);
        break;
      case 'superlike':
        _showSuperlikeBottomSheet(userId);
        break;
      case 'message':
        _handleCardTap(userId);
        break;
    }
  }

  void _showSuperlikeBottomSheet(int userId) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasText = controller.text.trim().isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Send a Super Like',
                        style: AppTypography.h3.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      Text(
                        'Add a message to stand out (required)',
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      SizedBox(height: AppSpacing.spacingLG),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: hasText
                                ? () {
                                    final message = controller.text.trim();
                                    Navigator.pop(context);
                                    _handleSwipe(userId, 'superlike', fromRow: true);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Super Like sent!'),
                                          backgroundColor: AppColors.onlineGreen,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warningYellow,
                              foregroundColor: Colors.black87,
                            ),
                            child: const Text('Send Super Like'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  Map<String, dynamic> _profileToCardMap(DiscoveryProfile profile) {
    return {
      'id': profile.id,
      'name': profile.firstName,
      'age': profile.age,
      'location': profile.city != null && profile.country != null
          ? '${profile.city}, ${profile.country}'
          : profile.city ?? profile.country ?? '',
      'avatar_url': profile.primaryImageUrl ?? profile.imageUrls?.first,
      'image_urls': profile.imageUrls ?? [profile.primaryImageUrl].whereType<String>().toList(),
      'bio': profile.profileBio ?? '',
      'is_verified': profile?.isVerified ?? false,
      'is_premium': profile?.isPremium ?? false,
      'distance': profile.distance,
      'compatibility_score': profile.compatibilityScore,
      'is_superliked': profile.isSuperliked ?? false,
    };
  }

  Future<void> _handleSwipe(int userId, String action, {bool fromRow = false}) async {
    final planLimitsService = ref.read(planLimitsServiceProvider);

    if (action == 'like' || action == 'dislike') {
      final hasReached = await planLimitsService.hasReachedSwipeLimit();
      if (hasReached && mounted) {
        final limits = await planLimitsService.getPlanLimits();
        UpgradeDialog.showSwipeLimitDialog(
          context,
          limits.usage.swipes.usedToday,
          limits.usage.swipes.limit,
        );
        return;
      }
    }

    if (action == 'superlike') {
      final hasReached = await planLimitsService.hasReachedSuperlikeLimit();
      if (hasReached && mounted) {
        final limits = await planLimitsService.getPlanLimits();
        UpgradeDialog.showSuperlikeLimitDialog(
          context,
          limits.usage.superlikes.usedToday,
          limits.usage.superlikes.limit,
        );
        return;
      }
    }

    ref.read(discoveryActedOnUserIdsProvider.notifier).update((s) => {...s, userId});
    ref.read(discoverCacheProvider.notifier).recordSwipe(
      userId,
      action,
      onMatch: (m) {
        if (m != null && mounted) _showMatchDialog(m);
      },
      onLimitError: (e) {
        if (!mounted) return;
        _showLimitError(e, action);
      },
      onTheyLikedYou: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("They liked you — you passed."),
              backgroundColor: AppColors.accentPurple,
            ),
          );
        }
      },
    );
    ref.read(discoverCacheProvider.notifier).fetchMoreIfNeeded(
      threshold: kDiscoverStackBufferThreshold,
      filters: _activeFilters,
    );
  }

  void _showLimitError(dynamic e, String action) {
    if (e is ApiError) {
      final errorCode = e.responseData?['error_code'] as String?;
      final data = e.responseData?['data'] as Map<String, dynamic>?;
      if (errorCode == 'DAILY_LIKE_LIMIT_REACHED') {
        final used = (data?['used_today'] as num?)?.toInt() ?? 0;
        final limit = (data?['daily_limit'] as num?)?.toInt() ?? 8;
        UpgradeDialog.showLikeLimitDialog(context, used, limit);
      } else if (errorCode == 'DAILY_LIMIT_REACHED') {
        ref.read(planLimitsServiceProvider).getPlanLimits().then((limits) {
          if (mounted) {
            UpgradeDialog.showSwipeLimitDialog(
              context,
              limits.usage.swipes.usedToday,
              limits.usage.swipes.limit,
            );
          }
        });
      } else {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to $action',
        );
      }
    } else {
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: 'Failed to $action',
      );
    }
  }

  void _showMatchDialog(match_models.Match? match) {
    if (match == null) return;

    // Bottom sheet: "It's a match!" + text field to start conversation
    final messageController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.spacingXL),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "It's a Match! 🎉",
                    style: AppTypography.h1Large.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  Text(
                    'You and ${match.firstName} liked each other! Say hi to start the conversation.',
                    style: AppTypography.body.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingLG),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ElevatedButton(
                    onPressed: () async {
                      final text = messageController.text.trim();
                      Navigator.pop(context);
                      if (!mounted) return;
                      if (text.isNotEmpty) {
                        try {
                          final chatService = ref.read(chatServiceProvider);
                          await chatService.sendMessage(match.userId, text);
                        } catch (_) {}
                      }
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userId: match.userId,
                            userName: match.firstName,
                            avatarUrl: match.primaryImageUrl,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send message'),
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Keep swiping',
                      style: AppTypography.button.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() => messageController.dispose());
  }

  void _handleCardTap(int userId) {
    // Navigate to profile detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(userId: userId),
      ),
    );
  }

  /// Build limit indicator showing remaining swipes
  Widget _buildLimitIndicator() {
    final planLimits = ref.watch(planLimitsProvider);
    
    return planLimits.when(
      data: (limits) {
        if (limits.usage.swipes.isUnlimited) {
          return const SizedBox.shrink();
        }
        
        final remaining = limits.usage.swipes.remaining;
        final used = limits.usage.swipes.usedToday;
        final limit = limits.usage.swipes.limit;
        
        // Don't show if user has plenty of swipes left
        if (remaining > limit * 0.5) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: remaining > 3
                ? AppColors.onlineGreen.withOpacity(0.1)
                : AppColors.warningYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: remaining > 3
                  ? AppColors.onlineGreen.withOpacity(0.3)
                  : AppColors.warningYellow.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                remaining > 3 ? Icons.favorite : Icons.warning_amber_rounded,
                color: remaining > 3 ? AppColors.onlineGreen : AppColors.warningYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$remaining swipes remaining today ($used/$limit used)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: remaining > 3 ? AppColors.onlineGreen : AppColors.warningYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!limits.planInfo.isPremium)
                TextButton(
                  onPressed: () {
                    context.push('/subscription-plans');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      color: remaining > 3 ? AppColors.onlineGreen : AppColors.warningYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Convert filter UI data to API format
  Future<Map<String, dynamic>> _convertFiltersToApiFormat(WidgetRef ref, Map<String, dynamic> filterData) async {
    final apiFilters = <String, dynamic>{};
    
    // Age range
    if (filterData['ageRange'] != null) {
      final ageRange = filterData['ageRange'] as RangeValues;
      apiFilters['min_age'] = ageRange.start.round();
      apiFilters['max_age'] = ageRange.end.round();
    }
    
    // Distance (if supported by API)
    if (filterData['maxDistance'] != null) {
      final maxDistance = filterData['maxDistance'] as double;
      apiFilters['max_distance'] = maxDistance.round();
    }
    
    // Gender preferences
    if (filterData['genders'] != null) {
      final genders = filterData['genders'] as List<String>;
      // Remove 'All' if present and convert to gender IDs
      if (!genders.contains('All') && genders.isNotEmpty) {
        try {
          // Fetch reference data to map gender names to IDs
          final gendersRef = await ref.read(gendersProvider.future);
          final genderIds = genders.map((genderName) {
            final genderItem = gendersRef.firstWhere(
              (item) => item.title.toLowerCase() == genderName.toLowerCase(),
              orElse: () => throw Exception('Gender not found: $genderName'),
            );
            return genderItem.id.toString();
          }).toList();

          apiFilters['genders'] = genderIds.join(',');
        } catch (e) {
          // Fallback to passing names if reference data fails
          apiFilters['genders'] = genders.join(',');
        }
      }
    }
    
    // Additional filters (if supported by API)
    if (filterData['verifiedOnly'] == true) {
      apiFilters['verified_only'] = true;
    }
    if (filterData['onlineOnly'] == true) {
      apiFilters['online_only'] = true;
    }
    if (filterData['premiumOnly'] == true) {
      apiFilters['premium_only'] = true;
    }
    
    return apiFilters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cacheState = ref.watch(discoverCacheProvider);
    final stack = cacheState.stack;
    final cards = stack.map(_profileToCardMap).toList();
    final showSkeleton = !cacheState.initialLoadComplete && stack.isEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppSpacing.contentPadding,
            right: AppSpacing.contentPadding,
          ),
          child: Row(
            children: [
              // Left side: Avatar + greeting and name (cache-first from GET /profile; fallback to auth)
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authProvider);
                  final authUser = authState.user;
                  final profileCache = ref.watch(profilePageCacheProvider);
                  final profile = profileCache.valueOrNull?.profile;
                  if (profile != null) {
                    final avatarUrl = profile.images?.isNotEmpty == true
                        ? profile.images!.first.imageUrl
                        : null;
                    final displayName = profile.lastName.isNotEmpty
                        ? '${profile.firstName} ${profile.lastName}'
                        : profile.firstName;
                    return Row(
                      children: [
                        _buildAvatarFrame(
                          backgroundColor,
                          isDark,
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildAvatarPlaceholder(isDark);
                                  },
                                )
                              : _buildAvatarPlaceholder(isDark),
                        ),
                        SizedBox(width: AppSpacing.spacingMD),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              'Hello $displayName',
                              style: AppTypography.h3.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return _buildAppBarUserRow(
                    context,
                    backgroundColor,
                    isDark,
                    avatarUrl: authUser?.avatarUrl ??
                        ((authUser?.images?.isNotEmpty == true)
                            ? authUser!.images!.first.toString()
                            : null),
                    name: authUser != null ? 'Hello ${authUser.firstName}' : 'Hello...',
                  );
                },
              ),
              const Spacer(),
              // Right side: Notifications and filter
              Row(
                children: [
                  // Notification bell with badge
                  Consumer(
                    builder: (context, ref, child) {
                      final notificationCount = ref.watch(unreadNotificationCountProvider).when(
                        data: (count) => count,
                        loading: () => null,
                        error: (_, __) => null,
                      );

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ScaleTapFeedback(
                            onTap: () => context.go('/home/notifications'),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: AppSvgIcon(
                                assetPath: AppIcons.notification,
                                size: 24,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          if (notificationCount != null && notificationCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.notificationRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  notificationCount > 99 ? '99+' : '$notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  // Filter button
                  ScaleTapFeedback(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FilterScreen(),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        final filters = await _convertFiltersToApiFormat(ref, result);
                        setState(() {
                          _activeFilters = filters;
                        });
                        ref.read(discoverCacheProvider.notifier).refresh(filters: filters);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AppSvgIcon(
                        assetPath: AppIcons.filter,
                        size: 24,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Limit indicator
            _buildLimitIndicator(),
            // Card stack with top/bottom margin so shadow doesn't sit under header or buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: showSkeleton
                  ? SkeletonDiscovery()
                  : CardStackManager(
                      cards: cards,
                      onSwipe: _handleSwipe,
                      onCardTap: _handleCardTap,
                      isLoading: false,
                      onRefresh: () => ref.read(discoverCacheProvider.notifier).refresh(filters: _activeFilters),
                    ),
              ),
            ),
            // Action buttons row: Nope, Super Like (center), Like — Chat removed
            if (!showSkeleton && cards.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.contentPadding,
                  vertical: AppSpacing.spacingLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nope (X, blue gradient)
                    _buildActionButton(
                      gradientColors: [
                        const Color(0xFF5B9BD5),
                        const Color(0xFF4A90E2),
                      ],
                      icon: AppIcons.close,
                      onPressed: () => _handleAction('dislike'),
                    ),
                    SizedBox(width: AppSpacing.spacingXL),
                    // Super Like (star) — subtle pride tint: yellow → orange from pride palette
                    _buildActionButton(
                      gradientColors: [
                        AppColors.warningYellow,
                        AppColors.lgbtGradient[1], // orange
                      ],
                      icon: AppIcons.star,
                      onPressed: () => _handleAction('superlike'),
                    ),
                    SizedBox(width: AppSpacing.spacingXL),
                    // Like (heart, red gradient)
                    _buildActionButton(
                      gradientColors: [
                        const Color(0xFFE84A5F),
                        AppColors.notificationRed,
                      ],
                      icon: AppIcons.heart,
                      onPressed: () => _handleAction('like'),
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
