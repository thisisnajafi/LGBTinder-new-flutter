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
import 'notification_navigation.dart';

String? resolveUrlSchemeRoute(Uri uri) {
  if (uri.scheme != 'lgbtfinder') return null;
  final host = uri.host;
  final pathSegments = uri.pathSegments;
  final peerId = pathSegments.isNotEmpty ? int.tryParse(pathSegments.first) : null;

  switch (host) {
    case 'match':
      return '${AppRoutes.home}/matches';
    case 'superlike':
    case 'message':
      if (peerId != null && peerId > 0) {
        return NotificationNavigation.chatThreadLocation(userId: peerId);
      }
      return host == 'superlike'
          ? '${AppRoutes.home}/discovery'
          : '${AppRoutes.home}/chat-list';
    case 'chat':
      if (peerId != null && peerId > 0) {
        return NotificationNavigation.chatThreadLocation(userId: peerId);
      }
      return '${AppRoutes.home}/chat-list';
    case 'profile':
      if (peerId != null && peerId > 0) {
        return Uri(
          path: AppRoutes.profileDetail,
          queryParameters: {'userId': peerId.toString()},
        ).toString();
      }
      return null;
    case 'call':
      if (peerId != null && peerId > 0) {
        return NotificationNavigation.chatThreadLocation(userId: peerId);
      }
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
  bool _initialized = false;
  final Map<String, DeepLinkHandler> _handlers = {};
  final MarketingAttributionService _marketingAttributionService = MarketingAttributionService();

  /// Initialize once with router (safe to call from [MyApp] build).
  void initialize(GoRouter router) {
    _router = router;
    if (_initialized) return;
    _initialized = true;
    _registerDefaultHandlers();
    Future.microtask(() => _marketingAttributionService.initialize());
  }

  void _navigateFromPayload(Map<String, dynamic> data, {bool usePush = false}) {
    final router = _router;
    if (router == null) return;
    NotificationNavigation.navigateWithRouter(
      router,
      data: data,
      usePush: usePush,
    );
  }

  /// Register default deep link handlers
  void _registerDefaultHandlers() {
    for (final type in [
      'message',
      'chat',
      'match',
      'superlike',
      'superlike_sent',
      'like',
      'call',
      'incoming_call',
      'incoming_call_audio',
      'incoming_call_video',
      'profile',
      'profile_view',
      'notification',
    ]) {
      registerHandler(type, (data) async {
        _navigateFromPayload(data);
      });
    }
  }

  /// Register a custom deep link handler
  void registerHandler(String type, DeepLinkHandler handler) {
    _handlers[type] = handler;
  }

  /// Handle deep link from notification data
  Future<void> handleDeepLink(Map<String, dynamic> data) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized. Call initialize() first.');
      return;
    }

    final payload = NotificationNavigation.normalizePayload(data);
    final type = payload['type']?.toString();
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
      final utmParams = <String, String>{};
      if (payload.containsKey('utm_source')) utmParams['utm_source'] = payload['utm_source'].toString();
      if (payload.containsKey('utm_medium')) utmParams['utm_medium'] = payload['utm_medium'].toString();
      if (payload.containsKey('utm_campaign')) utmParams['utm_campaign'] = payload['utm_campaign'].toString();
      if (payload.containsKey('utm_term')) utmParams['utm_term'] = payload['utm_term'].toString();
      if (payload.containsKey('utm_content')) utmParams['utm_content'] = payload['utm_content'].toString();
      if (payload.containsKey('campaign_id')) utmParams['campaign_id'] = payload['campaign_id'].toString();
      if (payload.containsKey('referral_code')) utmParams['referral_code'] = payload['referral_code'].toString();
      if (payload.containsKey('marketing_source')) {
        utmParams['marketing_source'] = payload['marketing_source'].toString();
      }

      if (utmParams.isNotEmpty) {
        await _marketingAttributionService.storeUtmParameters(utmParams);
        debugPrint('📊 Stored marketing attribution: ${utmParams.keys.join(", ")}');
      }

      debugPrint('🔗 Handling deep link: type=$type, data=$payload');
      await handler(payload);
    } catch (e) {
      debugPrint('❌ Error handling deep link: $e');
    }
  }

  /// Handle URL scheme (lgbtfinder://)
  Future<void> handleUrlScheme(String url) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'lgbtfinder') {
        debugPrint('⚠️ Unsupported URL scheme: ${uri.scheme}');
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
  Future<void> handleUniversalLink(String url) async {
    if (_router == null) {
      debugPrint('⚠️ DeepLinkingService not initialized');
      return;
    }

    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      final utmParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (key.startsWith('utm_') ||
            key == 'campaign_id' ||
            key == 'referral_code' ||
            key == 'marketing_source') {
          utmParams[key] = value;
        }
      });

      if (utmParams.isNotEmpty) {
        await _marketingAttributionService.storeUtmParameters(utmParams);
        debugPrint(
          '📊 Stored marketing attribution from universal link: ${utmParams.keys.join(", ")}',
        );
      }

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
    final segment = userId ?? matchId ?? chatId ?? callId;
    final uri = Uri(
      scheme: 'lgbtfinder',
      host: type,
      pathSegments: segment != null ? [segment] : const [],
    );
    return uri.toString();
  }
}

/// Deep link handler function type
typedef DeepLinkHandler = Future<void> Function(Map<String, dynamic> data);
