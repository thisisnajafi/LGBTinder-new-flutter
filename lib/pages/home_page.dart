// Screen: HomePage
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/animation_constants.dart';
import '../core/widgets/app_bottom_nav_bar.dart';
import '../pages/discovery_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/profile_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../features/chat/providers/chat_list_preview_provider.dart';
import '../core/utils/app_logger.dart';
import '../core/location/location_providers.dart';
import '../core/widgets/connectivity_banner.dart';
import '../core/providers/api_providers.dart';
import '../routes/home_tab_routes.dart';

/// Home page — main shell with animated tabs and root back-navigation.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController;
  int _lastRouteTab = 0;
  bool _pageChangeFromRoute = false;
  DateTime? _lastExitBackPressAt;

  static const Duration _exitConfirmWindow = Duration(seconds: 2);

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
      runStaleLocationBootstrap(ref);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _navigateToTab(index, animate: true);
  }

  void _onPageChanged(int index) {
    if (_pageChangeFromRoute) return;
    _lastRouteTab = index;
    final target = HomeTabRoutes.locationForTab(index);
    if (GoRouterState.of(context).uri.toString() != target) {
      context.go(target);
    }
  }

  /// Animates between tabs in bottom-nav order (direction-aware slide).
  void _navigateToTab(int index, {required bool animate}) {
    final bounded = index.clamp(0, HomeTabRoutes.tabCount - 1);
    final currentPage = _pageController.hasClients
        ? _pageController.page?.round() ?? _lastRouteTab
        : _lastRouteTab;

    if (bounded != 0) {
      _lastExitBackPressAt = null;
    }

    final target = HomeTabRoutes.locationForTab(bounded);
    if (GoRouterState.of(context).uri.toString() != target) {
      context.go(target);
    }

    if (bounded == currentPage) {
      _lastRouteTab = bounded;
      return;
    }

    _lastRouteTab = bounded;
    _pageChangeFromRoute = true;

    if (!_pageController.hasClients) {
      _pageChangeFromRoute = false;
      return;
    }

    final shouldAnimate =
        animate && AppAnimations.animationsEnabled(context);

    if (shouldAnimate) {
      _pageController
          .animateToPage(
            bounded,
            duration: AppAnimations.transitionTab,
            curve: AppAnimations.curveDefault,
          )
          .whenComplete(() {
        if (mounted) _pageChangeFromRoute = false;
      });
    } else {
      _pageController.jumpToPage(bounded);
      _pageChangeFromRoute = false;
    }
  }

  void _syncPageControllerToRoute(int tabIndex) {
    if (_lastRouteTab == tabIndex &&
        (_pageController.hasClients
            ? _pageController.page?.round() == tabIndex
            : true)) {
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

  void _handleSystemBack(int currentIndex, double navBarReserve) {
    if (currentIndex != 0) {
      _navigateToTab(0, animate: true);
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
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Press back again to exit'),
        duration: _exitConfirmWindow,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, navBarReserve + 8),
      ),
    );
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
        ChatListPage(
          selectedTabIndex: selectedTabIndex,
          messengerTabIndex: 1,
        ),
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
        (_pageController.hasClients &&
            _pageController.page?.round() != currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncPageControllerToRoute(currentIndex);
      });
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBarReserve = AppBottomNavBar.bottomReserve(bottomInset);

    ref.watch(connectivityServiceBindingProvider);

    final pages = _buildPages(currentIndex, profileUserId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleSystemBack(currentIndex, navBarReserve);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ConnectivityBanner(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: navBarReserve),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _KeepAliveTab(
                      key: const ValueKey('tab_discovery'),
                      child: pages[0],
                    ),
                    _KeepAliveTab(
                      key: const ValueKey('tab_chat'),
                      child: pages[1],
                    ),
                    _KeepAliveTab(
                      key: const ValueKey('tab_notifications'),
                      child: pages[2],
                    ),
                    _KeepAliveTab(
                      key: const ValueKey('tab_profile'),
                      child: pages[3],
                    ),
                    _KeepAliveTab(
                      key: const ValueKey('tab_settings'),
                      child: pages[4],
                    ),
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
                  messengerUnreadCount: ref.watch(unreadChatCountProvider),
                  notificationCount: ref.watch(unreadNotificationCountProvider).when(
                        data: (count) => count,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                ),
              ),
            ],
          ),
        ),
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
