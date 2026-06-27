// Screen: DiscoveryPage
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/widgets/premium/premium_design_system.dart';
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
import '../core/subscription/subscription_access.dart';
import '../features/payments/data/services/plan_limits_service.dart';
import '../widgets/premium/upgrade_dialog.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../screens/discovery/filter_screen.dart';
import '../features/payments/presentation/screens/superlike_packs_screen.dart';
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
import '../features/discover/widgets/discover_active_filters_bar.dart';
import '../features/discover/widgets/discover_swipe_limit_banner.dart';
import '../features/discover/widgets/discover_ambient_background.dart';
import '../features/discover/widgets/discover_greeting_widget.dart';
import '../core/location/location_providers.dart';
import '../core/location/widgets/location_permission_sheet.dart';
import '../core/location/data/models/user_location.dart';
import '../features/discover/widgets/discover_passport_banner.dart';
import '../core/location/passport_provider.dart';
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

/// Shared horizontal inset for discover chrome (greeting + profile card).
const double _kDiscoverHorizontalPadding = PremiumPageHeader.horizontalPadding;

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  // Filter state
  Map<String, dynamic>? _activeFilters;
  bool _isClearingPassport = false;
  bool _isSwipeInProgress = false;
  bool _isProfileSheetOpen = false;
  bool _isClosingProfileSheet = false;
  late final DraggableScrollableController _sheetController;

  Map<String, dynamic>? _discoverQueryFilters() {
    final location = ref.read(userLocationProvider).valueOrNull;
    final merged = DiscoveryFilterMapper.withPassportSearch(_activeFilters, location);
    return merged.isEmpty ? null : merged;
  }

  Future<void> _bootstrapDiscoverLocationAndRefresh() async {
    await runDiscoverLocationBootstrap(ref, context);
    if (!mounted) return;
    ref.read(profilePageCacheProvider.notifier).refresh();
    ref.read(discoverCacheProvider.notifier).refresh(filters: _discoverQueryFilters());
  }

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapDiscoverLocationAndRefresh());
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
    if (!_isProfileSheetOpen || _isClosingProfileSheet) return;
    _isClosingProfileSheet = true;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations || !_sheetController.isAttached) {
      setState(() {
        _isProfileSheetOpen = false;
        _isClosingProfileSheet = false;
      });
      return;
    }
    _sheetController
        .animateTo(
      0.50,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      if (mounted) {
        setState(() {
          _isProfileSheetOpen = false;
          _isClosingProfileSheet = false;
        });
      } else {
        _isClosingProfileSheet = false;
      }
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
      unawaited(_bootstrapDiscoverLocationAndRefresh());
      ref.read(discoverCacheProvider.notifier).fetchMoreIfNeeded(
        threshold: kDiscoverStackBufferThreshold,
        filters: _discoverQueryFilters(),
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
      onOfflineQueued: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Will send when reconnected'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          ),
        );
      },
    );
    ref.read(discoverCacheProvider.notifier).fetchMoreIfNeeded(
      threshold: kDiscoverStackBufferThreshold,
      filters: _discoverQueryFilters(),
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

  Future<void> _clearActiveFilters() async {
    setState(() => _activeFilters = null);
    ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
    await ref
        .read(discoverCacheProvider.notifier)
        .clearAndRefresh(filters: _discoverQueryFilters());
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilters: _activeFilters),
      ),
    );
    if (result != null) {
      final isPremium = ref.read(hasAdvancedFiltersProvider);
      final filters = isPremium
          ? result
          : DiscoveryFilterMapper.stripPremiumKeys(result);
      setState(() {
        _activeFilters = filters.isEmpty ? null : filters;
      });
      ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      ref.read(discoverCacheProvider.notifier).clearAndRefresh(filters: _discoverQueryFilters());
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

  bool _hasCoordinates(UserLocation? location) {
    return location?.latitude != null && location?.longitude != null;
  }

  bool _isLocationStale(UserLocation? location) {
    final updated = location?.locationUpdatedAt;
    if (updated == null) return true;
    return DateTime.now().difference(updated).inDays > 7;
  }

  _DiscoverEmptyConfig _emptyStateConfig(UserLocation? location) {
    if (!_hasCoordinates(location)) {
      return _DiscoverEmptyConfig(
        title: 'Turn on location for nearby matches',
        subtitle:
            'Enable location so we can find people near you, or expand your search radius.',
        primaryLabel: 'Enable location',
        onPrimary: _promptEnableLocation,
        secondaryLabel: 'Increase distance + retry',
        onSecondary: _expandRadiusAndRetry,
        tertiaryLabel: 'Adjust filters',
        onTertiary: _openFilters,
      );
    }

    if (_isLocationStale(location)) {
      return _DiscoverEmptyConfig(
        title: 'No one nearby right now',
        subtitle:
            'Your location may be outdated. Update it or try a wider search radius.',
        primaryLabel: 'Update location',
        onPrimary: _forceUpdateLocation,
        secondaryLabel: 'Increase distance + retry',
        onSecondary: _expandRadiusAndRetry,
        tertiaryLabel: 'Adjust filters',
        onTertiary: _openFilters,
      );
    }

    return _DiscoverEmptyConfig(
      title: "You've seen everyone nearby",
      subtitle: 'Check back soon or expand your filters to see more people',
      primaryLabel: 'Adjust filters',
      onPrimary: _openFilters,
      secondaryLabel: 'Increase distance + retry',
      onSecondary: _expandRadiusAndRetry,
    );
  }

  Future<void> _promptEnableLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.checkPermission();
    final permanentlyDenied = permission == LocationPermission.deniedForever;

    if (!mounted) return;
    await LocationPermissionSheet.show(
      context,
      permanentlyDenied: permanentlyDenied,
      onEnable: () async {
        await ref.read(locationSyncServiceProvider).syncIfNeeded(
              discoverOpen: true,
              force: true,
            );
        ref.invalidate(userLocationProvider);
        await _bootstrapDiscoverLocationAndRefresh();
      },
      onUseCity: () async {
        final profile = ref.read(profilePageCacheProvider).valueOrNull?.profile;
        final cityId = profile?.cityId;
        if (cityId != null) {
          await ref
              .read(locationApiServiceProvider)
              .updateAdministrativeLocation(cityId: cityId);
          ref.invalidate(userLocationProvider);
          await _bootstrapDiscoverLocationAndRefresh();
        }
      },
    );
  }

  Future<void> _forceUpdateLocation() async {
    await ref.read(locationSyncServiceProvider).syncIfNeeded(
          discoverOpen: true,
          force: true,
        );
    ref.invalidate(userLocationProvider);
    await _bootstrapDiscoverLocationAndRefresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location updated — refreshing discover')),
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
      data: (limits) => DiscoverSwipeLimitBanner(limits: limits),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _openPassport() async {
    final changed = await context.push<bool>(AppRoutes.passport);
    if (!mounted || changed != true) return;
    ref.invalidate(userLocationProvider);
    await ref.read(discoverCacheProvider.notifier).clearAndRefresh(
          filters: _discoverQueryFilters(),
        );
  }

  Future<void> _returnFromPassport() async {
    if (_isClearingPassport) return;
    setState(() => _isClearingPassport = true);
    try {
      await ref.read(passportControllerProvider).clear();
      if (!mounted) return;
      ref.invalidate(userLocationProvider);
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh(
            filters: _discoverQueryFilters(),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isClearingPassport = false);
    }
  }

  Widget _buildHeaderActions(BuildContext context) {
    final canUsePassport =
        ref.watch(planLimitsProvider).valueOrNull?.features.passport ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canUsePassport) ...[
          _buildHeaderIconButton(
            context: context,
            iconPath: AppIcons.map,
            semanticLabel: 'Passport — change discovery location',
            onTap: _openPassport,
            showBadge: ref.watch(passportLocationProvider).active,
          ),
          const SizedBox(width: AppSpacing.spacingXS),
        ],
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
          semanticLabel: 'Open filters',
          onTap: _openFilters,
          showBadge: _activeFilters != null && _activeFilters!.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required BuildContext context,
    required String iconPath,
    required String semanticLabel,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final theme = Theme.of(context);

    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentViolet.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.accentViolet.withValues(alpha: 0.16),
                ),
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: iconPath,
                  size: 20,
                  color: AppColors.accentViolet,
                ),
              ),
            ),
            if (showBadge)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.accentRose,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheState = ref.watch(discoverCacheProvider);
    final stack = cacheState.stack;
    final cards = stack.map(_profileToCardMap).toList();
    final showSkeleton = !cacheState.initialLoadComplete && stack.isEmpty;
    final sheetProfile = _sheetProfileFromStack(stack);

    final showActionRow =
        !showSkeleton && cards.isNotEmpty && !_isProfileSheetOpen;
    final emptyConfig = ref.watch(userLocationProvider).when(
          data: _emptyStateConfig,
          loading: () => _emptyStateConfig(null),
          error: (_, __) => _emptyStateConfig(null),
        );

    final passport = ref.watch(passportLocationProvider);

    return DiscoverAmbientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumPageHeader(
                  title: 'Discover',
                  subtitle: 'Swipe and connect with people nearby',
                  action: _buildHeaderActions(context),
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                const DiscoverGreetingWidget(),
                if (_activeFilters != null && _activeFilters!.isNotEmpty)
                  DiscoverActiveFiltersBar(
                    labels: _activeFilterLabels(),
                    onEdit: _openFilters,
                    onClear: _clearActiveFilters,
                  ),
                DiscoverPassportBanner(
                  passport: passport,
                  isClearing: _isClearingPassport,
                  onReturnHome: _returnFromPassport,
                ),
                _buildLimitIndicator(),
                Expanded(
                  child: showSkeleton
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                            _kDiscoverHorizontalPadding,
                            AppSpacing.spacingXS,
                            _kDiscoverHorizontalPadding,
                            AppSpacing.spacingXS,
                          ),
                          child: const SkeletonDiscovery(),
                        )
                      : CardStackManager(
                          cards: cards,
                          onSwipe: _onCardStackSwipe,
                          onViewProfile: _handleCardTap,
                          isSheetOpen: _isProfileSheetOpen,
                          onSheetOpenChanged: _setProfileSheetOpen,
                          horizontalPadding: _kDiscoverHorizontalPadding,
                          contentTopInset: AppSpacing.spacingSM,
                          contentBottomInset: AppSpacing.spacingSM,
                          isLoading: false,
                          onRefresh: () async {
                            await ref
                                .read(appCacheManagerProvider)
                                .revalidateAll();
                            await ref
                                .read(discoverCacheProvider.notifier)
                                .refresh(filters: _discoverQueryFilters());
                          },
                          emptyTitle: emptyConfig.title,
                          emptySubtitle: emptyConfig.subtitle,
                          emptyActionLabel: emptyConfig.primaryLabel,
                          onEmptyAction: emptyConfig.onPrimary,
                          emptySecondaryActionLabel: emptyConfig.secondaryLabel,
                          onEmptySecondaryAction: emptyConfig.onSecondary,
                          emptyTertiaryActionLabel: emptyConfig.tertiaryLabel,
                          onEmptyTertiaryAction: emptyConfig.onTertiary,
                        ),
                ),
                if (showActionRow)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _kDiscoverHorizontalPadding,
                      AppSpacing.spacingSM,
                      _kDiscoverHorizontalPadding,
                      AppSpacing.spacingXS,
                    ),
                    child: AnimatedOpacity(
                      opacity: _isSwipeInProgress ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: _buildDiscoveryActionRow(),
                    ),
                  ),
              ],
            ),
            if (_isProfileSheetOpen && sheetProfile != null)
              Positioned.fill(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _closeProfileSheet,
                      behavior: HitTestBehavior.opaque,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.42),
                      ),
                    ),
                    ProfileDetailSheet(
                      controller: _sheetController,
                      profile: sheetProfile,
                      sharedInterests: _sharedInterestSet(stack.first),
                      onClose: _closeProfileSheet,
                      actionsDisabled: _isSwipeInProgress,
                      onDislike: () => _handleSheetAction('dislike'),
                      onSuperlike: () => _handleSheetAction('superlike'),
                      onLike: () => _handleSheetAction('like'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  List<String> _activeFilterLabels() {
    final filters = _activeFilters;
    if (filters == null || filters.isEmpty) return const [];

    final labels = <String>[];
    final maxDistance = filters['max_distance'];
    if (maxDistance != null) {
      labels.add('${maxDistance}km');
    }
    final minAge = filters['min_age'];
    final maxAge = filters['max_age'];
    if (minAge != null || maxAge != null) {
      labels.add('${minAge ?? 18}–${maxAge ?? 99}');
    }
    if (filters['online_only'] == true) {
      labels.add('Online');
    }
    if (filters['verified_only'] == true) {
      labels.add('Verified');
    }
    if (labels.isEmpty) {
      labels.add('Custom filters');
    }
    return labels;
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
        const SizedBox(width: AppSpacing.spacingXXL),
        DiscoverySwipeActionButton(
          type: DiscoverySwipeActionType.superlike,
          size: 54,
          onPressed:
              _isSwipeInProgress ? null : () => _handleAction('superlike'),
        ),
        const SizedBox(width: AppSpacing.spacingXXL),
        DiscoverySwipeActionButton(
          type: DiscoverySwipeActionType.like,
          size: 58,
          onPressed: _isSwipeInProgress ? null : () => _handleAction('like'),
        ),
      ],
    );
  }
}

class _DiscoverEmptyConfig {
  const _DiscoverEmptyConfig({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;
}
