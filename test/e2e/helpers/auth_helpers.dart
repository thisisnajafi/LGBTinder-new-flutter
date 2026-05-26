import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/data/models/login_request.dart';
import 'package:lgbtindernew/features/auth/data/models/register_response.dart';
import 'package:lgbtindernew/features/auth/data/models/verify_email_request.dart';
import 'package:lgbtindernew/features/auth/data/services/auth_service.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';
import 'package:mocktail/mocktail.dart';

import '../config/test_credentials.dart';
import 'mock_services.dart';

/// Skip live API tests when backend URL or account is not configured.
void skipIfNoApiCredentials() {
  if (!TestCredentials.hasApiBaseUrl) {
    markTestSkipped('API credentials not configured (apiBaseUrl)');
  }
}

void skipIfNoValidAccount() {
  skipIfNoApiCredentials();
  if (!TestCredentials.hasValidAccount) {
    markTestSkipped('Valid email account not configured');
  }
}

void skipIfNoPremiumAccount() {
  skipIfNoApiCredentials();
  if (!TestCredentials.hasPremiumAccount) {
    markTestSkipped('Premium tier account not configured');
  }
}

void skipIfNoFreeAccount() {
  skipIfNoApiCredentials();
  if (!TestCredentials.hasFreeAccount) {
    markTestSkipped('Free (basid) tier account not configured');
  }
}

/// Stubs [AuthService.login] for a ready authenticated user.
void stubReadyLogin(MockAuthService auth, {String email = 'user@test.com'}) {
  when(() => auth.login(any())).thenAnswer((_) async => readyLoginResponse(email: email));
}

/// Stubs login to require profile wizard completion.
void stubProfileCompletionLogin(MockAuthService auth) {
  when(() => auth.login(any())).thenAnswer((_) async => profileCompletionLoginResponse());
}

/// Stubs login to require email verification.
void stubEmailVerificationLogin(MockAuthService auth) {
  when(() => auth.login(any())).thenAnswer((_) async => emailVerificationLoginResponse());
}

/// Stubs failed login.
void stubFailedLogin(MockAuthService auth, {Object? error}) {
  when(() => auth.login(any())).thenThrow(error ?? Exception('Invalid credentials'));
}

/// Stubs successful registration → email verification flow.
void stubRegister(MockAuthService auth, {String email = 'new@test.com'}) {
  when(() => auth.register(any())).thenAnswer(
    (_) async => RegisterResponse(userId: 10, email: email, emailSent: true),
  );
}

void stubVerifyEmailSuccess(MockAuthService auth) {
  when(() => auth.verifyEmail(any())).thenAnswer((_) async => stubVerifyEmailResponse());
}

void stubVerifyEmailFailure(MockAuthService auth) {
  when(() => auth.verifyEmail(any())).thenThrow(
    ApiError(code: 422, message: 'Invalid verification code'),
  );
}

void stubResendVerification(MockAuthService auth) {
  when(() => auth.resendVerificationCode(any())).thenAnswer((_) async {});
}

void stubLogout(MockAuthService auth, InMemoryTokenStorage storage) {
  when(() => auth.logout()).thenAnswer((_) async {
    storage.seedUnauthenticated();
  });
}

LoginRequest sampleLoginRequest() => LoginRequest(
      email: TestCredentials.validEmail,
      password: TestCredentials.validPassword,
      deviceName: 'E2E Test Device',
    );
