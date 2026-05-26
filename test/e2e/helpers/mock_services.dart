import 'package:lgbtindernew/features/auth/data/models/login_request.dart';
import 'package:lgbtindernew/features/auth/data/models/login_response.dart';
import 'package:lgbtindernew/features/auth/data/models/register_request.dart';
import 'package:lgbtindernew/features/auth/data/models/register_response.dart';
import 'package:lgbtindernew/features/auth/data/models/verify_email_request.dart';
import 'package:lgbtindernew/features/auth/data/models/verify_email_response.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/features/payments/data/models/plan_limits.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorageService {}

class MockAuthService extends Mock implements AuthService {}

class MockPlanLimitsService extends Mock implements PlanLimitsService {}

/// In-memory token storage for deterministic router/guard tests.
class InMemoryTokenStorage extends TokenStorageService {
  InMemoryTokenStorage();

  String? _authToken;
  String? _profileCompletionToken;
  String? _refreshToken;

  void seedAuthenticated({String token = 'test-auth-token'}) {
    _authToken = token;
    _profileCompletionToken = null;
  }

  void seedProfileCompletion({String token = 'test-profile-token'}) {
    _authToken = null;
    _profileCompletionToken = token;
  }

  void seedUnauthenticated() {
    _authToken = null;
    _profileCompletionToken = null;
    _refreshToken = null;
  }

  @override
  Future<void> saveAuthToken(String token) async => _authToken = token;

  @override
  Future<String?> getAuthToken() async => _authToken;

  @override
  Future<void> saveProfileCompletionToken(String token) async =>
      _profileCompletionToken = token;

  @override
  Future<String?> getProfileCompletionToken() async => _profileCompletionToken;

  @override
  Future<void> saveRefreshToken(String token) async => _refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearAllTokens() async => seedUnauthenticated();

  @override
  Future<void> clearAuthToken() async => _authToken = null;

  @override
  Future<void> clearProfileCompletionToken() async =>
      _profileCompletionToken = null;

  @override
  Future<bool> isAuthenticated() async =>
      _authToken != null && _authToken!.isNotEmpty;
}

LoginResponse readyLoginResponse({String email = 'user@test.com'}) {
  return LoginResponse(
    token: 'session-token',
    profileCompleted: true,
    needsProfileCompletion: false,
    userState: 'ready',
    user: UserData(
      id: 1,
      firstName: 'Test',
      lastName: 'User',
      email: email,
    ),
  );
}

LoginResponse profileCompletionLoginResponse() {
  return LoginResponse(
    token: 'profile-token',
    profileCompleted: false,
    needsProfileCompletion: true,
    userState: 'profile_completion_required',
    user: UserData(
      id: 2,
      firstName: 'New',
      lastName: 'User',
      email: 'new@test.com',
    ),
  );
}

LoginResponse emailVerificationLoginResponse() {
  return LoginResponse(
    profileCompleted: false,
    needsProfileCompletion: false,
    userState: 'email_verification_required',
    user: UserData(
      id: 3,
      firstName: 'Verify',
      lastName: 'User',
      email: 'verify@test.com',
    ),
  );
}

RegisterResponse stubRegisterResponse() {
  return RegisterResponse(
    userId: 10,
    email: 'reg@test.com',
    emailSent: true,
  );
}

VerifyEmailResponse stubVerifyEmailResponse() => VerifyEmailResponse(
      userId: 10,
      email: 'reg@test.com',
      token: 'verified-token',
      profileCompleted: true,
      profileCompletionRequired: false,
    );

Map<String, dynamic> _usageDetail({int limit = 50}) => {
      'used_today': 0,
      'limit': limit,
      'remaining': limit,
      'is_unlimited': false,
    };

/// Minimal plan limits payload for basid / silder / golden tiers.
PlanLimits planLimitsForTier(String tier) {
  final isPremium = tier != 'basid';
  final planId = switch (tier) {
    'golden' => 3,
    'silder' => 2,
    _ => 1,
  };
  final planName = switch (tier) {
    'golden' => 'golden',
    'silder' => 'silver premium',
    _ => 'basic',
  };
  final limit = isPremium ? 999 : 50;
  return PlanLimits.fromJson({
    'data': {
      'plan_info': {
        'plan_id': planId,
        'plan_name': planName,
        'is_premium': isPremium,
      },
      'limits': {
        'swipes': {'daily_limit': limit, 'is_unlimited': isPremium},
        'likes': {'daily_limit': limit, 'is_unlimited': isPremium},
        'superlikes': {'daily_limit': isPremium ? 10 : 1, 'is_unlimited': false},
        'messages': {'max_conversations': 999, 'is_unlimited': true},
      },
      'usage': {
        'swipes': _usageDetail(limit: limit),
        'likes': _usageDetail(limit: limit),
        'superlikes': _usageDetail(limit: 5),
        'messages': {
          'sent_today': 0,
          'active_conversations': 0,
          'conversation_limit': 999,
          'is_unlimited': true,
        },
      },
      'features': {
        'advanced_filters': isPremium,
        'see_who_liked_me': isPremium,
        'rewind': isPremium,
        'passport': tier == 'golden',
        'boost': tier == 'golden',
        'read_receipts': isPremium,
        'video_calls': isPremium,
        'incognito_mode': false,
        'ad_free': isPremium,
        'priority_likes': isPremium,
        'ai_matching': tier == 'golden',
      },
      'timestamps': {
        'resets_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'checked_at': DateTime.now().toIso8601String(),
      },
    },
  });
}

/// Stubs [PlanLimitsService] for widgets that read [planLimitsProvider].
void stubPlanLimitsService(
  MockPlanLimitsService planLimits, {
  String tier = 'basid',
}) {
  when(() => planLimits.isCacheValid()).thenReturn(false);
  when(() => planLimits.getCachedLimits()).thenReturn(null);
  when(() => planLimits.getPlanLimits(forceRefresh: any(named: 'forceRefresh')))
      .thenAnswer((_) async => planLimitsForTier(tier));
}

void registerAuthFallbacks() {
  registerFallbackValue(
    LoginRequest(email: 'a@b.com', password: 'x', deviceName: 'test'),
  );
  registerFallbackValue(
    RegisterRequest(
      email: 'a@b.com',
      password: 'x',
      passwordConfirmation: 'x',
      firstName: 'A',
      lastName: 'B',
    ),
  );
  registerFallbackValue(VerifyEmailRequest(email: 'a@b.com', code: '000000'));
}
