import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/app_logger.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/utils/call_navigation.dart';
import '../../features/notifications/data/models/notification.dart' as app_models;
import '../../routes/app_router.dart';

/// Resolves in-app routes for notification taps (push, in-app list, URL schemes).
class NotificationNavigation {
  NotificationNavigation._();

  /// Types that open a 1:1 chat thread (match always goes to matches list first).
  static const Set<String> _chatThreadTypes = {
    'message',
    'chat',
    'superlike',
    'superlike_sent',
  };

  /// Peer user id from push / OneSignal `data` or nested `data` JSON.
  static int? resolvePeerUserId(Map<String, dynamic> source) {
    for (final key in const [
      'user_id',
      'sender_id',
      'from_user_id',
      'peer_id',
    ]) {
      final parsed = _parsePositiveInt(source[key]);
      if (parsed != null) return parsed;
    }

    final nested = source['data'];
    if (nested is Map) {
      return resolvePeerUserId(Map<String, dynamic>.from(nested));
    }
    if (nested is String && nested.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) {
          return resolvePeerUserId(Map<String, dynamic>.from(decoded));
        }
      } catch (e) {
        AppLogger.warning(
          'Nested notification data JSON parse failed',
          tag: 'Notifications',
          error: e,
        );
      }
    }

    // Legacy alias: chat_id was sometimes used as the other user's id.
    final chatId = _parsePositiveInt(source['chat_id']);
    if (chatId != null) return chatId;

    return null;
  }

  static int? resolvePeerUserIdFromNotification(app_models.Notification notification) {
    final fromModel = notification.userId;
    if (fromModel != null && fromModel > 0) return fromModel;

    final data = notification.data;
    if (data != null && data.isNotEmpty) {
      final fromData = resolvePeerUserId(data);
      if (fromData != null) return fromData;
    }

    return null;
  }

  /// GoRouter location for a 1:1 chat thread, or null if [userId] invalid.
  static String? chatThreadLocation({
    required int userId,
    String? userName,
    String? avatarUrl,
  }) {
    if (userId <= 0) return null;

    return Uri(
      path: AppRoutes.chat,
      queryParameters: {
        'userId': userId.toString(),
        if (userName != null && userName.trim().isNotEmpty) 'userName': userName.trim(),
        if (avatarUrl != null && avatarUrl.trim().isNotEmpty) 'avatarUrl': avatarUrl.trim(),
      },
    ).toString();
  }

  /// Destination route for a notification [type] and payload.
  static String resolveDestination({
    required String type,
    Map<String, dynamic> data = const {},
    int? peerUserId,
    bool planRestricted = false,
    bool upgradeRequired = false,
    String? userName,
    String? avatarUrl,
  }) {
    final normalized = type.toLowerCase().trim();
    final userId = peerUserId ?? resolvePeerUserId(data);
    final restricted = planRestricted || upgradeRequired || data['plan_restricted'] == true;

    if (restricted && (userId == null || userId <= 0)) {
      return AppRoutes.featureLocked;
    }

    final name = userName ?? data['user_name']?.toString();
    final avatar = avatarUrl ?? data['avatar_url']?.toString() ?? data['user_avatar']?.toString();

    if (userId != null && userId > 0 && _chatThreadTypes.contains(normalized)) {
      return chatThreadLocation(
            userId: userId,
            userName: name,
            avatarUrl: avatar,
          ) ??
          '${AppRoutes.home}/chat-list';
    }

    switch (normalized) {
      case 'message':
      case 'chat':
        if (userId != null && userId > 0) {
          return chatThreadLocation(userId: userId, userName: name, avatarUrl: avatar) ??
              '${AppRoutes.home}/chat-list';
        }
        return '${AppRoutes.home}/chat-list';
      case 'match':
      case 'like':
        return '${AppRoutes.home}/matches';
      case 'superlike':
      case 'superlike_sent':
      case 'superlike_received':
        if (userId != null && userId > 0) {
          return chatThreadLocation(userId: userId, userName: name, avatarUrl: avatar) ??
              '${AppRoutes.home}/discovery';
        }
        return '${AppRoutes.home}/discovery';
      case 'call':
      case 'incoming_call':
      case 'incoming_call_audio':
      case 'incoming_call_video':
        final incoming = IncomingCallData.fromPayload(data);
        if (incoming != null) {
          return activeCallLocationFromIncoming(incoming);
        }
        return AppRoutes.home;
      case 'active_call':
        final location = data['location']?.toString();
        if (location != null && location.trim().isNotEmpty) {
          return location.trim();
        }
        return AppRoutes.home;
      case 'missed_call':
      case 'call_declined':
      case 'call_not_answered':
        if (userId != null && userId > 0) {
          return Uri(
            path: AppRoutes.peerCallHistory,
            queryParameters: {'userId': userId.toString()},
          ).toString();
        }
        return '${AppRoutes.home}/chat-list';
      case 'notification':
        return '${AppRoutes.home}/notifications';
      case 'plan_purchased':
      case 'plan_granted':
      case 'plan_upgraded':
      case 'plan_downgraded':
      case 'subscription_renewed':
      case 'subscription_canceled':
      case 'subscription_cancelled':
      case 'subscription_expired':
      case 'subscription_reminder':
      case 'renewal_reminder':
      case 'payment_success':
      case 'payment_failed':
      case 'premium_feature':
        return AppRoutes.subscriptionManagement;
      case 'superlike_pack_purchased':
      case 'superlike_pack_finished':
      case 'superlike_pack_auto_activated':
        return AppRoutes.superlikePacks;
      case 'profile':
      case 'profile_view':
      case 'view':
      case 'visit':
      case 'profile_visit':
        if (userId != null && userId > 0) {
          return Uri(
            path: AppRoutes.profileDetail,
            queryParameters: {'userId': userId.toString()},
          ).toString();
        }
        return '${AppRoutes.home}/discovery';
      case 'safety_alert':
        return '${AppRoutes.home}/safety-center';
      case 'system_announcement':
      case 'announcement':
      case 'admin':
      case 'system':
      case 'general':
        return '${AppRoutes.home}/notifications';
      case 'verification_reminder':
      case 'verification_approved':
      case 'verification_rejected':
        return AppRoutes.profileVerification;
      case 'marketing':
      case 'promotion':
      case 'promo':
        return AppRoutes.subscriptionPlans;
      case 'story_like':
      case 'story_reply':
      case 'feed_like':
      case 'feed_comment':
      case 'comment':
      case 'reply':
      case 'comment_like':
        return '${AppRoutes.home}/discovery';
      default:
        return '${AppRoutes.home}/notifications';
    }
  }

  /// Types registered for push / deep-link tap handling.
  static const List<String> routableTypes = [
    'message',
    'chat',
    'match',
    'like',
    'superlike',
    'superlike_sent',
    'superlike_received',
    'call',
    'incoming_call',
    'incoming_call_audio',
    'incoming_call_video',
    'active_call',
    'missed_call',
    'call_declined',
    'call_not_answered',
    'profile',
    'profile_view',
    'view',
    'visit',
    'profile_visit',
    'notification',
    'plan_purchased',
    'plan_granted',
    'plan_upgraded',
    'plan_downgraded',
    'subscription_renewed',
    'subscription_canceled',
    'subscription_cancelled',
    'subscription_expired',
    'subscription_reminder',
    'renewal_reminder',
    'payment_success',
    'payment_failed',
    'premium_feature',
    'superlike_pack_purchased',
    'superlike_pack_finished',
    'superlike_pack_auto_activated',
    'safety_alert',
    'system_announcement',
    'announcement',
    'admin',
    'system',
    'general',
    'verification_reminder',
    'verification_approved',
    'verification_rejected',
    'marketing',
    'promotion',
    'promo',
    'story_like',
    'story_reply',
    'feed_like',
    'feed_comment',
    'comment',
    'reply',
    'comment_like',
  ];

  static String resolveFromNotification(app_models.Notification notification) {
    if (notification.actionUrl != null && notification.actionUrl!.trim().isNotEmpty) {
      return notification.actionUrl!.trim();
    }

    return resolveDestination(
      type: notification.type,
      data: notification.data ?? const {},
      peerUserId: resolvePeerUserIdFromNotification(notification),
      planRestricted: notification.isPlanRestricted,
      upgradeRequired: notification.upgradeRequired,
      userName: notification.userName,
      avatarUrl: notification.userImageUrl,
    );
  }

  static Map<String, dynamic> normalizePayload(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);
    final type = normalized['type']?.toString();
    if (type == 'chat') {
      normalized['type'] = 'message';
    }
    return normalized;
  }

  /// Navigate from push / deep-link payload.
  static void navigateWithRouter(
    GoRouter router, {
    required Map<String, dynamic> data,
    bool usePush = false,
  }) {
    final payload = normalizePayload(data);
    final type = payload['type']?.toString() ?? 'notification';
    final location = resolveDestination(
      type: type,
      data: payload,
      peerUserId: resolvePeerUserId(payload),
      planRestricted: payload['plan_restricted'] == true,
      upgradeRequired: payload['upgrade_required'] == true,
    );

    if (usePush) {
      router.push(location);
    } else {
      router.go(location);
    }
  }

  static void navigateFromNotification(
    BuildContext context,
    app_models.Notification notification, {
    bool usePush = true,
  }) {
    final location = resolveFromNotification(notification);
    if (usePush) {
      context.push(location);
    } else {
      context.go(location);
    }
  }

  static Map<String, dynamic>? parseLocalNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return normalizePayload(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      AppLogger.warning(
        'Local notification payload JSON parse failed',
        tag: 'Notifications',
        error: e,
      );
    }

    return null;
  }

  static int? _parsePositiveInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}
