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
  static const String premiumEmail = 'FILL_ME_IN';
  static const String premiumPassword = 'FILL_ME_IN';

  /// A free-tier account (basid) for gating tests
  static const String freeEmail = 'test3@example.com';
  static const String freePassword = 'Prof48017421@#';

  // ── API ───────────────────────────────────────────────────
  /// Base URL of the backend (e.g. http://10.0.2.2:8000 for Android emulator)
  static const String apiBaseUrl = 'https://api.lgbtfinder.com/api';

  /// A pre-issued Sanctum token for a valid session (for mock bypass)
  static const String validSanctumToken = '2|oPDUfDYsKQTpE40OTkQPJIOtrGwNPSeXUVhuhbYcfac10942';

  /// A pre-issued Sanctum token for a premium session
  static const String premiumSanctumToken = '4|capxUGpS0IjH2DxjbZTNvItSlBEjYWKADjf6BKEE1c633dce';

  // ── Google Play Billing (sandbox) ────────────────────────
  static const String testProductId = 'FILL_ME_IN';

  // ── Target user IDs (for block/report/chat tests) ─────────
  static const String targetUserId = 'FILL_ME_IN';
  static const String targetUserName = 'FILL_ME_IN';

  static bool get isPlaceholder(String value) =>
      value.isEmpty || value == 'FILL_ME_IN';

  static bool get hasApiBaseUrl => !isPlaceholder(apiBaseUrl);

  static bool get hasValidAccount =>
      !isPlaceholder(validEmail) && !isPlaceholder(validPassword);

  static bool get hasPremiumAccount =>
      !isPlaceholder(premiumEmail) && !isPlaceholder(premiumPassword);

  static bool get hasFreeAccount =>
      !isPlaceholder(freeEmail) && !isPlaceholder(freePassword);
}
