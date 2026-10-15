import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/data/services/call_kit_service.dart';
import '../../core/services/app_logger.dart';
import '../../features/chat/utils/chat_fcm_suppress.dart';
import 'background_message_display.dart';

export 'background_message_display.dart'
    show kLgbtfinderFcmChannelId, kLgbtfinderMessagesChannelId;

/// FCM background isolate entrypoint. Must stay a top-level function.
///
/// Killed-app incoming calls: data-only FCM → [IncomingCallData.fromPayload]
/// → [CallKitService.showIncomingFromIsolate]. Android needs
/// POST_NOTIFICATIONS (13+) and USE_FULL_SCREEN_INTENT (14) in the manifest.
///
/// Data-only chat (and other) pushes are shown here. A payload that already
/// includes an OS notification is left to Android/iOS so it is not posted
/// twice. This isolate does not run for the conversation that is open in the
/// foreground, so a stored active-chat id must not hide the tray item.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

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

  if (!BackgroundMessageDisplay.shouldPostLocalNotification(
    hasOsNotificationPayload: message.notification != null,
    isCallPayload: false,
  )) {
    AppLogger.info(
      'Background FCM left to the OS notification payload',
      tag: 'Notifications',
    );
    return;
  }

  await _showBackgroundLocalNotification(message, data);
}

Future<void> _showBackgroundLocalNotification(
  RemoteMessage message,
  Map<String, dynamic> data,
) async {
  final text = BackgroundMessageDisplay.resolveText(
    notificationTitle: message.notification?.title,
    notificationBody: message.notification?.body,
    data: data,
  );
  if (text == null) {
    AppLogger.warning(
      'Background FCM had no title or body to display',
      tag: 'Notifications',
    );
    return;
  }

  try {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        kLgbtfinderMessagesChannelId,
        'Messages',
        description: 'New chat messages',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        kLgbtfinderFcmChannelId,
        'LGBTFinder Notifications',
        description: 'Notifications for LGBTFinder app',
        importance: Importance.high,
      ),
    ];
    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    final isChat = ChatFcmSuppress.isChatPayload(data);
    final channelId = isChat
        ? kLgbtfinderMessagesChannelId
        : kLgbtfinderFcmChannelId;
    final androidDetails = AndroidNotificationDetails(
      channelId,
      isChat ? 'Messages' : 'LGBTFinder Notifications',
      channelDescription: isChat
          ? 'New chat messages'
          : 'Notifications for LGBTFinder app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final id =
        data['message_id']?.hashCode ??
        message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch % 2147483647;

    await plugin.show(
      id,
      text.title,
      text.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );

    AppLogger.info(
      'Background FCM displayed local notification ${message.messageId}',
      tag: 'FCM',
    );
  } catch (e, stack) {
    AppLogger.error(
      'Background FCM local notification failed',
      tag: 'Notifications',
      error: e,
      stackTrace: stack,
    );
  }
}
