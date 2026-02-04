// Screen: HomePage
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Home page - Main navigation hub with bottom navigation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DiscoveryPage(),
    const ChatListPage(),
    const NotificationsScreen(),
    const ProfilePage(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
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
