// Screen: HomePage
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../pages/discovery_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/profile_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../core/utils/app_logger.dart';
import '../routes/home_tab_routes.dart';

/// Home page — main shell with tap-only tabs and bottom navigation.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController;
  int _lastRouteTab = 0;
  bool _pageChangeFromRoute = false;

  @override
  void initState() {
    super.initState();
    screenLog('HomePage', 'initState');
    startupLog('HomePage: reached HOME');
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialTab = HomeTabRoutes.tabIndexFromGoState(GoRouterState.of(context));
      _lastRouteTab = initialTab;
      if (_pageController.hasClients && initialTab != 0) {
        _pageController.jumpToPage(initialTab);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    final bounded = index.clamp(0, HomeTabRoutes.tabCount - 1);
    if (_pageController.hasClients) {
      _pageChangeFromRoute = true;
      _pageController.jumpToPage(bounded);
      _pageChangeFromRoute = false;
    }
    _lastRouteTab = bounded;
    final target = HomeTabRoutes.locationForTab(bounded);
    if (GoRouterState.of(context).uri.toString() != target) {
      context.go(target);
    }
  }

  void _onPageChanged(int index) {
    if (_pageChangeFromRoute) return;
    _lastRouteTab = index;
    final target = HomeTabRoutes.locationForTab(index);
    if (GoRouterState.of(context).uri.toString() != target) {
      context.go(target);
    }
  }

  void _syncPageControllerToRoute(int tabIndex) {
    if (_lastRouteTab == tabIndex &&
        (_pageController.hasClients ? _pageController.page?.round() == tabIndex : true)) {
      return;
    }
    _lastRouteTab = tabIndex;

    void jumpToTab() {
      if (!_pageController.hasClients) return;
      final current = _pageController.page?.round() ?? tabIndex;
      if (current == tabIndex) return;
      _pageChangeFromRoute = true;
      _pageController.jumpToPage(tabIndex);
      _pageChangeFromRoute = false;
    }

    if (_pageController.hasClients) {
      jumpToTab();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) jumpToTab();
      });
    }
  }

  int? _profileUserIdFromRoute(GoRouterState state) {
    final raw = state.uri.queryParameters['userId'];
    if (raw == null || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  List<Widget> _buildPages(int selectedTabIndex, int? profileUserId) => [
        DiscoveryPage(
          selectedTabIndex: selectedTabIndex,
          discoveryTabIndex: 0,
        ),
        const ChatListPage(),
        const NotificationsScreen(),
        ProfilePage(userId: profileUserId),
        const SettingsPage(),
      ];

  @override
  Widget build(BuildContext context) {
    screenLog('HomePage', 'build');
    final theme = Theme.of(context);
    final routerState = GoRouterState.of(context);
    final currentIndex = HomeTabRoutes.tabIndexFromGoState(routerState);
    final profileUserId = _profileUserIdFromRoute(routerState);

    if (currentIndex != _lastRouteTab ||
        (_pageController.hasClients && _pageController.page?.round() != currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPageControllerToRoute(currentIndex);
      });
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBarReserve = AppBottomNavBar.bottomReserve(bottomInset);

    final pages = _buildPages(currentIndex, profileUserId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: navBarReserve),
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _KeepAliveTab(key: const ValueKey('tab_discovery'), child: pages[0]),
                _KeepAliveTab(key: const ValueKey('tab_chat'), child: pages[1]),
                _KeepAliveTab(key: const ValueKey('tab_notifications'), child: pages[2]),
                _KeepAliveTab(key: const ValueKey('tab_profile'), child: pages[3]),
                _KeepAliveTab(key: const ValueKey('tab_settings'), child: pages[4]),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              currentIndex: currentIndex,
              onTap: _onTabTapped,
              notificationCount: ref.watch(unreadNotificationCountProvider).when(
                    data: (count) => count,
                    loading: () => null,
                    error: (_, __) => null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps off-screen tab state when switching main sections.
class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({super.key, required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
