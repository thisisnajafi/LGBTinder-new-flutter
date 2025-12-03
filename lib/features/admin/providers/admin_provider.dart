import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_user.dart';
import '../data/models/admin_analytics.dart';
import '../data/models/system_health.dart';
import '../domain/use_cases/get_admin_analytics_use_case.dart';
import '../domain/use_cases/manage_admin_users_use_case.dart';
import '../domain/use_cases/system_management_use_case.dart';
import '../domain/use_cases/export_analytics_use_case.dart';

/// Admin provider - manages admin dashboard and operations
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final getAdminAnalyticsUseCase = ref.watch(getAdminAnalyticsUseCaseProvider);
  final manageAdminUsersUseCase = ref.watch(manageAdminUsersUseCaseProvider);
  final systemManagementUseCase = ref.watch(systemManagementUseCaseProvider);
  final exportAnalyticsUseCase = ref.watch(exportAnalyticsUseCaseProvider);

  return AdminNotifier(
    getAdminAnalyticsUseCase: getAdminAnalyticsUseCase,
    manageAdminUsersUseCase: manageAdminUsersUseCase,
    systemManagementUseCase: systemManagementUseCase,
    exportAnalyticsUseCase: exportAnalyticsUseCase,
  );
});

/// Admin state
class AdminState {
  final AdminAnalytics? analytics;
  final List<AdminUser> adminUsers;
  final SystemHealth? systemHealth;
  final AppConfiguration? appConfiguration;
  final bool isLoading;
  final bool isLoadingUsers;
  final bool isLoadingAnalytics;
  final bool isLoadingHealth;
  final bool isCreatingUser;
  final bool isUpdatingUser;
  final bool isDeletingUser;
  final bool isSendingNotification;
  final bool isUpdatingConfig;
  final String? error;
  final String? exportUrl;

  AdminState({
    this.analytics,
    this.adminUsers = const [],
    this.systemHealth,
    this.appConfiguration,
    this.isLoading = false,
    this.isLoadingUsers = false,
    this.isLoadingAnalytics = false,
    this.isLoadingHealth = false,
    this.isCreatingUser = false,
    this.isUpdatingUser = false,
    this.isDeletingUser = false,
    this.isSendingNotification = false,
    this.isUpdatingConfig = false,
    this.error,
    this.exportUrl,
  });

  AdminState copyWith({
    AdminAnalytics? analytics,
    List<AdminUser>? adminUsers,
    SystemHealth? systemHealth,
    AppConfiguration? appConfiguration,
    bool? isLoading,
    bool? isLoadingUsers,
    bool? isLoadingAnalytics,
    bool? isLoadingHealth,
    bool? isCreatingUser,
    bool? isUpdatingUser,
    bool? isDeletingUser,
    bool? isSendingNotification,
    bool? isUpdatingConfig,
    String? error,
    String? exportUrl,
  }) {
    return AdminState(
      analytics: analytics ?? this.analytics,
      adminUsers: adminUsers ?? this.adminUsers,
      systemHealth: systemHealth ?? this.systemHealth,
      appConfiguration: appConfiguration ?? this.appConfiguration,
      isLoading: isLoading ?? this.isLoading,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingAnalytics: isLoadingAnalytics ?? this.isLoadingAnalytics,
      isLoadingHealth: isLoadingHealth ?? this.isLoadingHealth,
      isCreatingUser: isCreatingUser ?? this.isCreatingUser,
      isUpdatingUser: isUpdatingUser ?? this.isUpdatingUser,
      isDeletingUser: isDeletingUser ?? this.isDeletingUser,
      isSendingNotification: isSendingNotification ?? this.isSendingNotification,
      isUpdatingConfig: isUpdatingConfig ?? this.isUpdatingConfig,
      error: error ?? this.error,
      exportUrl: exportUrl ?? this.exportUrl,
    );
  }
}

/// Admin notifier
class AdminNotifier extends StateNotifier<AdminState> {
  final GetAdminAnalyticsUseCase _getAdminAnalyticsUseCase;
  final ManageAdminUsersUseCase _manageAdminUsersUseCase;
  final SystemManagementUseCase _systemManagementUseCase;
  final ExportAnalyticsUseCase _exportAnalyticsUseCase;

  AdminNotifier({
    required GetAdminAnalyticsUseCase getAdminAnalyticsUseCase,
    required ManageAdminUsersUseCase manageAdminUsersUseCase,
    required SystemManagementUseCase systemManagementUseCase,
    required ExportAnalyticsUseCase exportAnalyticsUseCase,
  }) : _getAdminAnalyticsUseCase = getAdminAnalyticsUseCase,
       _manageAdminUsersUseCase = manageAdminUsersUseCase,
       _systemManagementUseCase = systemManagementUseCase,
       _exportAnalyticsUseCase = exportAnalyticsUseCase,
       super(AdminState());

  /// Load dashboard data
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load analytics and system health in parallel
      final results = await Future.wait([
        _getAdminAnalyticsUseCase.execute(),
        _systemManagementUseCase.getSystemHealth(),
      ]);

      state = state.copyWith(
        analytics: results[0] as AdminAnalytics,
        systemHealth: results[1] as SystemHealth,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load admin users
  Future<void> loadAdminUsers({
    int? page,
    int? limit,
    String? role,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoadingUsers: true, error: null);

    try {
      final users = await _manageAdminUsersUseCase.getAdminUsers(
        page: page,
        limit: limit,
        role: role,
        isActive: isActive,
      );

      state = state.copyWith(
        adminUsers: users,
        isLoadingUsers: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingUsers: false,
        error: e.toString(),
      );
    }
  }

  /// Create admin user
  Future<bool> createAdminUser(CreateAdminUserRequest request) async {
    state = state.copyWith(isCreatingUser: true, error: null);

    try {
      final newUser = await _manageAdminUsersUseCase.createAdminUser(request);
      final updatedUsers = [...state.adminUsers, newUser];

      state = state.copyWith(
        adminUsers: updatedUsers,
        isCreatingUser: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isCreatingUser: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update admin user
  Future<bool> updateAdminUser(UpdateAdminUserRequest request) async {
    state = state.copyWith(isUpdatingUser: true, error: null);

    try {
      final updatedUser = await _manageAdminUsersUseCase.updateAdminUser(request);
      final updatedUsers = state.adminUsers.map((user) =>
        user.id == request.id ? updatedUser : user
      ).toList();

      state = state.copyWith(
        adminUsers: updatedUsers,
        isUpdatingUser: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdatingUser: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete admin user
  Future<bool> deleteAdminUser(int id) async {
    state = state.copyWith(isDeletingUser: true, error: null);

    try {
      await _manageAdminUsersUseCase.deleteAdminUser(id);
      final updatedUsers = state.adminUsers.where((user) => user.id != id).toList();

      state = state.copyWith(
        adminUsers: updatedUsers,
        isDeletingUser: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isDeletingUser: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(int id, bool isActive) async {
    return await updateAdminUser(UpdateAdminUserRequest(id: id, isActive: isActive));
  }

  /// Export analytics
  Future<bool> exportAnalytics(ExportAnalyticsRequest request) async {
    try {
      final url = await _exportAnalyticsUseCase.execute(request);
      state = state.copyWith(exportUrl: url);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear system cache
  Future<bool> clearSystemCache() async {
    try {
      await _systemManagementUseCase.clearSystemCache();
      // Refresh system health
      await loadSystemHealth();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Send system notification
  Future<bool> sendSystemNotification(SystemNotificationRequest request) async {
    state = state.copyWith(isSendingNotification: true, error: null);

    try {
      await _systemManagementUseCase.sendSystemNotification(request);
      state = state.copyWith(isSendingNotification: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSendingNotification: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load system health
  Future<void> loadSystemHealth() async {
    state = state.copyWith(isLoadingHealth: true, error: null);

    try {
      final health = await _systemManagementUseCase.getSystemHealth();
      state = state.copyWith(
        systemHealth: health,
        isLoadingHealth: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHealth: false,
        error: e.toString(),
      );
    }
  }

  /// Load app configuration
  Future<void> loadAppConfiguration() async {
    try {
      final config = await _systemManagementUseCase.getAppConfiguration();
      state = state.copyWith(appConfiguration: config);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update feature flag
  Future<bool> updateFeatureFlag(String featureKey, bool enabled) async {
    state = state.copyWith(isUpdatingConfig: true, error: null);

    try {
      final updatedConfig = await _systemManagementUseCase.updateFeatureFlag(featureKey, enabled);
      state = state.copyWith(
        appConfiguration: updatedConfig,
        isUpdatingConfig: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdatingConfig: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update app setting
  Future<bool> updateAppSetting(String settingKey, dynamic value) async {
    state = state.copyWith(isUpdatingConfig: true, error: null);

    try {
      final updatedConfig = await _systemManagementUseCase.updateAppSetting(settingKey, value);
      state = state.copyWith(
        appConfiguration: updatedConfig,
        isUpdatingConfig: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdatingConfig: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null, exportUrl: null);
  }

  /// Reset admin state
  void reset() {
    state = AdminState();
  }
}

// Use case providers
final getAdminAnalyticsUseCaseProvider = Provider<GetAdminAnalyticsUseCase>((ref) {
  throw UnimplementedError('GetAdminAnalyticsUseCase must be overridden in the provider scope');
});

final manageAdminUsersUseCaseProvider = Provider<ManageAdminUsersUseCase>((ref) {
  throw UnimplementedError('ManageAdminUsersUseCase must be overridden in the provider scope');
});

final systemManagementUseCaseProvider = Provider<SystemManagementUseCase>((ref) {
  throw UnimplementedError('SystemManagementUseCase must be overridden in the provider scope');
});

final exportAnalyticsUseCaseProvider = Provider<ExportAnalyticsUseCase>((ref) {
  throw UnimplementedError('ExportAnalyticsUseCase must be overridden in the provider scope');
});
