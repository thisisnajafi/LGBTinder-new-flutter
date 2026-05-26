import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Main shell tab indices and URL helpers for [HomePage].
class HomeTabRoutes {
  HomeTabRoutes._();

  static const int tabCount = 5;

  static const List<String> legacyPaths = [
    '${AppRoutes.home}/discovery',
    '${AppRoutes.home}/chat-list',
    '${AppRoutes.home}/notifications',
    '${AppRoutes.home}/profile',
    '${AppRoutes.home}/settings',
  ];

  /// Canonical location for a tab (keeps bottom nav shell on `/home`).
  static String locationForTab(int index) {
    final tab = index.clamp(0, tabCount - 1);
    return tab == 0 ? AppRoutes.home : '${AppRoutes.home}?tab=$tab';
  }

  static int tabIndexFromMatchedLocation(String location) {
    final uri = Uri.parse(location.startsWith('/') ? location : '/$location');
    return tabIndexFromUri(uri, matchedPath: uri.path);
  }

  static int tabIndexFromGoState(GoRouterState state) {
    return tabIndexFromUri(state.uri, matchedPath: state.matchedLocation);
  }

  static int tabIndexFromUri(Uri uri, {required String matchedPath}) {
    final tabParam = int.tryParse(uri.queryParameters['tab'] ?? '');
    if (tabParam != null && tabParam >= 0 && tabParam < tabCount) {
      return tabParam;
    }

    final path = matchedPath;
    if (path.startsWith('${AppRoutes.home}/chat-list')) return 1;
    if (path.startsWith('${AppRoutes.home}/notifications')) return 2;
    if (path.startsWith('${AppRoutes.home}/profile')) return 3;
    if (path.startsWith('${AppRoutes.home}/settings')) return 4;
    return 0;
  }

  /// Redirect target for legacy `/home/<tab>` deep links.
  static String? redirectLegacyChild(String matchedPath) {
    for (var i = 0; i < legacyPaths.length; i++) {
      if (matchedPath == legacyPaths[i] || matchedPath.startsWith('${legacyPaths[i]}/')) {
        return locationForTab(i);
      }
    }
    return null;
  }
}
