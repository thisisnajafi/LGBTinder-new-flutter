import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';

/// Marketing deep link handler
/// Handles deep links for marketing features
/// Part of the Marketing System Implementation (Task 4.3.2)
class MarketingDeepLinkHandler {
  static final MarketingDeepLinkHandler _instance =
      MarketingDeepLinkHandler._internal();
  factory MarketingDeepLinkHandler() => _instance;
  MarketingDeepLinkHandler._internal();

  /// Marketing route patterns
  static const List<String> marketingRoutes = [
    '/plans',
    '/daily-rewards',
    '/referral',
    '/badges',
    '/promotions',
  ];

  /// Handle a deep link
  /// Returns true if the link was handled, false otherwise
  bool handleDeepLink(BuildContext context, Uri uri) {
    final path = uri.path;
    final queryParams = uri.queryParameters;

    // Check if this is a marketing route
    if (!isMarketingDeepLink(uri)) {
      return false;
    }

    // Handle each marketing route
    switch (path) {
      case '/plans':
        return _handlePlansDeepLink(context, queryParams);
      case '/daily-rewards':
        return _handleDailyRewardsDeepLink(context, queryParams);
      case '/referral':
        return _handleReferralDeepLink(context, queryParams);
      case '/badges':
        return _handleBadgesDeepLink(context, queryParams);
      case '/promotions':
        return _handlePromotionsDeepLink(context, queryParams);
      default:
        // Check for profile deep links
        if (path.startsWith('/profile/')) {
          return _handleProfileDeepLink(context, path, queryParams);
        }
        return false;
    }
  }

  /// Check if URI is a marketing deep link
  bool isMarketingDeepLink(Uri uri) {
    final path = uri.path;
    return marketingRoutes.any((route) => path.startsWith(route)) ||
        path.startsWith('/profile/');
  }

  /// Handle /plans deep link
  bool _handlePlansDeepLink(
    BuildContext context,
    Map<String, String> queryParams,
  ) {
    final promoCode = queryParams['promo'];
    final planId = queryParams['plan'];
    final qp = <String, String>{};
    if (promoCode != null && promoCode.isNotEmpty) qp['promo'] = promoCode;
    if (planId != null && planId.isNotEmpty) qp['plan'] = planId;
    final target = Uri(path: AppRoutes.subscriptionPlans, queryParameters: qp.isEmpty ? null : qp).toString();
    context.push(target);

    return true;
  }

  /// Handle /daily-rewards deep link
  bool _handleDailyRewardsDeepLink(
    BuildContext context,
    Map<String, String> queryParams,
  ) {
    context.push(AppRoutes.home);
    return true;
  }

  /// Handle /referral deep link
  bool _handleReferralDeepLink(
    BuildContext context,
    Map<String, String> queryParams,
  ) {
    final code = queryParams['code'];
    final target = Uri(
      path: AppRoutes.home,
      queryParameters: code != null && code.isNotEmpty ? {'tab': 'settings', 'referralCode': code} : {'tab': 'settings'},
    ).toString();
    context.push(target);
    return true;
  }

  /// Handle /badges deep link
  bool _handleBadgesDeepLink(
    BuildContext context,
    Map<String, String> queryParams,
  ) {
    context.push('${AppRoutes.home}/profile');
    return true;
  }

  /// Handle /promotions deep link
  bool _handlePromotionsDeepLink(
    BuildContext context,
    Map<String, String> queryParams,
  ) {
    final campaignId = queryParams['campaign'];
    final target = Uri(
      path: AppRoutes.subscriptionPlans,
      queryParameters: campaignId != null && campaignId.isNotEmpty ? {'campaign': campaignId} : null,
    ).toString();
    context.push(target);
    return true;
  }

  /// Handle /profile/:id deep link
  bool _handleProfileDeepLink(
    BuildContext context,
    String path,
    Map<String, String> queryParams,
  ) {
    // Extract profile ID from path
    final segments = path.split('/');
    if (segments.length >= 3) {
      final profileId = segments[2];
      if (!RegExp(r'^\d+$').hasMatch(profileId)) {
        return false;
      }
      final target = Uri(path: AppRoutes.profileDetail, queryParameters: {'userId': profileId}).toString();
      context.push(target);
      return true;
    }
    return false;
  }

  /// Parse deep link from string
  static Uri? parseDeepLink(String? link) {
    if (link == null || link.isEmpty) {
      return null;
    }

    // Handle different URL schemes
    String normalizedLink = link;

    // Handle app-specific scheme
    if (link.startsWith('lgbtfinder://')) {
      normalizedLink = link.replaceFirst('lgbtfinder://', 'https://lgbtfinder.app/');
    }

    // Handle relative paths
    if (link.startsWith('/')) {
      normalizedLink = 'https://lgbtfinder.app$link';
    }

    try {
      return Uri.parse(normalizedLink);
    } catch (_) {
      return null;
    }
  }

  /// Generate deep link for sharing
  static String generateDeepLink(String path, {Map<String, String>? params}) {
    final uri = Uri(
      scheme: 'lgbtfinder',
      host: 'app',
      path: path,
      queryParameters: params,
    );
    return uri.toString();
  }

  /// Generate web deep link for sharing
  static String generateWebDeepLink(String path, {Map<String, String>? params}) {
    final uri = Uri(
      scheme: 'https',
      host: 'lgbtfinder.app',
      path: path,
      queryParameters: params,
    );
    return uri.toString();
  }
}

/// Deep link route configuration for marketing features
/// Use this with go_router to set up marketing routes
class MarketingRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: AppRoutes.subscriptionPlans,
      builder: (context, state) {
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: '${AppRoutes.home}/discovery',
      builder: (context, state) {
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: '${AppRoutes.home}/profile',
      builder: (context, state) {
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: '${AppRoutes.home}/settings',
      builder: (context, state) {
        return const SizedBox.shrink();
      },
    ),
  ];
}

/// Provider for deep link handler
final marketingDeepLinkHandlerProvider = Provider<MarketingDeepLinkHandler>((ref) {
  return MarketingDeepLinkHandler();
});
