// Screen: HomePage
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../widgets/navbar/bottom_navbar.dart';
import '../widgets/ui/greeting_header.dart';
import '../pages/discovery_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/profile_page.dart';
import '../screens/settings_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/providers/notification_providers.dart';
import '../core/utils/app_logger.dart';
import '../routes/app_router.dart';

/// Home page - Main navigation hub with bottom navigation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const List<String> _tabLocations = [
    '${AppRoutes.home}/discovery',
    '${AppRoutes.home}/chat-list',
    '${AppRoutes.home}/notifications',
    '${AppRoutes.home}/profile',
    '${AppRoutes.home}/settings',
  ];

  List<Widget> _buildPages(int selectedTabIndex) => [
    DiscoveryPage(selectedTabIndex: selectedTabIndex, discoveryTabIndex: 0),
    const ChatListPage(),
    const NotificationsScreen(),
    const ProfilePage(),
    const SettingsScreen(),
  ];

  int _locationToTabIndex(String location) {
    if (location.startsWith('${AppRoutes.home}/chat-list')) return 1;
    if (location.startsWith('${AppRoutes.home}/notifications')) return 2;
    if (location.startsWith('${AppRoutes.home}/profile')) return 3;
    if (location.startsWith('${AppRoutes.home}/settings')) return 4;
    // `/home` and unknown home children default to discovery tab.
    return 0;
  }

  void _onTabTapped(int index) {
    final bounded = index.clamp(0, _tabLocations.length - 1).toInt();
    context.go(_tabLocations[bounded]);
  }

  @override
  void initState() {
    super.initState();
    screenLog('HomePage', 'initState');
    startupLog('HomePage: reached HOME');
  }

  @override
  Widget build(BuildContext context) {
    screenLog('HomePage', 'build');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToTabIndex(currentLocation);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: currentIndex,
        children: _buildPages(currentIndex),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        notificationCount: ref.watch(unreadNotificationCountProvider).when(
              data: (count) => count,
              loading: () => null,
              error: (_, __) => null,
            ),
      ),
    );
  }
}
