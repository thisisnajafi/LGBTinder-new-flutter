import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/campaign_model.dart';

/// Marketing notification handler
/// Handles incoming marketing push notifications and routes to appropriate screens
/// Part of the Marketing System Implementation (Task 4.3.1)
class MarketingNotificationService {
  static final MarketingNotificationService _instance =
      MarketingNotificationService._internal();
  factory MarketingNotificationService() => _instance;
  MarketingNotificationService._internal();

  /// Notification type constants
  static const String typeReEngagement = 're_engagement';
  static const String typePromotional = 'promotional';
  static const String typeRenewal = 'renewal';
  static const String typeDailyRewards = 'daily_rewards';
  static const String typeAchievement = 'achievement';
  static const String typeChurnPrevention = 'churn_prevention';
  static const String typeSystem = 'system';

  /// Handle incoming notification payload
  Future<void> handleNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final type = payload['type']?.toString();
    final deepLink = payload['deep_link']?.toString();
    final template = payload['template']?.toString();

    // Track notification open
    await _trackNotificationOpen(payload);

    // Route based on type
    switch (type) {
      case typeReEngagement:
        await _handleReEngagementNotification(context, payload);
        break;
      case typePromotional:
        await _handlePromotionalNotification(context, payload);
        break;
      case typeRenewal:
        await _handleRenewalNotification(context, payload);
        break;
      case typeDailyRewards:
        await _handleDailyRewardsNotification(context, payload);
        break;
      case typeAchievement:
        await _handleAchievementNotification(context, payload);
        break;
      case typeChurnPrevention:
        await _handleChurnPreventionNotification(context, payload);
        break;
      case typeSystem:
        await _handleSystemNotification(context, payload);
        break;
      default:
        // Fallback to deep link if available
        if (deepLink != null && deepLink.isNotEmpty) {
          _navigateToDeepLink(context, deepLink);
        }
    }
  }

  /// Handle re-engagement notifications
  Future<void> _handleReEngagementNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final template = payload['template']?.toString();
    final deepLink = payload['deep_link']?.toString();

    switch (template) {
      case '3_days_inactive':
      case '7_days_inactive':
        // Navigate to likes/matches
        _navigateToDeepLink(context, deepLink ?? '/likes');
        break;
      case '14_days_inactive':
        // Navigate to daily rewards
        _navigateToDeepLink(context, '/daily-rewards');
        break;
      case '30_days_inactive':
        // Navigate to discover
        _navigateToDeepLink(context, '/discover');
        break;
      default:
        _navigateToDeepLink(context, deepLink ?? '/home');
    }
  }

  /// Handle promotional notifications
  Future<void> _handlePromotionalNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final deepLink = payload['deep_link']?.toString();
    final promoCode = payload['promo_code']?.toString();

    if (promoCode != null) {
      // Navigate to plans with promo code
      context.push('/plans?promo=$promoCode');
    } else if (deepLink != null) {
      _navigateToDeepLink(context, deepLink);
    } else {
      context.push('/plans');
    }
  }

  /// Handle renewal notifications
  Future<void> _handleRenewalNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final deepLink = payload['deep_link']?.toString();
    final template = payload['template']?.toString();

    // Check if there's a special offer
    if (template == 'renewal_3_days' || template == 'subscription_expired') {
      // Navigate to plans with promo
      context.push('/plans?promo=RENEW30');
    } else if (deepLink != null) {
      _navigateToDeepLink(context, deepLink);
    } else {
      context.push('/subscription');
    }
  }

  /// Handle daily rewards notifications
  Future<void> _handleDailyRewardsNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    context.push('/daily-rewards');
  }

  /// Handle achievement notifications
  Future<void> _handleAchievementNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    context.push('/badges');
  }

  /// Handle churn prevention notifications
  Future<void> _handleChurnPreventionNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final template = payload['template']?.toString();
    final deepLink = payload['deep_link']?.toString();

    if (template == 'churn_special_offer' || template == 'churn_win_back') {
      context.push('/plans?promo=STAYWITHUS');
    } else if (deepLink != null) {
      _navigateToDeepLink(context, deepLink);
    } else {
      context.push('/matches');
    }
  }

  /// Handle system notifications (matches, messages, etc.)
  Future<void> _handleSystemNotification(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final template = payload['template']?.toString();
    final deepLink = payload['deep_link']?.toString();

    switch (template) {
      case 'new_match':
        final matchId = payload['match_id']?.toString();
        if (matchId != null) {
          context.push('/chat/$matchId');
        } else {
          context.push('/matches');
        }
        break;
      case 'new_message':
        final chatId = payload['chat_id']?.toString();
        if (chatId != null) {
          context.push('/chat/$chatId');
        } else {
          context.push('/chats');
        }
        break;
      case 'new_like':
        context.push('/likes');
        break;
      case 'profile_view':
        context.push('/profile/views');
        break;
      default:
        if (deepLink != null) {
          _navigateToDeepLink(context, deepLink);
        }
    }
  }

  /// Navigate to a deep link
  void _navigateToDeepLink(BuildContext context, String deepLink) {
    // Clean up the deep link
    String path = deepLink;
    if (path.startsWith('lgbtfinder://')) {
      path = path.replaceFirst('lgbtfinder://', '/');
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    context.push(path);
  }

  /// Track notification open for analytics
  Future<void> _trackNotificationOpen(Map<String, dynamic> payload) async {
    // This would call the API to track the open
    // For now, just log it
    final notificationId = payload['notification_id']?.toString();
    final template = payload['template']?.toString();

    if (notificationId != null || template != null) {
      // TODO: Call API to track open
      // await _apiService.post('/notifications/track-open', {
      //   'notification_id': notificationId,
      //   'template': template,
      //   'opened_at': DateTime.now().toIso8601String(),
      // });
    }
  }

  /// Parse notification data from different sources
  static Map<String, dynamic> parseNotificationData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      try {
        // Try to parse as JSON
        return {};
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  /// Check if notification is a marketing notification
  static bool isMarketingNotification(Map<String, dynamic> payload) {
    final type = payload['type']?.toString();
    return type == typeReEngagement ||
        type == typePromotional ||
        type == typeRenewal ||
        type == typeDailyRewards ||
        type == typeAchievement ||
        type == typeChurnPrevention;
  }
}
