import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/routes/home_tab_routes.dart';

void main() {
  group('HomeTabRoutes', () {
    test('locationForTab uses /home for discover', () {
      expect(HomeTabRoutes.locationForTab(0), AppRoutes.home);
      expect(HomeTabRoutes.locationForTab(1), '${AppRoutes.home}?tab=1');
    });

    test('tabIndexFromUri reads tab query', () {
      expect(
        HomeTabRoutes.tabIndexFromUri(
          Uri.parse('${AppRoutes.home}?tab=2'),
          matchedPath: AppRoutes.home,
        ),
        2,
      );
    });

    test('tabIndexFromUri supports legacy paths', () {
      expect(
        HomeTabRoutes.tabIndexFromUri(
          Uri.parse('${AppRoutes.home}/chat-list'),
          matchedPath: '${AppRoutes.home}/chat-list',
        ),
        1,
      );
    });
  });
}
