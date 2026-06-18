// Screen: DiscoveryPage
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/widgets/app_page_header.dart';
import '../widgets/cards/card_stack_manager.dart';
import '../widgets/cards/profile_detail_sheet.dart';
import '../widgets/loading/skeleton_discovery.dart';
import '../features/discover/providers/discover_cache_provider.dart';
import '../features/discover/providers/discovery_providers.dart';
import '../features/discover/data/models/discovery_profile.dart';
import '../features/profile/providers/profile_page_cache_provider.dart';
import '../features/matching/data/models/match.dart' as match_models;
import '../features/matching/widgets/lost_match_dialog.dart';
import '../features/matching/widgets/match_celebration_launcher.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../widgets/premium/upgrade_dialog.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../screens/discovery/filter_screen.dart';
import '../screens/premium/superlike_packs_screen.dart';
import '../core/utils/app_icons.dart';
import '../widgets/discovery/discovery_swipe_action_button.dart';
import '../widgets/discovery/superlike_message_sheet.dart';
import '../widgets/discovery/superlike_packs_sheet.dart';
import '../core/cache/session_cache_providers.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/discover/data/models/discovery_filter_mapper.dart';
import '../core/cache/cache_invalidator.dart';
import '../core/cache/cache_manager.dart' show appCacheManagerProvider, notifyNewMatch;
import '../core/services/app_logger.dart';
import '../features/discover/widgets/discover_greeting_widget.dart';
import '../routes/app_router.dart';

/// Discovery page - Main swiping/discovery screen
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({
    super.key,
    this.selectedTabIndex,
    this.discoveryTabIndex,
  });

  /// When used inside a tab shell (e.g. HomePage), pass current tab index so we call nearby-suggestions when user switches to this tab.
  final int? selectedTabIndex;
  final int? discoveryTabIndex;

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

/// Resting card offset below header chrome (header + greeting).
const double _kDiscoverCardTopInset = 128;

/// Space reserved for the floating action row (button size + vertical padding).
const double _kDiscoverActionBarHeight = 90;

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  // Filter state
  Map<String, dynamic>? _activeFilters;
  bool _isSwipeInProgress = false;
  bool _isProfileSheetOpen = false;
  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profilePageCacheProvider.notifier).refresh();
      ref.read(discoverCacheProvider.notifier).refresh(filters: _activeFilters);
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _setProfileSheetOpen(bool open) {
    if (_isProfileSheetOpen == open) return;
    setState(() => _isProfileSheetOpen = open);
    if (open) {
      if (_sheetController.isAttached) {
        _sheetController.jumpTo(0.58);
      }
    }
  }

  void _closeProfileSheet() {
    if (!_isProfileSheetOpen) return;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations || !_sheetController.isAttached) {
      setState(() => _isProfileSheetOpen = false);
      return;
    }
    _sheetController.animateTo(
      0.50,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    ).whenComplete(() {
      if (mounted) setState(() => _isProfileSheetOpen = false);
    });
  }

  void _logDiscoverySuperlike(String step, Map<String, Object?> fields) {
    final details = fields.entries
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    AppLogger.debug('$step $details', tag: 'DiscoverySuperlike');
  }

  Future<void> _handleSheetAction(String action) async {
    final stack = ref.read(discoverCacheProvider).stack;
    if (stack.isEmpty) return;
    final userId = stack.first.id;
    _logDiscoverySuperlike('sheet_action', {
      'action': action,
      'userId': userId,
      'profileSheetOpen': _isProfileSheetOpen,
      'swipeInProgress': _isSwipeInProgress,
      'stackSize': stack.length,
    });
    if (action == 'superlike') {
      _closeProfileSheet();
      await _showSuperlikeBottomSheet(
        userId,
        source: 'profile_sheet',
      );
      return;
    }
    _closeProfileSheet();
    switch (action) {
      case 'like':
      case 'dislike':
        await _handleSwipe(
          userId,
          action,
          fromRow: true,
          superlikeSource: 'profile_sheet',
        );
        break;
      default:
        break;
    }
  }

  DiscoverySheetProfile? _sheetProfileFromStack(List<DiscoveryProfile> stack) {
    if (stack.isEmpty) return null;
    final profile = stack.first;
    return DiscoverySheetProfile(
      firstName: profile.firstName,
      age: profile.age,
      city: profile.city,
      country: profile.country,
      bio: profile.profileBio,
      isVerified: profile.isVerified ?? false,
      isOnline: profile.isOnline ?? false,
      matchPercentage: profile.matchPercentage ?? profile.compatibilityScore,
      matchReasons: profile.matchReasons,
      jobTitle: profile.jobTitle,
      educationTitle: profile.educationTitle,
      height: profile.height,
      distance: profile.distance,
      interests: profile.interestNames ?? const [],
      imageUrls: profile.imageUrls ?? const [],
    );
  }

  Set<String> _sharedInterestSet(DiscoveryProfile profile) {
    final fromApi = profile.sharedInterestNames ?? const [];
    if (fromApi.isNotEmpty) {
      return fromApi.map((e) => e.toLowerCase()).toSet();
    }
    final myProfile = ref.read(profilePageCacheProvider).valueOrNull?.profile;
    final myInterestIds = (myProfile?.interests ?? const <int>[]).toSet();
    final candidateInterests = profile.interestNames ?? const [];
    if (myInterestIds.isEmpty || candidateInterests.isEmpty) {
      return const {};
    }
    // When only titles are available, highlight overlapping names case-insensitively.
    return candidateInterests.map((e) => e.toLowerCase()).toSet();
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
        unawaited(_showSuperlikeBottomSheet(userId, source: 'action_row'));
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

  Future<void> _showSuperlikeBottomSheet(
    int userId, {
    required String source,
  }) async {
    _logDiscoverySuperlike('flow_start', {
      'userId': userId,
      'source': source,
      'profileSheetOpen': _isProfileSheetOpen,
      'swipeInProgress': _isSwipeInProgress,
    });
    if (_isSwipeInProgress) {
      _logDiscoverySuperlike('flow_blocked', {
        'userId': userId,
        'source': source,
        'reason': 'swipe_in_progress',
      });
      return;
    }

    final sessionCache = ref.read(sessionDataCacheServiceProvider);
    final remaining = sessionCache.getSuperlikesRemainingSync();
    _logDiscoverySuperlike('remaining_check', {
      'userId': userId,
      'source': source,
      'remaining': remaining ?? 'null',
    });

    if (remaining == null) {
      _logDiscoverySuperlike('open_packs_sheet', {
        'userId': userId,
        'source': source,
        'reason': 'remaining_null',
      });
      await showSuperlikePacksSheet(
        context,
        headerMessage: "You're out of superlikes — get more below",
        fetchCountInBackground: true,
      );
      ref.read(superlikesRemainingProvider.notifier).refreshFromCache();
      return;
    }

    if (remaining <= 0) {
      _logDiscoverySuperlike('open_packs_sheet', {
        'userId': userId,
        'source': source,
        'reason': 'remaining_zero',
      });
      await showSuperlikePacksSheet(
        context,
        headerMessage: "You're out of superlikes — get more below",
      );
      return;
    }

    final superlikeInfo = sessionCache.superlikeInfoFromCache();
    if (superlikeInfo == null) {
      _logDiscoverySuperlike('open_packs_sheet', {
        'userId': userId,
        'source': source,
        'reason': 'superlike_info_null',
      });
      await showSuperlikePacksSheet(
        context,
        headerMessage: "You're out of superlikes — get more below",
        fetchCountInBackground: true,
      );
      return;
    }

    if (!mounted) return;

    try {
      _logDiscoverySuperlike('open_message_sheet', {
        'userId': userId,
        'source': source,
        'remaining': remaining,
      });
      final result = await showSuperlikeMessageSheet(
        context,
        superlikeInfo: superlikeInfo,
      );
      if (!mounted || result == null) {
        _logDiscoverySuperlike('message_sheet_dismissed', {
          'userId': userId,
          'source': source,
          'result': 'null',
        });
        return;
      }

      if (result.openPurchase) {
        _logDiscoverySuperlike('open_packs_from_message_sheet', {
          'userId': userId,
          'source': source,
        });
        await showSuperlikePacksSheet(
          context,
          headerMessage: "You're out of superlikes — get more below",
        );
        return;
      }

      final message = result.message;
      if (message == null || message.isEmpty) {
        _logDiscoverySuperlike('message_sheet_empty', {
          'userId': userId,
          'source': source,
        });
        return;
      }

      if (_isProfileSheetOpen) {
        _logDiscoverySuperlike('close_profile_sheet_before_send', {
          'userId': userId,
          'source': source,
        });
        _closeProfileSheet();
      }

      _logDiscoverySuperlike('send_start', {
        'userId': userId,
        'source': source,
        'messageLength': message.length,
        'remainingBeforeSend': remaining,
      });
      final queued = await _handleSwipe(
        userId,
        'superlike',
        fromRow: source != 'card_swipe',
        superlikeMessage: message,
        superlikeSource: source,
        onSuperlikeSent: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Super Like sent!'),
              backgroundColor: AppColors.onlineGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
      _logDiscoverySuperlike('send_complete', {
        'userId': userId,
        'source': source,
        'queued': queued,
        'profileSheetOpen': _isProfileSheetOpen,
      });
    } catch (e, stack) {
      AppLogger.error(
        'Super like sheet failed (source=$source userId=$userId)',
        tag: 'DiscoverySuperlike',
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
      unawaited(_showSuperlikeBottomSheet(userId, source: 'card_swipe'));
      return;
    }
    unawaited(_handleSwipe(userId, action, fromRow: false));
  }

  void _applySwipeToCache(
    int userId,
    String action, {
    String? superlikeMessage,
    VoidCallback? onSuperlikeSent,
  }) {
    ref.read(discoveryActedOnUserIdsProvider.notifier).update((s) => {...s, userId});
    ref.read(discoverCacheProvider.notifier).recordSwipe(
      userId,
      action,
      superlikeMessage: superlikeMessage,
      onSuperlikeSent: onSuperlikeSent,
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
      onLostMatch: () {
        if (mounted) {
          unawaited(LostMatchDialog.show(context));
        }
      },
    );
    ref.read(discoverCacheProvider.notifier).fetchMoreIfNeeded(
      threshold: kDiscoverStackBufferThreshold,
      filters: _activeFilters,
    );
  }

  List<String> _profileImageUrls(DiscoveryProfile profile) {
    final seen = <String>{};
    final urls = <String>[];
    void add(String? url) {
      final trimmed = url?.trim();
      if (trimmed == null || trimmed.isEmpty || !seen.add(trimmed)) return;
      urls.add(trimmed);
    }
    for (final url in profile.imageUrls ?? const <String>[]) {
      add(url);
    }
    add(profile.primaryImageUrl);
    return urls;
  }

  Map<String, dynamic> _profileToCardMap(DiscoveryProfile profile) {
    final imageUrls = _profileImageUrls(profile);
    return {
      'id': profile.id,
      'name': profile.firstName,
      'age': profile.age,
      'city': profile.city,
      'country': profile.country,
      'gender': profile.gender,
      'location': profile.city != null && profile.country != null
          ? '${profile.city}, ${profile.country}'
          : profile.city ?? profile.country ?? '',
      'avatar_url': imageUrls.isNotEmpty ? imageUrls.first : null,
      'image_urls': imageUrls,
      'bio': profile.profileBio ?? '',
      'is_verified': profile.isVerified ?? false,
      'is_premium': profile.isPremium ?? false,
      'is_online': profile.isOnline ?? false,
      'distance': profile.distance,
      'compatibility_score': profile.compatibilityScore,
      'match_percentage': profile.matchPercentage ?? profile.compatibilityScore,
      'match_reasons': profile.matchReasons,
      'interests': profile.interestNames,
      'shared_interests': profile.sharedInterestNames,
      'job': profile.jobTitle,
      'education': profile.educationTitle,
      'is_superliked': profile.isSuperliked ?? false,
    };
  }

  Future<bool> _handleSwipe(
    int userId,
    String action, {
    bool fromRow = false,
    String? superlikeMessage,
    VoidCallback? onSuperlikeSent,
    String? superlikeSource,
  }) async {
    if (_isSwipeInProgress) {
      if (action == 'superlike') {
        _logDiscoverySuperlike('swipe_blocked', {
          'userId': userId,
          'source': superlikeSource ?? 'unknown',
          'reason': 'swipe_in_progress',
        });
      }
      return false;
    }
    _isSwipeInProgress = true;

    if (action == 'superlike') {
      _logDiscoverySuperlike('swipe_apply_cache', {
        'userId': userId,
        'source': superlikeSource ?? 'unknown',
        'fromRow': fromRow,
        'hasMessage': (superlikeMessage?.isNotEmpty ?? false),
        'messageLength': superlikeMessage?.length ?? 0,
      });
    }

    try {
      final planLimitsService = ref.read(planLimitsServiceProvider);

      if (action == 'like' || action == 'dislike') {
        final hasReached = await _hasReachedSwipeLimit(planLimitsService);
        if (!mounted) return false;
        if (hasReached) {
          final limits = await planLimitsService.getPlanLimits();
          if (!mounted) return false;
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
          ref.read(planLimitsProvider.notifier).clearCache();
          return false;
        }
      }

      if (action == 'superlike') {
        // Let the bottom sheet finish closing before mutating the card stack.
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return false;
      }
      _applySwipeToCache(
        userId,
        action,
        superlikeMessage: superlikeMessage,
        onSuperlikeSent: onSuperlikeSent,
      );
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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: _activeFilters),
      ),
    );
    if (result != null) {
      final isPremium =
          ref.read(planLimitsProvider).valueOrNull?.features.advancedFilters ??
              false;
      final filters = isPremium
          ? result
          : DiscoveryFilterMapper.stripPremiumKeys(result);
      setState(() {
        _activeFilters = filters.isEmpty ? null : filters;
      });
      ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      ref.read(discoverCacheProvider.notifier).refresh(filters: _activeFilters);
    }
  }

  void _expandRadiusAndRetry() {
    final nextFilters = <String, dynamic>{...?_activeFilters};
    final current = (nextFilters['max_distance'] as num?)?.toInt() ?? 50;
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
        ref.read(planLimitsProvider.notifier).clearCache();
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
                ? AppColors.onlineGreen.withValues(alpha: 0.1)
                : AppColors.warningYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: remaining > 3
                  ? AppColors.onlineGreen.withValues(alpha: 0.3)
                  : AppColors.warningYellow.withValues(alpha: 0.3),
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

  Widget _buildHeaderActions(BuildContext context, bool isDark) {
    final iconColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final iconBackgroundColor = Theme.of(context).colorScheme.onSurface.withValues(
      alpha: 0.08,
    );

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

            final hasUnreadNotifications =
                notificationCount != null && notificationCount > 0;
            return _buildHeaderIconButton(
              context: context,
              iconPath: AppIcons.notification,
              iconColor: iconColor,
              backgroundColor: iconBackgroundColor,
              semanticLabel: 'Notifications',
              onTap: () => context.go('${AppRoutes.home}/notifications'),
              showBadge: hasUnreadNotifications,
            );
          },
        ),
        const SizedBox(width: AppSpacing.spacingXS),
        _buildHeaderIconButton(
          context: context,
          iconPath: AppIcons.filter,
          iconColor: iconColor,
          backgroundColor: iconBackgroundColor,
          semanticLabel: 'Open filters',
          onTap: _openFilters,
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required BuildContext context,
    required String iconPath,
    required Color iconColor,
    required Color backgroundColor,
    required String semanticLabel,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: Center(
                      child: AppSvgIcon(
                        assetPath: iconPath,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final sheetProfile = _sheetProfileFromStack(stack);

    final showActionRow =
        !showSkeleton && cards.isNotEmpty && !_isProfileSheetOpen;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: 'Discover',
                  action: _buildHeaderActions(context, isDark),
                ),
                const DiscoverGreetingWidget(),
                _buildLimitIndicator(),
                const Spacer(),
                if (showActionRow)
                  SizedBox(height: _kDiscoverActionBarHeight),
              ],
            ),
            if (showActionRow)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPageHeader.horizontalPadding,
                    vertical: AppSpacing.spacingLG,
                  ),
                  child: AnimatedOpacity(
                    opacity: _isSwipeInProgress ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: _buildDiscoveryActionRow(),
                  ),
                ),
              ),
            if (showSkeleton)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: _kDiscoverCardTopInset + AppSpacing.spacingSM,
                    bottom: _kDiscoverActionBarHeight,
                    left: AppSpacing.spacingLG,
                    right: AppSpacing.spacingLG,
                  ),
                  child: const SkeletonDiscovery(),
                ),
              )
            else
              Positioned.fill(
                child: CardStackManager(
                  cards: cards,
                  onSwipe: _onCardStackSwipe,
                  onViewProfile: _handleCardTap,
                  isSheetOpen: _isProfileSheetOpen,
                  onSheetOpenChanged: _setProfileSheetOpen,
                  contentTopInset: _kDiscoverCardTopInset + AppSpacing.spacingSM,
                  contentBottomInset: showActionRow
                      ? _kDiscoverActionBarHeight
                      : AppSpacing.spacingLG,
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
            if (_isProfileSheetOpen && sheetProfile != null)
              Positioned.fill(
                child: ProfileDetailSheet(
                  controller: _sheetController,
                  profile: sheetProfile,
                  sharedInterests: _sharedInterestSet(stack.first),
                  onClose: _closeProfileSheet,
                  actionsDisabled: _isSwipeInProgress,
                  onDislike: () => _handleSheetAction('dislike'),
                  onSuperlike: () => _handleSheetAction('superlike'),
                  onLike: () => _handleSheetAction('like'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DiscoverySwipeActionButton(
          type: DiscoverySwipeActionType.dislike,
          size: 58,
          onPressed:
              _isSwipeInProgress ? null : () => _handleAction('dislike'),
        ),
        const SizedBox(width: AppSpacing.spacingXL),
        DiscoverySwipeActionButton(
          type: DiscoverySwipeActionType.superlike,
          size: 54,
          onPressed:
              _isSwipeInProgress ? null : () => _handleAction('superlike'),
        ),
        const SizedBox(width: AppSpacing.spacingXL),
        DiscoverySwipeActionButton(
          type: DiscoverySwipeActionType.like,
          size: 58,
          onPressed: _isSwipeInProgress ? null : () => _handleAction('like'),
        ),
      ],
    );
  }
}
