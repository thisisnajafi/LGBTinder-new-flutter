/// Unit tests for TokenStorageService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lgbtindernew/shared/services/token_storage_service.dart';

class _InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  Future<void> write({
    required String? key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (key == null) return;
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String? key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (key == null) return null;
    return store[key];
  }

  @override
  Future<void> delete({
    required String? key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (key != null) {
      store.remove(key);
    }
  }
}

void main() {
  late _InMemorySecureStorage storage;
  late TokenStorageService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = _InMemorySecureStorage();
    service = TokenStorageService(storage: storage);
  });

  group('TokenStorageService', () {
    test('isAuthenticated should return false when no token', () async {
      await service.clearAuthToken();
      expect(await service.isAuthenticated(), isFalse);
    });

    test('isAuthenticated should return true when token exists', () async {
      await service.saveAuthToken('test_auth_token');
      expect(await service.isAuthenticated(), isTrue);
    });

    test('saveAuthToken and getAuthToken should work correctly', () async {
      const testToken = 'test_auth_token_123';
      await service.saveAuthToken(testToken);
      expect(await service.getAuthToken(), equals(testToken));
    });

    test('clearAuthToken should remove token', () async {
      await service.saveAuthToken('test_auth_token');
      await service.clearAuthToken();
      expect(await service.getAuthToken(), isNull);
    });

    test('clearAllTokens should remove all tokens', () async {
      await service.saveAuthToken('test_auth_token');
      await service.saveRefreshToken('test_refresh_token');
      await service.saveProfileCompletionToken('test_profile_token');
      await service.clearAllTokens();

      expect(await service.getAuthToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getProfileCompletionToken(), isNull);
    });

    test('saveRefreshToken and getRefreshToken should work correctly', () async {
      const testToken = 'test_refresh_token';
      await service.saveRefreshToken(testToken);
      expect(await service.getRefreshToken(), equals(testToken));
    });

    test('saveProfileCompletionToken and getProfileCompletionToken should work correctly',
        () async {
      const testToken = 'test_profile_token';
      await service.saveProfileCompletionToken(testToken);
      expect(await service.getProfileCompletionToken(), equals(testToken));
    });
  });
}
