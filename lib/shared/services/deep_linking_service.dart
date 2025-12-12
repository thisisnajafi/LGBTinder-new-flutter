// FEATURE ENHANCEMENT (Task 9.1.2): Deep Linking Service
//
// Handles deep linking from push notifications and URLs
// - Navigate to specific screens based on notification type
// - Handle URL schemes (lgbtinder://)
// - Support universal links (iOS) and app links (Android)

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Deep linking service for navigation from notifications and URLs
class DeepLinkingService {
  static final DeepLinkingService _instance = DeepLinkingService._internal();
  factory DeepLinkingService() => _instance;
  DeepLinkingService._internal();

  GoRouter? _router;
  final Map<String, DeepLinkHandler> _handlers = {};

  /// Initialize with router
  void initialize(GoRouter router) {
    _router = router;
    _registerDefaultHandlers();
  }

  /// Register default deep link handlers
  void _registerDefaultHandlers() {
    // Match notification → Navigate to matches screen
    registerHandler('match', (data) {
      final matchId = data['match_id']?.toString();
      if (matchId != null) {
        _router?.go('/matches/$matchId');
      } else {
        _router?.go('/matches');
      }
    });

    // Like notification → Navigate to likes screen (if premium)
    registerHandler('like', (data) {
      _router?.go('/likes');
    });

    // Message notification → Navigate to specific chat
    registerHandler('message', (data) {
      final userId = data['user_id']?.toString();
      final chatId = data['chat_id']?.toString();
      if (userId != null) {
        _router?.go('/chat/$userId');
      } else if (chatId != null) {
        _router?.go('/chat/$chatId');
      } else {
        _router?.go('/chats');
      }
    });

    // Call notification → Navigate to call screen
    registerHandler('call', (data) {
      final callId = data['call_id']?.toString();
      if (callId != null) {
        _router?.go('/call/$callId');
      }
    });

    // General notification → Navigate to notifications screen
    registerHandler('notification', (data) {
      _router?.go('/notifications');
    });

    // Profile view → Navigate to user profile
    registerHandler('profile', (data) {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        _router?.go('/profile/$userId');
      }
    });

    // Superlike notification → Navigate to discovery
    registerHandler('superlike', (data) {
      _router?.go('/discover');
    });
  }

  /// Register a custom deep link handler
  void registerHandler(String type, DeepLinkHandler handler) {
    _handlers[type] = handler;
  }

  /// Handle deep link from notification data
  /// 
  /// Expected data format:
  /// ```json
  /// {
  ///   "type": "message|match|like|call|notification",
  ///   "user_id": "123",
  ///   "match_id": "456",
  ///   "chat_id": "789",
  ///   "call_id": "101",
  ///   ...
  /// }
  /// ```
  Future<void> handleDeepLink(Map<String, dynamic> data) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized. Call initialize() first.');
      return;
    }

    final type = data['type']?.toString();
    if (type == null) {
      debugPrint('⚠️ Deep link data missing "type" field');
      return;
    }

    final handler = _handlers[type];
    if (handler == null) {
      debugPrint('⚠️ No handler registered for type: $type');
      return;
    }

    try {
      debugPrint('🔗 Handling deep link: type=$type, data=$data');
      await handler(data);
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
    }
  }

  /// Handle URL scheme (lgbtinder://)
  /// 
  /// Supported formats:
  /// - lgbtinder://match/123
  /// - lgbtinder://chat/456
  /// - lgbtinder://profile/789
  /// - lgbtinder://call/101
  Future<void> handleUrlScheme(String url) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme;
      final host = uri.host;
      final pathSegments = uri.pathSegments;

      if (scheme != 'lgbtinder') {
        debugPrint('⚠️ Unsupported URL scheme: $scheme');
        return;
      }

      debugPrint('🔗 Handling URL scheme: $url');

      // Convert URL to route
      switch (host) {
        case 'match':
          if (pathSegments.isNotEmpty) {
            _router?.go('/matches/${pathSegments.first}');
          } else {
            _router?.go('/matches');
          }
          break;
        case 'chat':
          if (pathSegments.isNotEmpty) {
            _router?.go('/chat/${pathSegments.first}');
          } else {
            _router?.go('/chats');
          }
          break;
        case 'profile':
          if (pathSegments.isNotEmpty) {
            _router?.go('/profile/${pathSegments.first}');
          }
          break;
        case 'call':
          if (pathSegments.isNotEmpty) {
            _router?.go('/call/${pathSegments.first}');
          }
          break;
        case 'notifications':
          _router?.go('/notifications');
          break;
        case 'discover':
          _router?.go('/discover');
          break;
        default:
          debugPrint('⚠️ Unknown deep link host: $host');
      }
    } catch (e) {
      debugPrint('❌ Error parsing URL scheme: $e');
    }
  }

  /// Handle universal link (iOS) or app link (Android)
  /// 
  /// Format: https://lgbtinder.com/deep-link?type=message&user_id=123
  Future<void> handleUniversalLink(String url) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      // Extract type and data from query parameters
      final data = Map<String, dynamic>.from(queryParams);
      
      await handleDeepLink(data);
    } catch (e) {
      debugPrint('❌ Error parsing universal link: $e');
    }
  }

  /// Build deep link URL for sharing
  String buildDeepLinkUrl({
    required String type,
    String? userId,
    String? matchId,
    String? chatId,
    String? callId,
  }) {
    final uri = Uri(
      scheme: 'lgbtinder',
      host: type,
      pathSegments: [
        if (userId != null) userId,
        if (matchId != null) matchId,
        if (chatId != null) chatId,
        if (callId != null) callId,
      ].where((s) => s.isNotEmpty).toList(),
    );
    return uri.toString();
  }
}

/// Deep link handler function type
typedef DeepLinkHandler = Future<void> Function(Map<String, dynamic> data);

