/// Push Notification Service
/// FEATURE ENHANCEMENT (Task 9.1.2): Enhanced with deep linking and notification grouping
/// Handles Firebase Cloud Messaging (FCM) integration
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../services/api_service.dart';
import 'incoming_call_handler.dart';
import 'deep_linking_service.dart';
import 'notification_navigation.dart';
import '../../features/settings/providers/sound_preferences_provider.dart';
import '../../features/settings/data/models/sound_preferences.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Service for handling push notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  // API service for backend communication
  ApiService? _apiService;

  // Navigation callbacks
  void Function()? _navigateToMatches;
  void Function()? _navigateToMatch;
  void Function(String)? _navigateToChat;
  void Function()? _navigateToNotifications;

  /// Set API service for backend communication
  void setApiService(ApiService apiService) {
    _apiService = apiService;
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
        data: {
          'device_token': token,
          'platform': platform,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        AppLogger.debug('FCM token sent to backend successfully');
      } else {
        AppLogger.debug('Failed to send FCM token to backend: ${response.message}');
      }
    } catch (e) {
      AppLogger.debug('Error sending FCM token to backend: $e');
    }
  }

  /// Initialize push notification service.
  /// Yields between steps so the main thread is never blocked for >1s (avoids ANR).
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await SoundService.instance.initialize();
      await _requestPermission();
      await Future.delayed(Duration.zero); // yield to UI

      await _initializeLocalNotifications();
      await Future.delayed(Duration.zero); // yield to UI

      await _getFCMToken();
      await Future.delayed(Duration.zero); // yield to UI

      _setupMessageHandlers();
      _isInitialized = true;
    } catch (e) {
      AppLogger.debug('Error initializing push notifications: $e');
    }
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
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      AppLogger.debug('User granted provisional notification permission');
    } else {
      AppLogger.debug('User declined or has not accepted notification permission');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      AppLogger.debug('FCM Token: $_fcmToken');
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
      if (_isIncomingCallPayload(message.data)) {
        _handleIncomingCall(message.data);
        return;
      }
      unawaited(_playPayloadSound(message.data));
      _showLocalNotification(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.debug('Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        AppLogger.debug('App opened from terminated state: ${message.messageId}');
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

  /// Show local notification
  /// FEATURE ENHANCEMENT (Task 9.1.2): Added notification grouping
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    if (_isIncomingCallPayload(data)) {
      _handleIncomingCall(data);
      return;
    }

    final type = data['type']?.toString() ?? 'general';

    if (type == 'message' && _isMutedMessageSender(data)) {
      return;
    }
    
    // Group notifications by type (messages from same user, etc.)
    String? groupKey;
    String? groupChannelId;
    
    if (type == 'message') {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        groupKey = 'messages_$userId';
        groupChannelId = 'lgbtfinder_messages';
      }
    } else {
      groupChannelId = 'lgbtfinder_$type';
    }

    final payloadSound = _resolvePayloadSound(data);
    final androidRaw = payloadSound ?? SoundService.instance.getNotificationAndroidRaw();
    final iosSound = androidRaw != null ? '$androidRaw.wav' : null;

    final androidDetails = AndroidNotificationDetails(
      groupChannelId ?? 'lgbtfinder_channel',
      'LGBTFinder Notifications',
      channelDescription: 'Notifications for LGBTFinder app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey,
      setAsGroupSummary: false,
      styleInformation: const BigTextStyleInformation(''),
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
    final notificationId = data['message_id']?.hashCode ?? 
                          data['notification_id']?.hashCode ?? 
                          message.messageId?.hashCode ?? 
                          DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _localNotifications.show(
      notificationId,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );

    // Show summary notification for grouped messages (Android)
    if (groupKey != null && Platform.isAndroid) {
      await _showGroupSummaryNotification(groupKey, type);
    }
  }

  /// Show group summary notification (Android)
  Future<void> _showGroupSummaryNotification(String groupKey, String type) async {
    // This would show a summary like "5 new messages from John"
    // Implementation depends on tracking unread counts
    // For now, we'll skip this as it requires state management
  }

  /// Handle notification tap
  /// FEATURE ENHANCEMENT (Task 9.1.2): Enhanced with deep linking
  void _handleNotificationTap(RemoteMessage message) {
    final data = NotificationNavigation.normalizePayload(
      Map<String, dynamic>.from(message.data),
    );

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
      case 'superlike':
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
    final type = data['type']?.toString() ?? '';
    return type == 'call' ||
        type == 'incoming_call' ||
        type == 'incoming_call_audio' ||
        type == 'incoming_call_video' ||
        type.startsWith('incoming_call') ||
        data.containsKey('call_id') ||
        data.containsKey('callId');
  }

  /// Handle local notification tap (foreground FCM shown as local notification).
  void _onNotificationTapped(NotificationResponse response) {
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
    final raw = data['sound'] ??
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

  bool _isMutedMessageSender(Map<String, dynamic> data) {
    final senderId = int.tryParse(
      data['sender_id']?.toString() ??
          data['user_id']?.toString() ??
          '',
    );
    if (senderId == null || senderId <= 0) return false;
    return ConversationMuteBridge.isPeerMuted?.call(senderId) ?? false;
  }
}

