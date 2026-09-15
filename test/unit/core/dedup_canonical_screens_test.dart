import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/routes/home_tab_routes.dart';
import 'package:lgbtindernew/screens/settings/comprehensive_settings_screen.dart';
import 'package:lgbtindernew/screens/settings_screen.dart';

void main() {
  test('home tabs use a single /home path', () {
    expect(HomeTabRoutes.locationForTab(0), '/home');
    expect(HomeTabRoutes.locationForTab(1), '/home?tab=1');
    expect(HomeTabRoutes.locationForTab(4), '/home?tab=4');
    expect(
      HomeTabRoutes.redirectLegacyChild('/home/discovery'),
      '/home',
    );
    expect(
      HomeTabRoutes.redirectLegacyChild('/home/settings'),
      '/home?tab=4',
    );
  });

  test('settings aliases resolve to SettingsPage', () {
    expect(SettingsScreen, SettingsPage);
    expect(ComprehensiveSettingsScreen, SettingsPage);
  });

  test('canonical screens exist and feature stubs are gone', () {
    const keep = [
      'lib/pages/chat_list_page.dart',
      'lib/pages/chat_page.dart',
      'lib/pages/discovery_page.dart',
      'lib/pages/profile_page.dart',
      'lib/widgets/chat/message_bubble.dart',
      'lib/core/widgets/optimized_image.dart',
      'lib/widgets/cards/card_stack_manager.dart',
      'lib/features/settings/pages/settings_page.dart',
    ];
    const gone = [
      'lib/features/chat/presentation/screens/chats_screen.dart',
      'lib/features/chat/presentation/screens/chat_screen.dart',
      'lib/features/discover/presentation/screens/discover_screen.dart',
      'lib/features/profile/presentation/screens/profile_screen.dart',
      'lib/features/chat/presentation/widgets/message_bubble.dart',
      'lib/widgets/common/optimized_image.dart',
      'lib/widgets/images/image_carousel.dart',
      'lib/features/discover/presentation/widgets/swipeable_card_stack.dart',
      'lib/features/settings/presentation/screens/settings_screen.dart',
    ];
    for (final path in keep) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    for (final path in gone) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}
