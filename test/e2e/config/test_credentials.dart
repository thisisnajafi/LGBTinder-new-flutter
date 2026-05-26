// ============================================================
// TEST CREDENTIALS — FILL THESE IN BEFORE RUNNING TESTS
// DO NOT COMMIT REAL VALUES TO VERSION CONTROL
// Auth is email + password + email OTP only (no Firebase phone login).
// ============================================================

class TestCredentials {
  // ── Auth (email only) ─────────────────────────────────────
  /// A real registered account for happy-path flow tests
  static const String validEmail = 'test1@example.com';
  static const String validPassword = 'Prof48017421@#';
  static const String validLoginCode = '123456'; // email OTP when backend uses fixed code

  /// An account with an ACTIVE premium subscription (silder or golden tier)
  static const String premiumEmail = 'test2@example.com';
  static const String premiumPassword = 'Prof48017421@#';

  /// A free-tier account (basid) for gating tests
  static const String freeEmail = 'test3@example.com';
  static const String freePassword = 'Prof48017421@#';

  // ── API ───────────────────────────────────────────────────
  /// Base URL of the backend (e.g. http://10.0.2.2:8000 for Android emulator)
  static const String apiBaseUrl = 'https://api.lgbtfinder.com/api';

  /// A pre-issued Sanctum token for a valid session (for mock bypass)
  static const String validSanctumToken = '6|oingzgbR5l2ak6Y1S6dRB4KkcgZn87ZnCnmv6YrBb1f78f10';

  /// A pre-issued Sanctum token for a premium session
  static const String premiumSanctumToken = '5|GHh2vIh7IHMk2tS7bUYOpUn163fDtrl2TQHMEvTsb924a5b1';

  // ── Google Play Billing (sandbox) ────────────────────────
  static const String testProductId = 'FILL_ME_IN';

  // ── Target user IDs (for block/report/chat tests) ─────────
  static const String targetUserId = '741';
  static const String targetUserName = 'Test User';

  static bool isPlaceholder(String value) =>
      value.isEmpty || value == 'FILL_ME_IN';

  static bool get hasApiBaseUrl => !isPlaceholder(apiBaseUrl);

  static bool get hasValidAccount =>
      !isPlaceholder(validEmail) && !isPlaceholder(validPassword);

  static bool get hasPremiumAccount =>
      !isPlaceholder(premiumEmail) && !isPlaceholder(premiumPassword);

  static bool get hasFreeAccount =>
      !isPlaceholder(freeEmail) && !isPlaceholder(freePassword);
}
