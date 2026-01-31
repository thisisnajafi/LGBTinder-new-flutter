import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/models/user_settings.dart';
import '../data/models/privacy_settings.dart';
import '../data/models/device_session.dart';
import '../data/models/matching_preferences.dart';
import '../data/models/settings_summary.dart';
import '../data/services/matching_preferences_service.dart';
import '../data/services/settings_summary_service.dart';
import '../domain/use_cases/get_settings_use_case.dart';
import '../domain/use_cases/update_settings_use_case.dart';
import '../domain/use_cases/change_password_use_case.dart';
import '../domain/use_cases/delete_account_use_case.dart';
import '../data/repositories/settings_repository.dart';

/// Settings provider - manages user settings and account operations
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final getSettingsUseCase = ref.watch(getSettingsUseCaseProvider);
  final updateSettingsUseCase = ref.watch(updateSettingsUseCaseProvider);
  final changePasswordUseCase = ref.watch(changePasswordUseCaseProvider);
  final deleteAccountUseCase = ref.watch(deleteAccountUseCaseProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);

  return SettingsNotifier(
    getSettingsUseCase: getSettingsUseCase,
    updateSettingsUseCase: updateSettingsUseCase,
    changePasswordUseCase: changePasswordUseCase,
    deleteAccountUseCase: deleteAccountUseCase,
    settingsRepository: settingsRepository,
  );
});

/// Settings state
class SettingsState {
  final UserSettings? userSettings;
  final PrivacySettings? privacySettings;
  final List<DeviceSession> deviceSessions;
  final bool isLoading;
  final bool isUpdating;
  final bool isChangingPassword;
  final bool isDeletingAccount;
  final String? error;
  final bool cacheCleared;
  final bool settingsReset;

  SettingsState({
    this.userSettings,
    this.privacySettings,
    this.deviceSessions = const [],
    this.isLoading = false,
    this.isUpdating = false,
    this.isChangingPassword = false,
    this.isDeletingAccount = false,
    this.error,
    this.cacheCleared = false,
    this.settingsReset = false,
  });

  SettingsState copyWith({
    UserSettings? userSettings,
    PrivacySettings? privacySettings,
    List<DeviceSession>? deviceSessions,
    bool? isLoading,
    bool? isUpdating,
    bool? isChangingPassword,
    bool? isDeletingAccount,
    String? error,
    bool? cacheCleared,
    bool? settingsReset,
  }) {
    return SettingsState(
      userSettings: userSettings ?? this.userSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      deviceSessions: deviceSessions ?? this.deviceSessions,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      error: error ?? this.error,
      cacheCleared: cacheCleared ?? this.cacheCleared,
      settingsReset: settingsReset ?? this.settingsReset,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final UpdateSettingsUseCase _updateSettingsUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final SettingsRepository _settingsRepository;

  SettingsNotifier({
    required GetSettingsUseCase getSettingsUseCase,
    required UpdateSettingsUseCase updateSettingsUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required SettingsRepository settingsRepository,
  }) : _getSettingsUseCase = getSettingsUseCase,
       _updateSettingsUseCase = updateSettingsUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _settingsRepository = settingsRepository,
       super(SettingsState());

  /// Load user settings
  Future<void> loadUserSettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final settings = await _getSettingsUseCase.getUserSettings();
      state = state.copyWith(
        userSettings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load privacy settings
  Future<void> loadPrivacySettings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final privacySettings = await _getSettingsUseCase.getPrivacySettings();
      state = state.copyWith(
        privacySettings: privacySettings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update user settings
  Future<void> updateUserSettings(UpdateSettingsRequest request) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final updatedSettings = await _updateSettingsUseCase.updateUserSettings(request);
      state = state.copyWith(
        userSettings: updatedSettings,
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(UpdatePrivacySettingsRequest request) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final updatedPrivacySettings = await _updateSettingsUseCase.updatePrivacySettings(request);
      state = state.copyWith(
        privacySettings: updatedPrivacySettings,
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isChangingPassword: true, error: null);

    try {
      await _changePasswordUseCase.execute(currentPassword, newPassword);
      state = state.copyWith(isChangingPassword: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount([String? password, String? reason]) async {
    state = state.copyWith(isDeletingAccount: true, error: null);

    try {
      await _deleteAccountUseCase.execute(password ?? '', reason ?? 'User requested deletion');
      state = state.copyWith(isDeletingAccount: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeletingAccount: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load device sessions
  Future<void> loadDeviceSessions() async {
    try {
      final sessions = await _settingsRepository.getDeviceSessions();
      state = state.copyWith(deviceSessions: sessions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Revoke device session
  Future<bool> revokeDeviceSession(int sessionId) async {
    try {
      await _settingsRepository.revokeDeviceSession(RevokeSessionRequest(sessionId: sessionId));
      final updatedSessions = state.deviceSessions.where((s) => s.id != sessionId).toList();
      state = state.copyWith(deviceSessions: updatedSessions);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Trust device session
  Future<bool> trustDeviceSession(int sessionId) async {
    try {
      await _settingsRepository.trustDeviceSession(TrustDeviceRequest(sessionId: sessionId));
      final updatedSessions = state.deviceSessions.map((s) =>
        s.id == sessionId ? DeviceSession(
          id: s.id,
          deviceId: s.deviceId,
          deviceName: s.deviceName,
          deviceType: s.deviceType,
          platform: s.platform,
          browser: s.browser,
          ipAddress: s.ipAddress,
          location: s.location,
          createdAt: s.createdAt,
          lastActiveAt: s.lastActiveAt,
          isCurrentDevice: s.isCurrentDevice,
          isTrusted: true, // Mark as trusted
          deviceInfo: s.deviceInfo,
        ) : s
      ).toList();
      state = state.copyWith(deviceSessions: updatedSessions);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear app cache
  Future<bool> clearCache() async {
    try {
      await _settingsRepository.clearCache();
      state = state.copyWith(cacheCleared: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Reset settings to defaults
  Future<bool> resetSettingsToDefaults() async {
    try {
      await _settingsRepository.resetToDefaults();
      state = state.copyWith(settingsReset: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      return await _settingsRepository.exportUserData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear flags
  void clearFlags() {
    state = state.copyWith(
      cacheCleared: false,
      settingsReset: false,
    );
  }

  /// Reset settings state
  void reset() {
    state = SettingsState();
  }
}

// Use case providers
final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  throw UnimplementedError('GetSettingsUseCase must be overridden in the provider scope');
});

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>((ref) {
  throw UnimplementedError('UpdateSettingsUseCase must be overridden in the provider scope');
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  throw UnimplementedError('ChangePasswordUseCase must be overridden in the provider scope');
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  throw UnimplementedError('DeleteAccountUseCase must be overridden in the provider scope');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('SettingsRepository must be overridden in the provider scope');
});

/// Matching preferences service (GET/PUT /api/preferences/matching)
final matchingPreferencesServiceProvider = Provider<MatchingPreferencesService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MatchingPreferencesService(apiService);
});

/// Async provider for matching preferences (loads from API)
final matchingPreferencesProvider = FutureProvider<MatchingPreferences>((ref) async {
  final service = ref.watch(matchingPreferencesServiceProvider);
  return service.getPreferences();
});

/// Settings summary service (GET /api/settings)
final settingsSummaryServiceProvider = Provider<SettingsSummaryService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SettingsSummaryService(apiService);
});

/// Async provider for settings summary (overview screen)
final settingsSummaryProvider = FutureProvider<SettingsSummary>((ref) async {
  final service = ref.watch(settingsSummaryServiceProvider);
  return service.getSummary();
});
