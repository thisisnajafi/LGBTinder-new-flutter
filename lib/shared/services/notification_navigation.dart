import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/data/models/notification.dart' as app_models;
import '../../routes/app_router.dart';

/// Resolves in-app routes for notification taps (push, in-app list, URL schemes).
class NotificationNavigation {
  NotificationNavigation._();

  static const Set<String> _chatThreadTypes = {
    'message',
    'chat',
    'match',
    'superlike',
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
      } catch (_) {}
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
        if (userId != null && userId > 0) {
          return chatThreadLocation(userId: userId, userName: name, avatarUrl: avatar) ??
              '${AppRoutes.home}/matches';
        }
        return '${AppRoutes.home}/matches';
      case 'superlike':
        if (userId != null && userId > 0) {
          return chatThreadLocation(userId: userId, userName: name, avatarUrl: avatar) ??
              '${AppRoutes.home}/discovery';
        }
        return '${AppRoutes.home}/discovery';
      case 'like':
        return '${AppRoutes.home}/matches';
      case 'call':
      case 'incoming_call':
      case 'incoming_call_audio':
      case 'incoming_call_video':
        if (userId != null && userId > 0) {
          return chatThreadLocation(userId: userId, userName: name, avatarUrl: avatar) ??
              AppRoutes.chat;
        }
        return AppRoutes.chat;
      case 'notification':
        return '${AppRoutes.home}/notifications';
      case 'profile':
      case 'profile_view':
        if (userId != null && userId > 0) {
          return Uri(
            path: AppRoutes.profileDetail,
            queryParameters: {'userId': userId.toString()},
          ).toString();
        }
        return '${AppRoutes.home}/discovery';
      default:
        return '${AppRoutes.home}/notifications';
    }
  }

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
    } catch (_) {}

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
