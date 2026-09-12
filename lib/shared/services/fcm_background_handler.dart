import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/data/services/call_kit_service.dart';
import '../../core/services/app_logger.dart';
import '../../features/chat/providers/active_chat_peer_bridge.dart';
import '../../features/chat/utils/chat_fcm_suppress.dart';

/// Must match FCM `android.notification.channel_id` from the backend.
const String kLgbtfinderFcmChannelId = 'lgbtfinder_channel';

/// FCM background isolate entrypoint. Must stay a top-level function.
///
/// Killed-app incoming calls: data-only FCM → [IncomingCallData.fromPayload]
/// → [CallKitService.showIncomingFromIsolate]. Android needs
/// POST_NOTIFICATIONS (13+) and USE_FULL_SCREEN_INTENT (14) in the manifest.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized in this isolate.
  }

  final data = Map<String, dynamic>.from(message.data);
  if (IncomingCallData.isCallPayload(data)) {
    final parsed = IncomingCallData.fromPayload(data);
    if (parsed != null) {
      AppLogger.info(
        'FCM incoming call ${parsed.callId} type=${parsed.callType} channel=${parsed.channelName}',
        tag: 'CallKit',
      );
      await CallKitService.showIncomingFromIsolate(parsed);
    } else {
      AppLogger.warning(
        'FCM call payload missing required fields',
        tag: 'CallKit',
      );
    }
    return;
  }

  if (await _shouldSuppressBackgroundMessage(data)) {
    AppLogger.info(
      'Suppressed background FCM banner for the open chat',
      tag: 'Notifications',
    );
    return;
  }

  // Data-only message pushes: app must display (unless suppressed for open chat).
  if (message.notification != null &&
      (data['type']?.toString() ?? '') != 'message') {
    return;
  }

  await _showBackgroundLocalNotification(message);
}

Future<bool> _shouldSuppressBackgroundMessage(Map<String, dynamic> data) async {
  if (!ChatFcmSuppress.isChatPayload(data)) return false;

  final activePeer = await ActiveChatPeerBridge.readActivePeerFromPrefs();
  final activeConversation =
      await ActiveChatPeerBridge.readActiveConversationFromPrefs();
  return ChatFcmSuppress.matchesOpenChat(
    data,
    activePeerUserId: activePeer,
    activeConversationId: activeConversation,
  );
}

Future<void> _showBackgroundLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title ??
      message.data['title']?.toString() ??
      message.data['headings']?.toString();
  final body = message.notification?.body ??
      message.data['body']?.toString() ??
      message.data['message']?.toString();
  if (title == null || body == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await plugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final androidDetails = AndroidNotificationDetails(
    kLgbtfinderFcmChannelId,
    'LGBTFinder Notifications',
    channelDescription: 'Notifications for LGBTFinder app',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final id = message.data['message_id']?.hashCode ??
      message.messageId?.hashCode ??
      DateTime.now().millisecondsSinceEpoch % 2147483647;

  await plugin.show(
    id,
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(message.data),
  );

  AppLogger.debug(
    'Background FCM displayed local notification ${message.messageId}',
    tag: 'FCM',
  );
}
