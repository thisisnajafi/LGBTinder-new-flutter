/// Push Notification Service
/// FEATURE ENHANCEMENT (Task 9.1.2): Enhanced with deep linking and notification grouping
/// Handles Firebase Cloud Messaging (FCM) integration
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../services/api_service.dart';
import 'background_message_display.dart';
import 'notification_avatar_bitmap.dart';
import 'notification_payload_map.dart';
import 'notification_quick_actions.dart';
import 'incoming_call_handler.dart';
import 'deep_linking_service.dart';
import 'notification_navigation.dart';
import 'pending_launch_route.dart';
import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/data/models/active_call_notification.dart';
import '../../features/calls/data/models/active_call_session.dart';
import '../../features/settings/providers/sound_preferences_provider.dart';
import '../../features/settings/data/models/sound_preferences.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import '../../features/chat/providers/active_chat_peer_bridge.dart';
import '../../features/chat/providers/in_app_chat_banner_provider.dart';
import '../../features/chat/utils/chat_fcm_suppress.dart';
import '../../features/chat/utils/in_app_chat_banner.dart';
import '../../features/notifications/data/foreground_push_policy.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Service for handling push notifications
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  // API service for backend communication
  ApiService? _apiService;

  // Navigation callbacks
  void Function()? _navigateToMatches;
  void Function()? _navigateToMatch;
  void Function(String)? _navigateToChat;
  void Function()? _navigateToNotifications;
  Future<void> Function()? _onPremiumAccessChanged;

  static const Set<String> _premiumAccessTypes = {
    'plan_purchased',
    'plan_granted',
    'plan_upgraded',
    'plan_downgraded',
    'subscription_renewed',
    'subscription_canceled',
    'subscription_cancelled',
    'subscription_expired',
    'payment_success',
    'payment_failed',
    'premium_feature',
  };

  /// Set API service for backend communication and push the current token if we have one.
  void setApiService(ApiService apiService) {
    _apiService = apiService;
    final token = _fcmToken;
    if (token != null && token.isNotEmpty) {
      unawaited(_sendTokenToBackend(token));
    }
  }

  /// Set navigation callbacks
  void setNavigationCallbacks({
    void Function()? navigateToMatches,
    void Function()? navigateToMatch,
    void Function(String)? navigateToChat,
    void Function()? navigateToNotifications,
  }) {
    _navigateToMatches = navigateToMatches;
    _navigateToMatch = navigateToMatch;
    _navigateToChat = navigateToChat;
    _navigateToNotifications = navigateToNotifications;
  }

  /// Refresh cached subscription/tier state when premium access changes.
  void setPremiumAccessChangeHandler(Future<void> Function()? handler) {
    _onPremiumAccessChanged = handler;
  }

  bool _isPremiumAccessType(String type) => _premiumAccessTypes.contains(type);

  Future<void> _handlePremiumAccessNotification(
    Map<String, dynamic> data,
  ) async {
    final type = data['type']?.toString() ?? '';
    if (!_isPremiumAccessType(type)) return;

    try {
      await _onPremiumAccessChanged?.call();
    } catch (e) {
      AppLogger.debug('Premium access refresh failed: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    if (_apiService == null) {
      AppLogger.debug('API service not set, cannot send token to backend');
      return;
    }

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await _apiService!.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsRegisterDevice,
        data: {'device_token': token, 'platform': platform},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        AppLogger.info(
          'FCM token sent to backend successfully',
          tag: 'Notifications',
        );
      } else {
        AppLogger.error(
          'Failed to send FCM token to backend: ${response.message}',
          tag: 'Notifications',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error sending FCM token to backend: $e',
        tag: 'Notifications',
      );
    }
  }

  /// Initialize push notification service.
  /// Yields between steps so the main thread is never blocked for >1s (avoids ANR).
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeLocalNotifications();
    } catch (e) {
      AppLogger.debug('Local notifications init failed: $e');
    }

    try {
      await SoundService.instance.initialize();
      await _requestPermission();
      await Future.delayed(Duration.zero);
      await _getFCMToken();
      await Future.delayed(Duration.zero);
      _setupMessageHandlers();
    } catch (e) {
      AppLogger.debug('FCM init failed (local tray still available): $e');
    }

    _isInitialized = true;
  }

  /// Tray alert when Firebase has no API key. Real FCM still owns production.
  Future<void> showLocalChatAlert({
    required int messageId,
    required String title,
    required String body,
    required int senderId,
  }) async {
    if (!_isInitialized) {
      try {
        await _initializeLocalNotifications();
      } catch (e) {
        AppLogger.debug('Local chat alert skipped: $e');
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      kLgbtfinderFcmChannelId,
      'LGBTFinder Notifications',
      channelDescription: 'Notifications for LGBTFinder app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      groupKey: 'messages_$senderId',
      styleInformation: BigTextStyleInformation(body),
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    final id = messageId > 0
        ? messageId
        : DateTime.now().millisecondsSinceEpoch % 2147483647;
    await _localNotifications.show(id, title, body, details);
    AppLogger.info(
      'Local chat tray for message $messageId from $senderId',
      tag: 'Notifications',
    );
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.debug('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      AppLogger.debug('User granted provisional notification permission');
    } else {
      AppLogger.debug(
        'User declined or has not accepted notification permission',
      );
    }

    // Never show an OS banner while the app is open — in-app banners cover that.
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_lgbtfinder',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          ActiveCallNotification.iosCategory,
          actions: [
            DarwinNotificationAction.plain(
              ActiveCallNotification.actionReturn,
              'Return',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              ActiveCallNotification.actionHangup,
              'Hang up',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationAction,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kLgbtfinderMessagesChannelId,
        'Messages',
        description: 'New chat messages',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kLgbtfinderFcmChannelId,
        'LGBTFinder Notifications',
        description: 'Notifications for LGBTFinder app',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        ActiveCallNotification.androidChannelId,
        ActiveCallNotification.androidChannelName,
        description: 'Ongoing call — tap to return',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kLgbtfinderLikesChannelId,
        'Likes',
        description: 'Likes and Super Likes',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kLgbtfinderMatchesChannelId,
        'Matches',
        description: 'New matches',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kLgbtfinderCallsChannelId,
        'Calls',
        description: 'Missed calls and call updates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Terminated-app tap. Reads FCM and the local notification plugin before
  /// splash sends the user to Discover.
  Future<void> captureTerminatedLaunch() {
    return PendingLaunchRoute.capture(() async {
      try {
        await _initializeLocalNotifications();
        final launch = await _localNotifications.getNotificationAppLaunchDetails();
        final response = launch?.notificationResponse;
        final launched = launch?.didNotificationLaunchApp ?? false;
        PendingLaunchRoute.localLaunchCaptured = launched;
        PendingLaunchRoute.store(
          PendingLaunchRoute.payloadFromLocalLaunch(
            didLaunchApp: launched,
            payload: response?.payload,
            actionId: response?.actionId,
          ),
        );
      } catch (e) {
        AppLogger.debug('Local notification launch details failed: $e');
      }

      try {
        final message = await _firebaseMessaging.getInitialMessage();
        PendingLaunchRoute.initialMessageCaptured = true;
        PendingLaunchRoute.store(
          PendingLaunchRoute.payloadFromFcmData(
            message == null ? null : Map<String, dynamic>.from(message.data),
          ),
        );
      } catch (e) {
        AppLogger.debug('FCM initial message failed: $e');
      }
    });
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      AppLogger.debug('FCM Token: $_fcmToken');
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _sendTokenToBackend(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      AppLogger.debug('Error getting FCM token: $e');
      return null;
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.debug('Received foreground message: ${message.messageId}');
      unawaited(_onForegroundMessage(message));
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.debug('Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Terminated taps are stored by [captureTerminatedLaunch] and applied
    // after splash. A second getInitialMessage() is empty once consumed.
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (PendingLaunchRoute.initialMessageCaptured || message == null) return;
      AppLogger.debug(
        'App opened from terminated state: ${message.messageId}',
      );
      final data = PendingLaunchRoute.payloadFromFcmData(
        Map<String, dynamic>.from(message.data),
      );
      if (!PendingLaunchRoute.navigationReady) {
        PendingLaunchRoute.store(data);
        return;
      }
      if (data != null) {
        _handleNotificationTap(message);
      }
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      AppLogger.debug('FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      await _sendTokenToBackend(newToken);
    });
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (_isIncomingCallPayload(message.data)) {
      _handleIncomingCall(message.data);
      return;
    }
    unawaited(_handlePremiumAccessNotification(message.data));
    if (_shouldSuppressMessageAlert(message.data)) {
      final openChat = _isOpenChatMessage(message.data);
      AppLogger.info(
        openChat
            ? 'Suppressed FCM banner for the open chat'
            : 'Suppressed FCM banner for a muted chat',
        tag: 'Notifications',
      );
      if (openChat) {
        await _markSuppressedChatRead(message.data);
      }
      return;
    }

    final type = message.data['type']?.toString() ?? 'general';
    final fromUserId = NotificationNavigation.resolvePeerUserId(message.data);
    if (ForegroundPushPolicy.shouldSuppress(
      type: type,
      fromUserId: fromUserId,
    )) {
      AppLogger.info(
        'Suppressed FCM banner for muted user / quiet hours / disabled type ($type)',
        tag: 'Notifications',
      );
      return;
    }

    if (ChatFcmSuppress.isChatPayload(message.data) ||
        InAppChatBannerPolicy.fromGenericFcm(message.data) != null) {
      final isChat = ChatFcmSuppress.isChatPayload(message.data);
      final item = InAppChatBannerPolicy.fromFcm(
        message.data,
        notificationTitle: message.notification?.title,
        notificationBody: message.notification?.body,
      );
      if (item != null &&
          InAppChatBannerPolicy.shouldPresent(
            isChatPayload: isChat,
            isGenericPayload: !isChat,
            suppressedOpenOrMuted: false,
            isOwnMessage: false,
            appForeground: inAppChatBannerAppForeground(),
          ) &&
          InAppChatBannerBridge.tryPresent(item)) {
        AppLogger.info(
          'In-app banner from FCM type=${item.type} peer=${item.peerUserId}',
          tag: 'Notifications',
        );
        unawaited(_playPayloadSound(message.data));
        ForegroundPushPolicy.bumpUnread?.call();
        return;
      }
    }
    unawaited(_playPayloadSound(message.data));
    ForegroundPushPolicy.bumpUnread?.call();
    if (!ForegroundPushPolicy.shouldShowDeviceNotification(
      appForeground: inAppChatBannerAppForeground(),
      isIncomingCall: false,
    )) {
      AppLogger.info(
        'Skipped device push; showing in-app notification instead',
        tag: 'Notifications',
      );
      return;
    }
    await _showLocalNotification(message);
  }

  /// Show local notification
  /// FEATURE ENHANCEMENT (Task 9.1.2): Added notification grouping
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    if (_isIncomingCallPayload(data)) {
      _handleIncomingCall(data);
      return;
    }

    final mapped = MappedTrayNotification.from(
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
      data: data,
      fallbackId: message.messageId,
    );
    if (mapped == null) return;
    final title = mapped.title;
    final body = mapped.body;
    final type = mapped.type;

    if (_shouldSuppressMessageAlert(mapped.data)) {
      return;
    }

    final channelId = mapped.channelId;
    final groupKey = mapped.groupKey;
    final isChat = mapped.style == TrayStyleKind.messaging;
    final avatar = await NotificationAvatarBitmap.load(mapped.avatarUrl);

    final payloadSound = _resolvePayloadSound(data);
    final androidRaw =
        payloadSound ?? SoundService.instance.getNotificationAndroidRaw();
    final iosSound = androidRaw != null ? '$androidRaw.wav' : null;

    final androidDetails = mapped.callBack
        ? missedCallAndroidDetails(
            title: title,
            body: body,
            tag: mapped.tag,
            largeIcon: NotificationAvatarBitmap.largeIcon(avatar),
          )
        : AndroidNotificationDetails(
            channelId,
            notificationChannelLabel(channelId),
            channelDescription: notificationChannelDescription(channelId),
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_lgbtfinder',
            color: const Color(0xFFEC4899),
            largeIcon: NotificationAvatarBitmap.largeIcon(avatar),
            showWhen: true,
            groupKey: groupKey,
            tag: mapped.tag,
            setAsGroupSummary: false,
            styleInformation: messageTrayStyle(
              chat: isChat,
              title: title,
              body: body,
              senderKey:
                  mapped.data['sender_id']?.toString() ??
                  mapped.data['user_id']?.toString(),
              avatarPng: avatar?.png,
            ),
            actions: trayActionsFor(type),
            sound: androidRaw != null
                ? RawResourceAndroidNotificationSound(androidRaw)
                : null,
            enableVibration: SoundService.instance.vibrationEnabled,
          );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: groupKey,
      sound: iosSound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use message ID or timestamp as notification ID for uniqueness
    final notificationId =
        mapped.data['message_id']?.hashCode ??
        mapped.data['call_id']?.hashCode ??
        mapped.data['notification_id']?.hashCode ??
        message.messageId?.hashCode ??
        mapped.tag.hashCode;

    final encodedPayload = jsonEncode(mapped.data);
    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: encodedPayload,
    );

    if (mapped.callBack && Platform.isAndroid) {
      await showMissedCallGroupSummary(
        plugin: _localNotifications,
        title: title,
        body: body,
        payload: encodedPayload,
      );
    }

    // Show summary notification for grouped messages (Android)
    if (groupKey != null && !mapped.callBack && Platform.isAndroid) {
      await _showGroupSummaryNotification(
        groupKey: groupKey,
        channelId: channelId,
        title: title,
        body: body,
      );
    }
  }

  /// Android group header for one conversation. Silent so it does not add a second alert.
  Future<void> _showGroupSummaryNotification({
    required String groupKey,
    required String channelId,
    required String title,
    required String body,
  }) async {
    final summary = AndroidNotificationDetails(
      channelId,
      notificationChannelLabel(channelId),
      channelDescription: 'Notifications for LGBTFinder app',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@drawable/ic_stat_lgbtfinder',
      color: const Color(0xFFEC4899),
      groupKey: groupKey,
      setAsGroupSummary: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      styleInformation: InboxStyleInformation(
        [body],
        contentTitle: title,
        summaryText: 'Messages',
      ),
    );
    await _localNotifications.show(
      groupKey.hashCode,
      title,
      body,
      NotificationDetails(android: summary),
      payload: jsonEncode({'type': 'message', 'group': groupKey}),
    );
  }

  /// Handle notification tap
  /// FEATURE ENHANCEMENT (Task 9.1.2): Enhanced with deep linking
  void _handleNotificationTap(RemoteMessage message) {
    final data = NotificationNavigation.normalizePayload(
      Map<String, dynamic>.from(message.data),
    );

    unawaited(_handlePremiumAccessNotification(data));

    final type = data['type']?.toString() ?? '';
    if (_isIncomingCallPayload(data)) {
      _handleIncomingCall(data);
      return;
    }

    try {
      DeepLinkingService().handleDeepLink(data);
      return;
    } catch (e) {
      debugPrint('Deep linking service not available, using fallback: $e');
    }

    _handleNotificationTapFallback(data, type);
  }

  void _handleNotificationTapFallback(Map<String, dynamic> data, String type) {
    final userId = NotificationNavigation.resolvePeerUserId(data);

    switch (type) {
      case 'like':
        _navigateToMatches?.call();
        break;
      case 'match':
        _navigateToMatch?.call();
        break;
      case 'superlike':
      case 'super_like':
        if (userId != null && _navigateToChat != null) {
          _navigateToChat!.call(userId.toString());
        } else {
          _navigateToMatch?.call();
        }
        break;
      case 'message':
      case 'chat':
        if (userId != null && _navigateToChat != null) {
          _navigateToChat!.call(userId.toString());
        }
        break;
      case 'call':
      case 'incoming_call':
      case 'incoming_call_audio':
      case 'incoming_call_video':
        _handleIncomingCall(data);
        break;
      case 'notification':
        _navigateToNotifications?.call();
        break;
      case 'plan_purchased':
      case 'plan_granted':
      case 'plan_upgraded':
      case 'subscription_renewed':
        _navigateToNotifications?.call();
        break;
      default:
        break;
    }
  }

  /// Handle incoming call notification
  void _handleIncomingCall(Map<String, dynamic> data) {
    AppLogger.debug('Incoming call notification received: $data');
    IncomingCallHandler.storePendingCallData(data);
  }

  bool _isIncomingCallPayload(Map<String, dynamic> data) {
    return IncomingCallData.isCallPayload(data);
  }

  /// Handle local notification tap (foreground FCM shown as local notification).
  void _onNotificationTapped(NotificationResponse response) {
    final parsed = NotificationNavigation.parseLocalNotificationPayload(
      response.payload,
    );
    if (parsed != null &&
        response.actionId != null &&
        response.actionId!.isNotEmpty) {
      parsed['action'] = response.actionId;
    }
    if (PendingLaunchRoute.localLaunchCaptured) {
      PendingLaunchRoute.localLaunchCaptured = false;
      if (!PendingLaunchRoute.navigationReady) {
        PendingLaunchRoute.store(parsed);
      }
      return;
    }
    if (PendingLaunchRoute.wasJustConsumed(parsed)) {
      return;
    }
    if (!PendingLaunchRoute.navigationReady) {
      PendingLaunchRoute.store(parsed);
      return;
    }
    if (response.actionId == kNotificationActionCallBack) {
      final payload = NotificationNavigation.parseLocalNotificationPayload(
        response.payload,
      );
      if (payload != null) {
        payload['action'] = kNotificationActionCallBack;
        unawaited(DeepLinkingService().handleDeepLink(payload));
      }
      return;
    }
    if (response.actionId == kNotificationActionReply ||
        response.actionId == kNotificationActionMarkRead) {
      unawaited(NotificationQuickActions.handle(response));
      if (response.actionId == kNotificationActionMarkRead) return;
    }
    if (ActiveCallNotification.isHangupAction(response.actionId) ||
        ActiveCallNotification.isReturnAction(
          response.actionId,
          response.payload,
        )) {
      ActiveCallBridge.dispatch(response.actionId, response.payload);
      return;
    }

    final payload = NotificationNavigation.parseLocalNotificationPayload(
      response.payload,
    );
    if (payload == null) {
      AppLogger.debug('Notification tapped with empty or invalid payload');
      return;
    }

    AppLogger.debug('Local notification tapped: $payload');

    if (_isIncomingCallPayload(payload)) {
      _handleIncomingCall(payload);
      return;
    }

    unawaited(_handlePremiumAccessNotification(payload));

    try {
      DeepLinkingService().handleDeepLink(payload);
    } catch (e) {
      AppLogger.debug('Local notification deep link failed: $e');
      _handleNotificationTapFallback(
        payload,
        payload['type']?.toString() ?? '',
      );
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.debug('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.debug('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.debug('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.debug('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      AppLogger.debug('FCM token deleted');
    } catch (e) {
      AppLogger.debug('Error deleting FCM token: $e');
    }
  }

  String? _resolvePayloadSound(Map<String, dynamic> data) {
    final raw =
        data['sound'] ??
        data['notification_sound'] ??
        data['ios_sound'] ??
        data['android_sound'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return value.replaceAll('.wav', '').replaceAll('.mp3', '');
  }

  Future<void> _playPayloadSound(Map<String, dynamic> data) async {
    final payloadSound = _resolvePayloadSound(data);
    if (payloadSound != null) {
      await SoundService.instance.previewSound(
        payloadSound,
        SoundCategory.notification,
      );
      return;
    }
    await SoundService.instance.playNotificationSound();
  }

  bool _isOpenChatMessage(Map<String, dynamic> data) {
    return ChatFcmSuppress.matchesOpenChat(
      data,
      isActivePeer: ActiveChatPeerBridge.isActivePeer,
      isActiveConversation: ActiveChatPeerBridge.isActiveConversation,
    );
  }

  bool _shouldSuppressMessageAlert(Map<String, dynamic> data) {
    return ChatFcmSuppress.shouldSuppress(
      data,
      isActivePeer: ActiveChatPeerBridge.isActivePeer,
      isActiveConversation: ActiveChatPeerBridge.isActiveConversation,
      isMutedPeer: ConversationMuteBridge.isPeerMuted,
    );
  }

  Future<void> _markSuppressedChatRead(Map<String, dynamic> data) async {
    final senderId = ChatFcmSuppress.senderId(data);
    if (senderId == null || _apiService == null) return;
    try {
      await _apiService!.post<void>(
        ApiEndpoints.chatRead,
        data: {'sender_id': senderId},
      );
    } catch (e) {
      AppLogger.warning(
        'Mark-as-read after FCM suppress failed',
        tag: 'Notifications',
        error: e,
      );
    }
  }

  Future<void> showActiveCall(ActiveCallSession session) async {
    final title = ActiveCallNotification.titleFor(session.peerName);
    const androidDetails = AndroidNotificationDetails(
      ActiveCallNotification.androidChannelId,
      ActiveCallNotification.androidChannelName,
      channelDescription: 'Ongoing call — tap to return',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.call,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          ActiveCallNotification.actionReturn,
          'Return',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          ActiveCallNotification.actionHangup,
          'Hang up',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      categoryIdentifier: ActiveCallNotification.iosCategory,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    try {
      await _localNotifications.show(
        ActiveCallNotification.notificationId,
        title,
        'Tap to return',
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: ActiveCallNotification.encode(
          callId: session.callId,
          location: session.routeLocation,
          peerName: session.peerName,
        ),
      );
    } catch (e) {
      AppLogger.warning('Active call notification failed', error: e);
    }
  }

  Future<void> hideActiveCall() async {
    try {
      await _localNotifications.cancel(ActiveCallNotification.notificationId);
    } catch (e) {
      AppLogger.debug('Active call notification cancel failed: $e');
    }
  }
}
