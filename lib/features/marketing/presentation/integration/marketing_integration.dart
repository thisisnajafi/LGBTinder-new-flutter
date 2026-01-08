/// Marketing integration exports
/// Provides easy-to-use widgets for integrating marketing features into existing screens
/// Part of the Marketing System Implementation (Phase 3.6)
library marketing_integration;

export 'banner_integration.dart';
export 'daily_rewards_integration.dart';
export 'badges_integration.dart';
export 'purchase_promo_integration.dart';

/*
 * MARKETING INTEGRATION GUIDE
 * ===========================
 * 
 * This library provides reusable widgets for integrating marketing features
 * into any screen without modifying existing code significantly.
 * 
 * 
 * 1. BANNER INTEGRATION (Home/Discover screens)
 * ---------------------------------------------
 * 
 * Hero Banner at top of screen:
 * ```dart
 * Column(
 *   children: [
 *     BannerIntegration.hero(position: 'home'),
 *     Expanded(child: YourContent()),
 *   ],
 * )
 * ```
 * 
 * Interstitial between content:
 * ```dart
 * ListView(
 *   children: [
 *     ...items.take(5),
 *     BannerIntegration.interstitial(position: 'discover'),
 *     ...items.skip(5),
 *   ],
 * )
 * ```
 * 
 * Sticky banner at bottom:
 * ```dart
 * Scaffold(
 *   body: ...,
 *   bottomNavigationBar: Column(
 *     mainAxisSize: MainAxisSize.min,
 *     children: [
 *       StickyBannerWrapper(position: 'home'),
 *       YourBottomNav(),
 *     ],
 *   ),
 * )
 * ```
 * 
 * Show popup after X swipes (use mixin):
 * ```dart
 * class _DiscoverState extends ConsumerState<Discover> 
 *     with InterstitialBannerMixin {
 *   
 *   void _onSwipe() {
 *     incrementSwipeCount();
 *     checkAndShowInterstitial(context, 'discover');
 *   }
 * }
 * ```
 * 
 * 
 * 2. DAILY REWARDS INTEGRATION (Profile screen)
 * ----------------------------------------------
 * 
 * Full card with streak info:
 * ```dart
 * DailyRewardsButton.card()
 * ```
 * 
 * Compact button for app bar:
 * ```dart
 * AppBar(
 *   actions: [DailyRewardsButton.compact()],
 * )
 * ```
 * 
 * FAB for screens (shows only when claimable):
 * ```dart
 * Scaffold(
 *   floatingActionButton: DailyRewardsFAB(),
 * )
 * ```
 * 
 * 
 * 3. BADGES INTEGRATION (Settings/Profile screens)
 * -------------------------------------------------
 * 
 * Settings tile with notification:
 * ```dart
 * BadgesSettingsTile()
 * BadgesSettingsTile.compact() // For list tiles
 * ```
 * 
 * Profile badges display:
 * ```dart
 * ProfileBadgesDisplay(
 *   userId: userId, // null for own profile
 *   onViewAll: () => context.push('/badges'),
 * )
 * ```
 * 
 * Mini preview for cards/lists:
 * ```dart
 * MiniBadgePreview(userId: user.id)
 * ```
 * 
 * 
 * 4. PURCHASE PROMO INTEGRATION (Checkout screen)
 * ------------------------------------------------
 * 
 * Full promo section with active promotions and input:
 * ```dart
 * PurchasePromoSection(
 *   productId: 'gold_monthly',
 *   initialPromoCode: promoFromDeepLink,
 *   onPromoApplied: (result) {
 *     setState(() => _appliedPromo = result);
 *   },
 * )
 * ```
 * 
 * Price display with discount:
 * ```dart
 * PriceDisplay(
 *   originalPrice: 19.99,
 *   discountedPrice: 14.99,
 *   period: 'month',
 * )
 * ```
 * 
 * Order summary:
 * ```dart
 * OrderSummary(
 *   planName: 'Gold Premium',
 *   originalPrice: 19.99,
 *   promo: appliedPromo,
 *   period: 'month',
 * )
 * ```
 * 
 * 
 * POSITION VALUES
 * ---------------
 * - 'home' - Home/main screen
 * - 'discover' - Discovery/swiping screen
 * - 'chat' - Chat list screen
 * - 'profile' - Profile screen
 * - 'settings' - Settings screen
 * - 'plans' - Subscription plans screen
 * - 'matches' - Matches screen
 * 
 */
