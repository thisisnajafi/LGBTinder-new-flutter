// FEATURE ENHANCEMENT (Task 9.1.2): Deep Linking Service
//
// Handles deep linking from push notifications and URLs
// - Navigate to specific screens based on notification type
// - Handle URL schemes (lgbtfinder://)
// - Support universal links (iOS) and app links (Android)
// - Capture UTM parameters for marketing attribution

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/payments/data/services/marketing_attribution_service.dart';
import '../../routes/app_router.dart';

String? resolveUrlSchemeRoute(Uri uri) {
  if (uri.scheme != 'lgbtfinder') return null;
  final host = uri.host;
  final pathSegments = uri.pathSegments;

  switch (host) {
    case 'match':
      return '${AppRoutes.home}/matches';
    case 'chat':
      if (pathSegments.isNotEmpty) {
        return Uri(
          path: AppRoutes.chat,
          queryParameters: {'userId': pathSegments.first},
        ).toString();
      }
      return AppRoutes.chat;
    case 'profile':
      if (pathSegments.isNotEmpty) {
        return Uri(
          path: AppRoutes.profileDetail,
          queryParameters: {'userId': pathSegments.first},
        ).toString();
      }
      return null;
    case 'call':
      return AppRoutes.chat;
    case 'notifications':
      return '${AppRoutes.home}/notifications';
    case 'discover':
      return '${AppRoutes.home}/discovery';
    default:
      return null;
  }
}

/// Deep linking service for navigation from notifications and URLs
class DeepLinkingService {
  static final DeepLinkingService _instance = DeepLinkingService._internal();
  factory DeepLinkingService() => _instance;
  DeepLinkingService._internal();

  GoRouter? _router;
  final Map<String, DeepLinkHandler> _handlers = {};
  final MarketingAttributionService _marketingAttributionService = MarketingAttributionService();

  /// Initialize with router
  void initialize(GoRouter router) async {
    _router = router;
    await _marketingAttributionService.initialize();
    _registerDefaultHandlers();
  }

  /// Register default deep link handlers
  void _registerDefaultHandlers() {
    // Match notification → Navigate to matches screen
    registerHandler('match', (data) async {
      _router?.go('${AppRoutes.home}/matches');
    });

    // Like notification → Navigate to likes screen (if premium)
    registerHandler('like', (data) async {
      _router?.go('${AppRoutes.home}/discovery');
    });

    // Message notification → Navigate to specific chat
    registerHandler('message', (data) async {
      final userId = data['user_id']?.toString();
      final chatId = data['chat_id']?.toString();
      if (userId != null) {
        final target = Uri(
          path: AppRoutes.chat,
          queryParameters: {'userId': userId},
        ).toString();
        _router?.go(target);
      } else if (chatId != null) {
        final target = Uri(
          path: AppRoutes.chat,
          queryParameters: {'userId': chatId},
        ).toString();
        _router?.go(target);
      } else {
        _router?.go(AppRoutes.chat);
      }
    });

    // Call notification → Navigate to call screen
    registerHandler('call', (data) async {
      _router?.go(AppRoutes.chat);
    });

    // General notification → Navigate to notifications screen
    registerHandler('notification', (data) async {
      _router?.go('/home/notifications');
    });

    // Profile view → Navigate to user profile
    registerHandler('profile', (data) async {
      final userId = data['user_id']?.toString();
      if (userId != null) {
        final target = Uri(
          path: AppRoutes.profileDetail,
          queryParameters: {'userId': userId},
        ).toString();
        _router?.go(target);
      }
    });

    // Superlike notification → Navigate to discovery
    registerHandler('superlike', (data) async {
      _router?.go('${AppRoutes.home}/discovery');
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
  ///   "utm_source": "email",
  ///   "utm_campaign": "promo",
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
      // Extract and store UTM parameters for marketing attribution
      final utmParams = <String, String>{};
      if (data.containsKey('utm_source')) utmParams['utm_source'] = data['utm_source'].toString();
      if (data.containsKey('utm_medium')) utmParams['utm_medium'] = data['utm_medium'].toString();
      if (data.containsKey('utm_campaign')) utmParams['utm_campaign'] = data['utm_campaign'].toString();
      if (data.containsKey('utm_term')) utmParams['utm_term'] = data['utm_term'].toString();
      if (data.containsKey('utm_content')) utmParams['utm_content'] = data['utm_content'].toString();
      if (data.containsKey('campaign_id')) utmParams['campaign_id'] = data['campaign_id'].toString();
      if (data.containsKey('referral_code')) utmParams['referral_code'] = data['referral_code'].toString();
      if (data.containsKey('marketing_source')) utmParams['marketing_source'] = data['marketing_source'].toString();

      if (utmParams.isNotEmpty) {
        await _marketingAttributionService.storeUtmParameters(utmParams);
        debugPrint('📊 Stored marketing attribution: ${utmParams.keys.join(", ")}');
      }

      debugPrint('🔗 Handling deep link: type=$type, data=$data');
      await handler(data);
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
    }
  }

  /// Handle URL scheme (lgbtfinder://)
  /// 
  /// Supported formats:
  /// - lgbtfinder://match/123
  /// - lgbtfinder://chat/456
  /// - lgbtfinder://profile/789
  /// - lgbtfinder://call/101
  Future<void> handleUrlScheme(String url) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme;
      if (scheme != 'lgbtfinder') {
        debugPrint('⚠️ Unsupported URL scheme: $scheme');
        return;
      }

      debugPrint('🔗 Handling URL scheme: $url');
      final route = resolveUrlSchemeRoute(uri);
      if (route == null) {
        debugPrint('⚠️ Unknown deep link host: ${uri.host}');
        return;
      }
      _router?.go(route);
    } catch (e) {
      debugPrint('❌ Error parsing URL scheme: $e');
    }
  }

  /// Handle universal link (iOS) or app link (Android)
  /// 
  /// Format: https://lgbtfinder.com/deep-link?type=message&user_id=123
  Future<void> handleUniversalLink(String url) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      // Extract and store UTM parameters for marketing attribution
      final utmParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (key.startsWith('utm_') || key == 'campaign_id' || key == 'referral_code' || key == 'marketing_source') {
          utmParams[key] = value;
        }
      });

      if (utmParams.isNotEmpty) {
        await _marketingAttributionService.storeUtmParameters(utmParams);
        debugPrint('📊 Stored marketing attribution from universal link: ${utmParams.keys.join(", ")}');
      }

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
      scheme: 'lgbtfinder',
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

