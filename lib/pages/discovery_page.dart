// Screen: DiscoveryPage
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/widgets/app_page_header.dart';
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
import '../features/matching/widgets/match_celebration_launcher.dart';
import '../features/payments/providers/payment_providers.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../widgets/premium/upgrade_dialog.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../screens/discovery/filter_screen.dart';
import '../screens/premium/superlike_packs_screen.dart';
import '../features/chat/providers/chat_providers.dart';
import '../core/utils/app_icons.dart';
import '../widgets/buttons/scale_tap_feedback.dart';
import '../widgets/discovery/superlike_message_sheet.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../core/cache/cache_invalidator.dart';
import '../core/cache/cache_manager.dart' show appCacheManagerProvider, notifyNewMatch;
import '../core/services/app_logger.dart';
import '../core/widgets/cached_content_banner.dart';
import '../routes/app_router.dart';

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
  bool _isSwipeInProgress = false;

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

  Widget _buildDiscoveryActionButton({
    required String icon,
    required VoidCallback onPressed,
    required double size,
    Color? fillColor,
    required bool filled,
    required bool outlined,
  }) {
    final theme = Theme.of(context);
    final fill = fillColor ?? theme.colorScheme.primary;

    return ScaleTapFeedback(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? fill : Colors.transparent,
          border: outlined
              ? Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: AppSvgIcon(
            assetPath: icon,
            size: filled && size <= 44 ? 22 : 24,
            color: filled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  void _handleAction(String action) {
    if (_isSwipeInProgress) return;

    final stack = ref.read(discoverCacheProvider).stack;
    if (stack.isEmpty) return;

    final userId = stack.first.id;

    switch (action) {
      case 'like':
      case 'dislike':
        unawaited(_handleSwipe(userId, action, fromRow: true));
        break;
      case 'superlike':
        unawaited(_showSuperlikeBottomSheet(userId));
        break;
      case 'message':
        _handleCardTap(userId);
        break;
    }
  }

  Future<bool> _hasReachedSwipeLimit(PlanLimitsService service) async {
    final cached = service.getCachedLimits();
    if (cached != null) return cached.hasReachedLimit('swipes');
    return service.hasReachedSwipeLimit();
  }

  Future<bool> _hasReachedSuperlikeLimit(PlanLimitsService service) async {
    final cached = service.getCachedLimits();
    if (cached != null) return cached.hasReachedLimit('superlikes');
    return service.hasReachedSuperlikeLimit();
  }

  Future<void> _showSuperlikeBottomSheet(int userId) async {
    if (_isSwipeInProgress) return;

    try {
      final planLimitsService = ref.read(planLimitsServiceProvider);
      final limits =
          await planLimitsService.getPlanLimits(forceRefresh: true);
      if (!mounted) return;

      final result = await showSuperlikeMessageSheet(
        context,
        superlikeInfo: limits.effectiveSuperlikeInfo,
      );
      if (!mounted || result == null) return;

      if (result.openPurchase) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SuperlikePacksScreen(),
          ),
        );
        planLimitsService.clearCache();
        ref.invalidate(planLimitsProvider);
        return;
      }

      final message = result.message;
      if (message == null || message.isEmpty) return;

      final queued = await _handleSwipe(
        userId,
        'superlike',
        fromRow: true,
        superlikeMessage: message,
      );

      if (queued && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Super Like sent!'),
              backgroundColor: AppColors.onlineGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        'Super like sheet failed',
        tag: 'DiscoveryPage',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Could not open Super Like. Please try again.',
        );
      }
    }
  }

  void _onCardStackSwipe(int userId, String action) {
    if (_isSwipeInProgress) return;

    if (action == 'superlike') {
      unawaited(_showSuperlikeBottomSheet(userId));
      return;
    }
    unawaited(_handleSwipe(userId, action, fromRow: false));
  }

  void _applySwipeToCache(
    int userId,
    String action, {
    String? superlikeMessage,
  }) {
    ref.read(discoveryActedOnUserIdsProvider.notifier).update((s) => {...s, userId});
    ref.read(discoverCacheProvider.notifier).recordSwipe(
      userId,
      action,
      superlikeMessage: superlikeMessage,
      onMatch: (m) {
        if (m != null) {
          unawaited(notifyNewMatch(ref));
          if (mounted) _showMatchDialog(m);
        }
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

  Future<bool> _handleSwipe(
    int userId,
    String action, {
    bool fromRow = false,
    String? superlikeMessage,
  }) async {
    if (_isSwipeInProgress) return false;
    _isSwipeInProgress = true;

    try {
      final planLimitsService = ref.read(planLimitsServiceProvider);

      if (action == 'like' || action == 'dislike') {
        final hasReached = await _hasReachedSwipeLimit(planLimitsService);
        if (hasReached && mounted) {
          final limits = await planLimitsService.getPlanLimits();
          UpgradeDialog.showSwipeLimitDialog(
            context,
            limits.usage.swipes.usedToday,
            limits.usage.swipes.limit,
          );
          return false;
        }
      }

      if (action == 'superlike') {
        final hasReached = await _hasReachedSuperlikeLimit(planLimitsService);
        if (hasReached && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SuperlikePacksScreen(),
            ),
          );
          planLimitsService.clearCache();
          ref.invalidate(planLimitsProvider);
          return false;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applySwipeToCache(
          userId,
          action,
          superlikeMessage: superlikeMessage,
        );
      });
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Swipe action failed ($action)',
        tag: 'DiscoveryPage',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Action failed. Please try again.',
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSwipeInProgress = false);
      } else {
        _isSwipeInProgress = false;
      }
    }
  }

  Future<void> _openFilters() async {
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
      ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      ref.read(discoverCacheProvider.notifier).refresh(filters: filters);
    }
  }

  void _expandRadiusAndRetry() {
    final nextFilters = <String, dynamic>{...?_activeFilters};
    final current = (nextFilters['max_distance'] as num?)?.toInt() ?? 25;
    final expanded = (current + 25).clamp(25, 200);
    nextFilters['max_distance'] = expanded;
    setState(() {
      _activeFilters = nextFilters;
    });
    ref.read(discoverCacheProvider.notifier).refresh(filters: nextFilters);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Expanded distance to $expanded km and retrying...')),
    );
  }

  void _showLimitError(dynamic e, String action) {
    if (e is ApiError) {
      final errorCode = e.responseData?['error_code'] as String?;
      final data = e.responseData?['data'] as Map<String, dynamic>?;
      final purchaseRequired = data?['purchase_required'] == true ||
          e.responseData?['purchase_required'] == true;

      if (action == 'superlike' &&
          (purchaseRequired || e.code == 403)) {
        ref.read(planLimitsServiceProvider).clearCache();
        ref.invalidate(planLimitsProvider);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SuperlikePacksScreen(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message.isNotEmpty
                  ? e.message
                  : 'No Super Likes remaining. Purchase more to continue.',
            ),
            backgroundColor: AppColors.feedbackWarning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

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
    if (match == null || !mounted) return;
    MatchCelebrationLauncher.show(context, ref, match: match);
  }

  void _handleCardTap(int userId) {
    final target = Uri(
      path: AppRoutes.profileDetail,
      queryParameters: {'userId': userId.toString()},
    ).toString();
    context.push(target);
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
                    context.push(AppRoutes.subscriptionPlans);
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

  Widget _buildHeaderActions(BuildContext context, bool isDark) {
    final iconColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, child) {
            final notificationCount =
                ref.watch(unreadNotificationCountProvider).when(
                      data: (count) => count,
                      loading: () => null,
                      error: (_, __) => null,
                    );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: AppIcons.notification,
                    size: 24,
                    color: iconColor,
                  ),
                  onPressed: () =>
                      context.go('${AppRoutes.home}/notifications'),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
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
        IconButton(
          icon: AppSvgIcon(
            assetPath: AppIcons.filter,
            size: 24,
            color: iconColor,
          ),
          onPressed: _openFilters,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cacheState = ref.watch(discoverCacheProvider);
    final stack = cacheState.stack;
    final cards = stack.map(_profileToCardMap).toList();
    final showSkeleton = !cacheState.initialLoadComplete && stack.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Discover',
              action: _buildHeaderActions(context, isDark),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            const CachedContentBanner(),
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
                      onSwipe: _onCardStackSwipe,
                      onCardTap: _handleCardTap,
                      isLoading: false,
                      onRefresh: () async {
                        await ref.read(appCacheManagerProvider).revalidateAll();
                        await ref
                            .read(discoverCacheProvider.notifier)
                            .refresh(filters: _activeFilters);
                      },
                      emptyActionLabel: 'Adjust filters',
                      onEmptyAction: _openFilters,
                      emptySecondaryActionLabel: 'Increase distance + retry',
                      onEmptySecondaryAction: _expandRadiusAndRetry,
                    ),
              ),
            ),
            // Action buttons row: Nope, Super Like (center), Like — Chat removed
            if (!showSkeleton && cards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPageHeader.horizontalPadding,
                  vertical: AppSpacing.spacingLG,
                ),
                child: AnimatedOpacity(
                  opacity: _isSwipeInProgress ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDiscoveryActionButton(
                        icon: AppIcons.close,
                        onPressed: _isSwipeInProgress
                            ? () {}
                            : () => _handleAction('dislike'),
                        size: 52,
                        filled: false,
                        outlined: true,
                      ),
                      const SizedBox(width: AppSpacing.spacingXL),
                      _buildDiscoveryActionButton(
                        icon: AppIcons.star,
                        onPressed: _isSwipeInProgress
                            ? () {}
                            : () => _handleAction('superlike'),
                        size: 44,
                        fillColor: AppColors.warningYellow,
                        filled: true,
                        outlined: false,
                      ),
                      const SizedBox(width: AppSpacing.spacingXL),
                      _buildDiscoveryActionButton(
                        icon: AppIcons.heart,
                        onPressed: _isSwipeInProgress
                            ? () {}
                            : () => _handleAction('like'),
                        size: 52,
                        filled: true,
                        outlined: false,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
