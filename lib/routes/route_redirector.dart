import 'app_router.dart';

/// Router redirect helper:
/// - normalizes legacy/old deep links into valid `GoRouter` locations
/// - stores a pending protected destination for post-login resume
class RouteRedirector {
  String? _pendingProtectedRoute;

  /// App routes under `/profile/...` that must not be treated as `/profile/:userId`.
  static const Set<String> _reservedProfileSegments = {
    'edit',
    'verification',
    'views',
    'completion-status',
    'search',
    'update',
    'badge',
    'change-email',
    'verify-email-change',
  };

  String? get pendingProtectedRoute => _pendingProtectedRoute;

  void setPendingIfEmpty(String location) {
    _pendingProtectedRoute ??= location;
  }

  String? consumePending() {
    final v = _pendingProtectedRoute;
    _pendingProtectedRoute = null;
    return v;
  }

  /// Returns a corrected location for legacy routes, or null if not a legacy path.
  String? resolveLegacyRoute(Uri uri) {
    final path = uri.path;

    if (path == '/help') return AppRoutes.helpSupport;
    if (path == '/discover') return '${AppRoutes.home}/discovery';
    if (path == '/likes') return '${AppRoutes.home}/matches';
    if (path == '/chats') return AppRoutes.chat;
    if (path == '/plans' || path == '/subscription') return AppRoutes.subscriptionPlans;
    if (path == '/badges' || path == '/promotions' || path == '/daily-rewards') {
      return AppRoutes.home;
    }
    if (path == '/matches') return '${AppRoutes.home}/matches';

    if (path.startsWith('/profile/')) {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments.first == 'profile') {
        final slug = segments[1];
        if (_reservedProfileSegments.contains(slug)) {
          return null;
        }
        if (RegExp(r'^\d+$').hasMatch(slug)) {
          return Uri(
            path: AppRoutes.profileDetail,
            queryParameters: {'userId': slug},
          ).toString();
        }
      }
    }

    if (path.startsWith('/chat/')) {
      final userId = path.split('/').last;
      if (userId.isNotEmpty) {
        return Uri(path: AppRoutes.chat, queryParameters: {'userId': userId}).toString();
      }
    }

    if (path.startsWith('/matches/')) {
      return '${AppRoutes.home}/matches';
    }

    if (path.startsWith('/call/')) {
      return AppRoutes.chat;
    }

    return null;
  }
}

