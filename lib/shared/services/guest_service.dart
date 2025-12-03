import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing guest mode
class GuestService {
  static const String _isGuestModeKey = 'is_guest_mode';

  /// Check if user is in guest mode
  Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isGuestModeKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isGuestModeKey, true);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Disable guest mode (when user logs in)
  Future<void> disableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isGuestModeKey);
    } catch (e) {
      // Silently fail - not critical
    }
  }
}

