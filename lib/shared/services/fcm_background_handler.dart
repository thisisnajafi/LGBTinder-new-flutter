import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/data/services/call_kit_service.dart';
import '../../core/services/app_logger.dart';
import 'background_message_display.dart';

export 'background_message_display.dart'
    show
        kLgbtfinderFcmChannelId,
        kLgbtfinderMessagesChannelId,
        kLgbtfinderLikesChannelId,
        kLgbtfinderMatchesChannelId,
        kLgbtfinderCallsChannelId,
        notificationChannelIdFor,
        notificationChannelLabel;

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

  await _showBackgroundLocalNotification(
    message,
    data,
    hasOsNotificationPayload: message.notification != null,
  );
}

Future<void> _showBackgroundLocalNotification(
  RemoteMessage message,
  Map<String, dynamic> data, {
  required bool hasOsNotificationPayload,
}) async {
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

  final tag = BackgroundMessageDisplay.trayTagForMessage(
    data['message_id'] ?? message.messageId,
  );

  try {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_lgbtfinder',
    );
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final active = await _readTray(plugin);
    final post = BackgroundMessageDisplay.shouldPostLocalNotification(
      hasOsNotificationPayload: hasOsNotificationPayload,
      isCallPayload: false,
      trayAlreadyShowsMessage: BackgroundMessageDisplay.trayAlreadyShowsMessage(
        title: text.title,
        body: text.body,
        active: active,
      ),
    );
    if (!post) {
      AppLogger.info(
        'Background FCM left a single tray row for ${message.messageId}',
        tag: 'Notifications',
      );
      await _collapseDuplicateTrayRows(
        plugin,
        title: text.title,
        body: text.body,
        keepTag: tag,
      );
      return;
    }

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
      AndroidNotificationChannel(
        kLgbtfinderLikesChannelId,
        'Likes',
        description: 'Likes and Super Likes',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        kLgbtfinderMatchesChannelId,
        'Matches',
        description: 'New matches',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        kLgbtfinderCallsChannelId,
        'Calls',
        description: 'Missed calls and call updates',
        importance: Importance.high,
      ),
    ];
    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }

    final channelId = notificationChannelIdFor(data['type']?.toString());
    final androidDetails = AndroidNotificationDetails(
      channelId,
      notificationChannelLabel(channelId),
      channelDescription: channelId == kLgbtfinderMessagesChannelId
          ? 'New chat messages'
          : 'Notifications for LGBTFinder app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_lgbtfinder',
      color: const Color(0xFFEC4899),
      tag: tag,
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
    // The OS may still be inserting the FCM notification row. Wait so the
    // collapse sees both and leaves one.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _collapseDuplicateTrayRows(
      plugin,
      title: text.title,
      body: text.body,
      keepTag: tag,
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

Future<List<BackgroundTrayItem>> _readTray(
  FlutterLocalNotificationsPlugin plugin,
) async {
  try {
    final active = await plugin.getActiveNotifications();
    return [
      for (final item in active)
        BackgroundTrayItem(
          id: item.id,
          tag: item.tag,
          title: item.title,
          body: item.body,
        ),
    ];
  } catch (e) {
    AppLogger.warning(
      'Active notification list failed',
      tag: 'Notifications',
      error: e,
    );
    return const [];
  }
}

/// Drop every shade row for this message except one.
Future<void> _collapseDuplicateTrayRows(
  FlutterLocalNotificationsPlugin plugin, {
  required String title,
  required String body,
  required String keepTag,
}) async {
  final extras = BackgroundMessageDisplay.extrasToCancel(
    title: title,
    body: body,
    keepTag: keepTag,
    active: await _readTray(plugin),
  );
  for (final extra in extras) {
    final id = extra.id;
    if (id == null) continue;
    try {
      await plugin.cancel(id, tag: extra.tag);
    } catch (e) {
      AppLogger.warning(
        'Duplicate notification cancel failed',
        tag: 'Notifications',
        error: e,
      );
    }
  }
}
