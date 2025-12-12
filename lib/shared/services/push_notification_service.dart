/// Push Notification Service
/// FEATURE ENHANCEMENT (Task 9.1.2): Enhanced with deep linking and notification grouping
/// Handles Firebase Cloud Messaging (FCM) integration
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../services/api_service.dart';
import 'incoming_call_handler.dart';
import 'deep_linking_service.dart';

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
      print('API service not set, cannot send token to backend');
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
        print('FCM token sent to backend successfully');
      } else {
        print('Failed to send FCM token to backend: ${response.message}');
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing push notifications: $e');
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
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined or has not accepted notification permission');
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
      print('FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Handle notification tap when app is terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      print('FCM Token refreshed: $newToken');
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
    final type = data['type']?.toString() ?? 'general';
    
    // Group notifications by type (messages from same user, etc.)
    String? groupKey;
    String? groupChannelId;
    
    if (type == 'message') {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        groupKey = 'messages_$userId';
        groupChannelId = 'lgbtinder_messages';
      }
    } else {
      groupChannelId = 'lgbtinder_$type';
    }

    final androidDetails = AndroidNotificationDetails(
      groupChannelId ?? 'lgbtinder_channel',
      'LGBTinder Notifications',
      channelDescription: 'Notifications for LGBTinder app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      groupKey: groupKey, // Group messages from same user
      setAsGroupSummary: false, // Don't show summary for individual messages
      styleInformation: const BigTextStyleInformation(''), // Expandable notification
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: groupKey, // iOS notification grouping
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
      payload: message.data.toString(),
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
    final data = message.data;
    
    // Use deep linking service if available
    try {
      final deepLinkingService = DeepLinkingService();
      deepLinkingService.handleDeepLink(data);
      return;
    } catch (e) {
      debugPrint('Deep linking service not available, using fallback: $e');
    }
    
    // Fallback to callback-based navigation
    if (data.containsKey('type')) {
      final type = data['type'] as String;
      
      switch (type) {
        case 'like':
          _navigateToMatches?.call();
          break;
        case 'match':
          _navigateToMatch?.call();
          break;
        case 'message':
          final userId = data['user_id'];
          if (userId != null && _navigateToChat != null) {
            _navigateToChat?.call(userId);
          }
          break;
        case 'call':
          // Handle incoming call notification
          _handleIncomingCall(data);
          break;
        case 'notification':
          _navigateToNotifications?.call();
          break;
        default:
          break;
      }
    }
  }

  /// Handle incoming call notification
  void _handleIncomingCall(Map<String, dynamic> data) {
    print('Incoming call notification received: $data');

    // Note: This method is called from notification handlers where we may not have context.
    // The actual handling should be done in the main app where context is available.
    // For now, we'll store the data and handle it when the app is in foreground.
    IncomingCallHandler.storePendingCallData(data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload and navigate
      print('Notification tapped: ${response.payload}');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background message here
}

