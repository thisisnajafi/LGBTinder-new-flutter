// ============================================================
// TEST CREDENTIALS — FILL THESE IN BEFORE RUNNING TESTS
// DO NOT COMMIT REAL VALUES TO VERSION CONTROL
// ============================================================

class TestCredentials {
  // ── Auth ──────────────────────────────────────────────────
  /// A real registered account for happy-path flow tests
  static const String validEmail         = 'kavehascend@gmail.com';
  static const String validPassword      = 'Prof48017421@#';
  static const String validLoginCode     = '123456'; // fixed when LOGIN_CODE_USE_FIXED=true on backend

  /// An account with an ACTIVE premium subscription (silder or golden tier)
  static const String premiumEmail       = 'FILL_ME_IN';
  static const String premiumPassword    = 'FILL_ME_IN';

  /// A free-tier account (basid) for gating tests
  static const String freeEmail          = 'FILL_ME_IN';
  static const String freePassword       = 'FILL_ME_IN';

  // ── API ───────────────────────────────────────────────────
  /// Base URL of the backend (e.g. http://10.0.2.2:8000 for Android emulator)
  static const String apiBaseUrl         = 'https://api.lgbtfinder.com/api';

  /// A pre-issued Sanctum token for a valid session (for mock bypass)
  static const String validSanctumToken  = 'FILL_ME_IN';

  /// A pre-issued Sanctum token for a premium session
  static const String premiumSanctumToken = 'FILL_ME_IN';

  // ── Firebase ─────────────────────────────────────────────
  static const String testPhoneNumber    = 'FILL_ME_IN'; // E.164 format
  static const String testPhoneOtp       = 'FILL_ME_IN'; // Firebase test OTP

  // ── Google Play Billing (sandbox) ────────────────────────
  static const String testProductId      = 'FILL_ME_IN';

  // ── Target user IDs (for block/report/chat tests) ─────────
  static const String targetUserId       = 'FILL_ME_IN';
  static const String targetUserName     = 'FILL_ME_IN';
}
