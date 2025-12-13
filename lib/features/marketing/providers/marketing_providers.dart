import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_providers.dart';
import '../data/services/marketing_service.dart';
import '../data/services/daily_rewards_service.dart';
import '../data/services/banner_service.dart';
import '../data/services/gamification_service.dart';
import '../data/models/campaign_model.dart';
import '../data/models/banner_model.dart';
import '../data/models/daily_reward_model.dart';
import '../data/models/badge_model.dart';

/// Marketing service provider
/// Part of the Marketing System Implementation (Task 3.3.1)
final marketingServiceProvider = Provider<MarketingService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MarketingService(apiService);
});

/// Daily rewards service provider
final dailyRewardsServiceProvider = Provider<DailyRewardsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DailyRewardsService(apiService);
});

/// Banner service provider
final bannerServiceProvider = Provider<BannerService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BannerService(apiService);
});

/// Gamification service provider
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GamificationService(apiService);
});

// ==================== Marketing Providers ====================

/// Active promotions provider
final activePromotionsProvider = FutureProvider<List<PromotionModel>>((ref) async {
  final service = ref.watch(marketingServiceProvider);
  return service.getActivePromotions();
});

/// Personalized pricing provider
final personalizedPricingProvider = FutureProvider<List<PersonalizedPrice>>((ref) async {
  final service = ref.watch(marketingServiceProvider);
  return service.getPersonalizedPricing();
});

/// Public promo codes provider
final publicPromoCodesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(marketingServiceProvider);
  return service.getPublicPromoCodes();
});

// ==================== Daily Rewards Providers ====================

/// Daily reward status provider
final dailyRewardStatusProvider = FutureProvider<DailyRewardStatus>((ref) async {
  final service = ref.watch(dailyRewardsServiceProvider);
  return service.getStatus();
});

/// Daily rewards configuration provider
final dailyRewardsConfigProvider = FutureProvider<List<DailyRewardConfig>>((ref) async {
  final service = ref.watch(dailyRewardsServiceProvider);
  return service.getConfiguration();
});

/// Daily rewards leaderboard provider
final dailyRewardsLeaderboardProvider = FutureProvider<List<StreakLeaderboardEntry>>((ref) async {
  final service = ref.watch(dailyRewardsServiceProvider);
  return service.getLeaderboard();
});

// ==================== Banner Providers ====================

/// Banners by position provider
final bannersByPositionProvider = FutureProvider.family<List<BannerModel>, String>((ref, position) async {
  final service = ref.watch(bannerServiceProvider);
  return service.getBannersByPosition(position);
});

/// All banners provider
final allBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final service = ref.watch(bannerServiceProvider);
  return service.getAllBanners();
});

// ==================== Gamification Providers ====================

/// All badges provider
final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getAllBadges();
});

/// My badges provider
final myBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getMyBadges();
});

/// Displayed badges provider
final displayedBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getDisplayedBadges();
});

/// Badge eligibility provider
final badgeEligibilityProvider = FutureProvider<BadgeEligibility>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.checkEligibility();
});

/// Badge leaderboard provider
final badgeLeaderboardProvider = FutureProvider<List<BadgeLeaderboardEntry>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getLeaderboard();
});

/// User badges provider (for viewing other profiles)
final userBadgesProvider = FutureProvider.family<List<BadgeModel>, int>((ref, userId) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserBadges(userId);
});
