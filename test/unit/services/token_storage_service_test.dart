/// Unit tests for TokenStorageService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';

import 'token_storage_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  // Note: TokenStorageService uses FlutterSecureStorage which is platform-specific
  // These tests may need to be adjusted for actual implementation
  // For now, we'll test the logic without mocking FlutterSecureStorage directly

  group('TokenStorageService', () {
    test('isAuthenticated should return false when no token', () async {
      // Arrange
      final service = TokenStorageService();

      // Act
      // Clear any existing token first
      await service.clearAuthToken();
      final result = await service.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });

    test('isAuthenticated should return true when token exists', () async {
      // Arrange
      final service = TokenStorageService();
      const testToken = 'test_auth_token';

      // Act
      await service.saveAuthToken(testToken);
      final result = await service.isAuthenticated();

      // Assert
      expect(result, isTrue);

      // Cleanup
      await service.clearAuthToken();
    });

    test('saveAuthToken and getAuthToken should work correctly', () async {
      // Arrange
      final service = TokenStorageService();
      const testToken = 'test_auth_token_123';

      // Act
      await service.saveAuthToken(testToken);
      final retrievedToken = await service.getAuthToken();

      // Assert
      expect(retrievedToken, equals(testToken));

      // Cleanup
      await service.clearAuthToken();
    });

    test('clearAuthToken should remove token', () async {
      // Arrange
      final service = TokenStorageService();
      const testToken = 'test_auth_token';

      // Act
      await service.saveAuthToken(testToken);
      await service.clearAuthToken();
      final retrievedToken = await service.getAuthToken();

      // Assert
      expect(retrievedToken, isNull);
    });

    test('clearAllTokens should remove all tokens', () async {
      // Arrange
      final service = TokenStorageService();
      const authToken = 'test_auth_token';
      const refreshToken = 'test_refresh_token';
      const profileToken = 'test_profile_token';

      // Act
      await service.saveAuthToken(authToken);
      await service.saveRefreshToken(refreshToken);
      await service.saveProfileCompletionToken(profileToken);
      await service.clearAllTokens();

      // Assert
      final auth = await service.getAuthToken();
      final refresh = await service.getRefreshToken();
      final profile = await service.getProfileCompletionToken();

      expect(auth, isNull);
      expect(refresh, isNull);
      expect(profile, isNull);
    });

    test('saveRefreshToken and getRefreshToken should work correctly', () async {
      // Arrange
      final service = TokenStorageService();
      const testToken = 'test_refresh_token';

      // Act
      await service.saveRefreshToken(testToken);
      final retrievedToken = await service.getRefreshToken();

      // Assert
      expect(retrievedToken, equals(testToken));

      // Cleanup
      await service.clearAllTokens();
    });

    test('saveProfileCompletionToken and getProfileCompletionToken should work correctly',
        () async {
      // Arrange
      final service = TokenStorageService();
      const testToken = 'test_profile_token';

      // Act
      await service.saveProfileCompletionToken(testToken);
      final retrievedToken = await service.getProfileCompletionToken();

      // Assert
      expect(retrievedToken, equals(testToken));

      // Cleanup
      await service.clearAllTokens();
    });
  });
}

