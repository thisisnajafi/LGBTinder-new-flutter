// Screen: HomePage
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive/responsive.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../pages/discovery_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/profile_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/matching/data/models/match.dart' as match_models;
import '../features/matching/widgets/match_celebration_launcher.dart';
import '../features/chat/providers/chat_pusher_providers.dart';
import '../shared/services/pusher_websocket_service.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../core/utils/app_logger.dart';
import '../core/location/location_providers.dart';
import '../core/widgets/connectivity_banner.dart';
import '../core/providers/api_providers.dart';
import '../routes/home_tab_routes.dart';

/// Notifications + Settings unmount after this idle window (PERF-PAGE-HOME-004).
@visibleForTesting
const Duration homeIdleTabDisposeAfter = Duration(minutes: 5);

@visibleForTesting
const Set<int> homeIdleDisposableTabs = {2, 4};

/// Drops idle Settings/Notifications tabs while keeping the current one.
@visibleForTesting
Set<int> homeTabsAfterIdleDispose({
  required Iterable<int> mounted,
  required int currentIndex,
}) {
  return {
    for (final tab in mounted)
      if (tab == currentIndex || !homeIdleDisposableTabs.contains(tab)) tab,
  };
}

/// Home page — main shell with lazy tabs and root back-navigation.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<int> _mountedTabs = {};
  int _lastRouteTab = 0;
  DateTime? _lastExitBackPressAt;
  StreamSubscription<MatchEvent>? _matchSub;
  Timer? _idleDisposeTimer;

  static const Duration _exitConfirmWindow = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    screenLog('HomePage', 'initState');
    startupLog('HomePage: reached HOME');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialTab = HomeTabRoutes.tabIndexFromGoState(GoRouterState.of(context));
      _lastRouteTab = initialTab;
      _mountedTabs.add(initialTab);
      if (initialTab != 0) setState(() {});
      runStaleLocationBootstrap(ref);
      _matchSub = ref
          .read(pusherWebSocketServiceProvider)
          .matchStream
          .listen(_onRemoteMatch);
    });
  }

  @override
  void dispose() {
    _idleDisposeTimer?.cancel();
    _matchSub?.cancel();
    super.dispose();
  }

  void _onRemoteMatch(MatchEvent event) {
    if (!mounted) return;
    if (MatchCelebrationDedupe.wasRecentlyShown(event.matchId, event.userId)) {
      return;
    }
    if ((event.userId ?? 0) <= 0) return;
    MatchCelebrationDedupe.mark(event.matchId, event.userId);
    final match = match_models.Match(
      id: event.matchId ?? 0,
      userId: event.userId ?? 0,
      firstName: (event.firstName != null && event.firstName!.isNotEmpty)
          ? event.firstName!
          : 'Someone',
      lastName: event.lastName,
      primaryImageUrl: event.avatarUrl,
      matchedAt: event.timestamp,
    );
    unawaited(
      MatchCelebrationLauncher.show(
        context,
        ref,
        match: match,
        matchedAvatarUrl: event.avatarUrl,
      ),
    );
  }

  void _onTabTapped(int index) {
    _navigateToTab(index);
  }

  void _navigateToTab(int index) {
    final bounded = index.clamp(0, HomeTabRoutes.tabCount - 1);
    if (bounded != 0) {
      _lastExitBackPressAt = null;
    }

    _lastRouteTab = bounded;
    final added = _mountedTabs.add(bounded);
    if (added) setState(() {});
    _scheduleIdleDispose(bounded);

    final target = HomeTabRoutes.locationForTab(bounded);
    if (GoRouterState.of(context).uri.toString() != target) {
      context.go(target);
    }
  }

  void _scheduleIdleDispose(int currentIndex) {
    _idleDisposeTimer?.cancel();
    _idleDisposeTimer = Timer(homeIdleTabDisposeAfter, () {
      if (!mounted) return;
      final next = homeTabsAfterIdleDispose(
        mounted: _mountedTabs,
        currentIndex: currentIndex,
      );
      if (next.length == _mountedTabs.length &&
          next.containsAll(_mountedTabs)) {
        return;
      }
      setState(() {
        _mountedTabs
          ..clear()
          ..addAll(next);
      });
    });
  }

  void _handleSystemBack(int currentIndex, double navBarReserve) {
    if (currentIndex != 0) {
      _navigateToTab(0);
      return;
    }

    final now = DateTime.now();
    if (_lastExitBackPressAt != null &&
        now.difference(_lastExitBackPressAt!) < _exitConfirmWindow) {
      SystemNavigator.pop();
      return;
    }

    _lastExitBackPressAt = now;
    final messenger = ScaffoldMessenger.of(context);
    final horizontal = ResponsivePadding.horizontal(context).horizontal;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const AppText(
          'Press back again to exit',
          maxLines: 1,
        ),
        duration: _exitConfirmWindow,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(horizontal, 0, horizontal, navBarReserve + 8),
      ),
    );
  }

  int? _profileUserIdFromRoute(GoRouterState state) {
    final raw = state.uri.queryParameters['userId'];
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  Widget _tabPage(int index, int selectedTabIndex, int? profileUserId) {
    switch (index) {
      case 0:
        return DiscoveryPage(
          selectedTabIndex: selectedTabIndex,
          discoveryTabIndex: 0,
        );
      case 1:
        return ChatListPage(
          selectedTabIndex: selectedTabIndex,
          messengerTabIndex: 1,
        );
      case 2:
        return NotificationsScreen(
          selectedTabIndex: selectedTabIndex,
          notificationsTabIndex: 2,
        );
      case 3:
        return ProfilePage(userId: profileUserId);
      default:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    screenLog('HomePage', 'build');
    final theme = Theme.of(context);
    final routerState = GoRouterState.of(context);
    final currentIndex = HomeTabRoutes.tabIndexFromGoState(routerState);
    final profileUserId = _profileUserIdFromRoute(routerState);

    _mountedTabs.add(currentIndex);
    if (_lastRouteTab != currentIndex) {
      _lastRouteTab = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleIdleDispose(currentIndex);
      });
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBarReserve = AppBottomNavBar.bottomReserve(bottomInset);

    ref.watch(connectivityServiceBindingProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleSystemBack(currentIndex, navBarReserve);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: currentIndex != 1,
        body: ConnectivityBanner(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: navBarReserve),
                child: RepaintBoundary(
                  child: IndexedStack(
                    index: currentIndex,
                    sizing: StackFit.expand,
                    children: [
                      for (var i = 0; i < HomeTabRoutes.tabCount; i++)
                        KeyedSubtree(
                          key: ValueKey('tab_$i'),
                          child: _mountedTabs.contains(i)
                              ? _tabPage(i, currentIndex, profileUserId)
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _HomeBottomNavHost(
                  currentIndex: currentIndex,
                  onTap: _onTabTapped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isolated badge watches so chat/notification counts do not rebuild tab bodies
/// (PERF-PAGE-HOME-002 / 005).
class _HomeBottomNavHost extends ConsumerWidget {
  const _HomeBottomNavHost({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messengerUnread = ref.watch(unreadChatCountProvider);
    final notificationCount = ref.watch(
      unreadNotificationCountProvider.select((async) => async.asData?.value),
    );

    return RepaintBoundary(
      child: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        messengerUnreadCount: messengerUnread,
        notificationCount: notificationCount,
      ),
    );
  }
}
