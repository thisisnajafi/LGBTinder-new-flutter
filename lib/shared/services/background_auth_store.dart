import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_endpoints.dart';

/// Prefs keys. Android native reads `flutter.` + these names from
/// `FlutterSharedPreferences`. iOS reads the same keys from UserDefaults.
const String kBackgroundAuthTokenKey = 'lgbtfinder_bg_auth_token';
const String kBackgroundApiOriginKey = 'lgbtfinder_bg_api_origin';
const String kCallkitPendingActionsKey = 'lgbtfinder_callkit_pending_actions';

/// Copies the bearer token where a killed-app CallKit handler can read it.
class BackgroundAuthStore {
  static Future<void> mirror(String? token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = token?.trim() ?? '';
      if (value.isEmpty) {
        await prefs.remove(kBackgroundAuthTokenKey);
        await prefs.remove(kBackgroundApiOriginKey);
        return;
      }
      await prefs.setString(kBackgroundAuthTokenKey, value);
      await prefs.setString(kBackgroundApiOriginKey, ApiEndpoints.apiOrigin);
    } catch (_) {}
  }
}
