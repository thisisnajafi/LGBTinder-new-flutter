import 'package:flutter/material.dart';

import '../../data/models/notification.dart' as app_models;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../shared/services/notification_navigation.dart';

/// Visual rules for notification list leading icons.
class NotificationVisuals {
  NotificationVisuals._();

  static const Set<String> _systemTypes = {
    'plan_purchased',
    'plan_granted',
    'plan_upgraded',
    'plan_downgraded',
    'subscription_renewed',
    'subscription_canceled',
    'subscription_expired',
    'subscription_reminder',
    'payment_failed',
    'payment_success',
    'marketing',
    'promotion',
    'promo',
    'system',
    'announcement',
    'admin',
    'renewal_reminder',
    'premium_feature',
    'verification_reminder',
    'general',
    'info',
    'safety_alert',
    'safety',
    'report',
    'moderation',
    'system_announcement',
  };

  static const Set<String> _userTypes = {
    'like',
    'match',
    'superlike',
    'superlike_sent',
    'superlike_received',
    'message',
    'chat',
    'view',
    'profile_view',
    'profile',
    'visit',
    'profile_visit',
    'incoming_call',
    'incoming_call_audio',
    'incoming_call_video',
    'call',
    'missed_call',
    'missed-call',
    'call_missed',
    'call.missed',
    'story_like',
    'story_reply',
    'feed_like',
    'feed_comment',
    'comment',
    'reply',
    'comment_like',
  };

  static bool isUserRelated(app_models.Notification notification) {
    final type = notification.type.toLowerCase().trim();
    if (_systemTypes.contains(type)) return false;
    if (_userTypes.contains(type)) return true;
    if (notification.userId != null && notification.userId! > 0) return true;
    final peerId = NotificationNavigation.resolvePeerUserIdFromNotification(
      notification,
    );
    return peerId != null && peerId > 0;
  }

  static String? actorImageUrl(app_models.Notification notification) {
    final direct = _cleanUrl(notification.userImageUrl);
    if (direct != null) return direct;

    final data = notification.data;
    if (data == null) return null;

    for (final key in const [
      'avatar_url',
      'user_avatar',
      'from_user_avatar',
      'profile_image',
      'image_url',
    ]) {
      final url = _cleanUrl(data[key]?.toString());
      if (url != null) return url;
    }

    final fromUser = data['from_user'];
    if (fromUser is Map) {
      final avatar = _cleanUrl(fromUser['avatar']?.toString());
      if (avatar != null) return avatar;
    }

    return null;
  }

  static String? actorInitial(app_models.Notification notification) {
    final name = notification.userName?.trim();
    if (name != null && name.isNotEmpty && name.toLowerCase() != 'anonymous') {
      return name[0].toUpperCase();
    }

    final dataName = notification.data?['user_name']?.toString().trim();
    if (dataName != null && dataName.isNotEmpty) {
      return dataName[0].toUpperCase();
    }

    return null;
  }

  static String iconAssetFor(app_models.Notification notification) {
    switch (notification.type.toLowerCase().trim()) {
      case 'like':
      case 'match':
        return AppIcons.heart;
      case 'superlike':
      case 'superlike_sent':
      case 'superlike_received':
        return AppIcons.star;
      case 'message':
      case 'chat':
        return AppIcons.message;
      case 'view':
      case 'profile_view':
      case 'profile':
      case 'visit':
      case 'profile_visit':
        return AppIcons.eye;
      case 'plan_purchased':
      case 'plan_granted':
      case 'plan_upgraded':
      case 'premium_feature':
        return AppIcons.crown;
      case 'subscription_renewed':
      case 'payment_success':
        return AppIcons.getIconPath('tick-circle');
      case 'subscription_canceled':
      case 'subscription_expired':
      case 'payment_failed':
        return AppIcons.getIconPath('warning-2');
      case 'marketing':
      case 'promotion':
      case 'promo':
        return AppIcons.getIconPath('gift');
      case 'verification_reminder':
        return AppIcons.verify;
      case 'incoming_call':
      case 'incoming_call_audio':
      case 'incoming_call_video':
      case 'call':
        return AppIcons.call;
      case 'missed_call':
      case 'missed-call':
      case 'call_missed':
      case 'call.missed':
        return AppIcons.callMissed;
      case 'safety_alert':
      case 'safety':
      case 'report':
      case 'moderation':
        return AppIcons.shield;
      case 'system':
      case 'announcement':
      case 'admin':
      case 'general':
      case 'info':
      case 'system_announcement':
        return AppIcons.infoCircle;
      default:
        return AppIcons.notification;
    }
  }

  static Color accentFor(app_models.Notification notification) {
    switch (notification.type.toLowerCase().trim()) {
      case 'like':
      case 'match':
        return AppColors.accentRose;
      case 'superlike':
      case 'superlike_sent':
      case 'superlike_received':
        return AppColors.warningYellow;
      case 'message':
      case 'chat':
        return AppColors.accentViolet;
      case 'plan_purchased':
      case 'plan_granted':
      case 'plan_upgraded':
      case 'premium_feature':
        return AppColors.warningYellow;
      case 'subscription_canceled':
      case 'payment_failed':
        return AppColors.feedbackError;
      case 'subscription_renewed':
      case 'payment_success':
        return AppColors.feedbackSuccess;
      case 'missed_call':
      case 'missed-call':
      case 'call_missed':
      case 'call.missed':
        return AppColors.feedbackError;
      case 'safety_alert':
      case 'safety':
      case 'report':
      case 'moderation':
        return AppColors.feedbackWarning;
      case 'system':
      case 'announcement':
      case 'admin':
      case 'general':
      case 'info':
      case 'system_announcement':
        return AppColors.feedbackInfo;
      default:
        return AppColors.accentViolet;
    }
  }

  static String? _cleanUrl(String? raw) {
    final url = raw?.trim();
    if (url == null || url.isEmpty) return null;
    if (url.contains('default-avatar')) return null;
    return url;
  }
}
