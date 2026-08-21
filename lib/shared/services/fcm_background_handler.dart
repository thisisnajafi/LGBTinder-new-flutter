import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/data/services/call_kit_service.dart';
import '../../core/services/app_logger.dart';

/// FCM background isolate entrypoint. Must stay a top-level function.
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
      await CallKitService.showIncomingFromIsolate(parsed);
    }
    return;
  }

  // Display-payload messages are shown by the OS while backgrounded.
  if (message.notification != null) return;

  await _showBackgroundLocalNotification(message);
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
    'lgbtfinder_channel',
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
