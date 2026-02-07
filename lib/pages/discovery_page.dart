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
import '../features/discover/providers/discovery_providers.dart';
import '../features/discover/data/models/discovery_profile.dart';
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
import '../widgets/match/match_screen.dart';
import '../pages/chat_page.dart';
import '../core/utils/app_icons.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../features/auth/providers/auth_provider.dart';

/// Discovery page - Main swiping/discovery screen
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _cards = [];
  int _currentPage = 1;
  final int _pageSize = 10;

  // Filter state
  Map<String, dynamic>? _activeFilters;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildActionButton({
    required Color color,
    required String icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: AppSvgIcon(
          assetPath: icon,
          size: 24,
          color: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _handleAction(String action) {
    if (_cards.isEmpty) return;

    // Get the current top card
    final currentCard = _cards.first;
    final userId = currentCard['id'] as int;

    switch (action) {
      case 'like':
      case 'dislike':
      case 'superlike':
        _handleSwipe(userId, action);
        break;
      case 'message':
        // Navigate to chat if there's a match or open profile
        _handleCardTap(userId);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _cards.clear();
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final discoveryService = ref.read(discoveryServiceProvider);
      List<DiscoveryProfile> profiles;
      
      // Always use nearby suggestions with optional filters
      profiles = await discoveryService.getNearbySuggestions(
        page: _currentPage,
        limit: _pageSize,
        filters: _activeFilters,
      );

      if (mounted) {
        setState(() {
          // Convert DiscoveryProfile to Map format for CardStackManager
          final newCards = profiles.map((profile) => _profileToCardMap(profile)).toList();
          if (refresh) {
            _cards = newCards;
          } else {
            _cards.addAll(newCards);
          }
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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

  Future<void> _handleSwipe(int userId, String action) async {
    try {
      // Check limits before action
      final planLimitsService = ref.read(planLimitsServiceProvider);
      
      // Check swipe limit
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
      
      // Check superlike limit
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
      
      final likesService = ref.read(likesServiceProvider);
      
      switch (action) {
        case 'like':
          final response = await likesService.likeUser(userId);
          // Increment usage locally (optimistic update)
          planLimitsService.incrementUsage('swipes');
          planLimitsService.incrementUsage('likes');
          if (response.isMatch && mounted) {
            _showMatchDialog(response.match as match_models.Match?);
          }
          break;
        case 'dislike':
          await likesService.dislikeUser(userId);
          // Increment usage
          planLimitsService.incrementUsage('swipes');
          break;
        case 'superlike':
          final response = await likesService.superlikeUser(userId);
          // Increment usage
          planLimitsService.incrementUsage('swipes');
          planLimitsService.incrementUsage('superlikes');
          if (response.isMatch && mounted) {
            _showMatchDialog(response.match as match_models.Match?);
          }
          break;
      }
    } on ApiError catch (e) {
      if (mounted) {
        // Check if error is DAILY_LIMIT_REACHED
        final errorCode = e.responseData?['error_code'] as String?;
        if (errorCode == 'DAILY_LIMIT_REACHED') {
          final limits = await ref.read(planLimitsServiceProvider).getPlanLimits();
          UpgradeDialog.showSwipeLimitDialog(
            context,
            limits.usage.swipes.usedToday,
            limits.usage.swipes.limit,
          );
        } else {
          ErrorHandlerService.showErrorSnackBar(
            context,
            e,
            customMessage: 'Failed to $action',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to $action',
        );
      }
    }
  }

  void _showMatchDialog(match_models.Match? match) {
    if (match == null) return;
    
    // Show match screen as a full-screen dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => MatchScreen(
        match: match,
        onSendMessage: () {
          Navigator.pop(context);
          // Navigate to chat with match.userId
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
        onKeepSwiping: () {
          Navigator.pop(context);
        },
      ),
    );
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
              // Left side: Avatar with gradient ring + greeting and name
              Consumer(
                builder: (context, ref, child) {
                  // Get actual user data from auth provider
                  final authState = ref.watch(authProvider);
                  final user = authState.user;

                  return Row(
                    children: [
                      // Circular avatar with gradient ring
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentGradientStart,
                              AppColors.accentGradientEnd,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: backgroundColor,
                          ),
                          child: ClipOval(
                            child: user?.images != null && user!.images!.isNotEmpty
                                ? Image.network(
                                    user.images!.first.toString(),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                        child: Icon(
                                          Icons.person,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                                    child: Icon(
                                      Icons.person,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      // Greeting and name
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
                            user != null ? 'Hello ${user.firstName}' : 'Hello User',
                            style: AppTypography.h3.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          IconButton(
                            icon: AppSvgIcon(
                              assetPath: AppIcons.notification,
                              size: 24,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            onPressed: () {
                              context.go('/home/notifications');
                            },
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
                  IconButton(
                    icon: AppSvgIcon(
                      assetPath: AppIcons.filter,
                      size: 24,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FilterScreen(),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        // Convert filter result to API format
                        final filters = await _convertFiltersToApiFormat(ref, result);
                        setState(() {
                          _activeFilters = filters;
                        });
                        // Reload cards with new filters
                        _loadCards(refresh: true);
                      }
                    },
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
            // Card stack
            Expanded(
              child: _isLoading
                  ? SkeletonDiscovery()
                  : _hasError
                      ? ErrorDisplayWidget(
                          errorMessage: _errorMessage ?? 'Failed to load profiles',
                          onRetry: () => _loadCards(refresh: true),
                        )
                      : CardStackManager(
                          cards: _cards,
                          onSwipe: _handleSwipe,
                          onCardTap: _handleCardTap,
                          isLoading: _isLoading,
                          onRefresh: () => _loadCards(refresh: true),
                        ),
            ),
            // Action buttons row
            if (!_isLoading && !_hasError && _cards.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.contentPadding,
                  vertical: AppSpacing.spacingLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dislike button (X, blue)
                    _buildActionButton(
                      color: const Color(0xFF4A90E2), // Light blue
                      icon: AppIcons.close, // X icon
                      onPressed: () => _handleAction('dislike'),
                    ),
                    SizedBox(width: AppSpacing.spacingXL),
                    // Message button (chat, purple)
                    _buildActionButton(
                      color: AppColors.accentPurple,
                      icon: AppIcons.message, // Chat icon
                      onPressed: () => _handleAction('message'),
                    ),
                    SizedBox(width: AppSpacing.spacingXL),
                    // Like button (heart, red)
                    _buildActionButton(
                      color: AppColors.notificationRed,
                      icon: AppIcons.heart,
                      onPressed: () => _handleAction('like'),
                    ),
                    SizedBox(width: AppSpacing.spacingXL),
                    // Super Like button (star, yellow)
                    _buildActionButton(
                      color: AppColors.warningYellow,
                      icon: AppIcons.star,
                      onPressed: () => _handleAction('superlike'),
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
