// Provider: AuthProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/login_response.dart';
import '../data/models/user_state_response.dart';
import '../data/services/auth_service.dart';
import '../../user/data/models/user_info.dart';
import '../../../shared/services/token_storage_service.dart';
import '../../../shared/services/onboarding_service.dart';
import '../../../core/providers/api_providers.dart';
import 'auth_service_provider.dart';

/// Auth Provider State
class AuthProviderState {
  final bool isAuthenticated;
  final bool isEmailVerified;
  final bool isProfileComplete;
  final bool hasCompletedOnboarding;
  final UserData? user;
  final bool isLoading;
  final String? errorMessage;

  AuthProviderState({
    this.isAuthenticated = false,
    this.isEmailVerified = false,
    this.isProfileComplete = false,
    this.hasCompletedOnboarding = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthProviderState copyWith({
    bool? isAuthenticated,
    bool? isEmailVerified,
    bool? isProfileComplete,
    bool? hasCompletedOnboarding,
    UserData? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthProviderState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Auth Provider Notifier
class AuthProviderNotifier extends StateNotifier<AuthProviderState> {
  final AuthService _authService;
  final TokenStorageService _tokenStorage;
  final OnboardingService _onboardingService;

  AuthProviderNotifier(
    this._authService,
    this._tokenStorage,
    this._onboardingService,
  ) : super(AuthProviderState()) {
    // Check auth status on initialization
    checkAuthStatus();
  }

  /// Check authentication status
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isAuthenticated = await _tokenStorage.isAuthenticated();
      final hasCompletedOnboarding = await _onboardingService.isOnboardingCompleted();

      if (!isAuthenticated) {
        state = state.copyWith(
          isAuthenticated: false,
          hasCompletedOnboarding: hasCompletedOnboarding,
          isLoading: false,
        );
        return;
      }

      // If authenticated, try to get user info to check profile completion
      // Note: This requires a separate call to user service
      // For now, we'll just set authenticated status
      state = state.copyWith(
        isAuthenticated: true,
        hasCompletedOnboarding: hasCompletedOnboarding,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Login user
  Future<void> login(LoginResponse loginResponse) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Update state with login response
      state = state.copyWith(
        isAuthenticated: true,
        isEmailVerified: loginResponse.userState != 'email_verification_required',
        isProfileComplete: loginResponse.profileCompleted,
        user: loginResponse.user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Logout user.
  /// [silent] when true (e.g. from 401 handler): do not set loading state so it can be
  /// run fire-and-forget without blocking the UI; storage is still cleared.
  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }

    try {
      await _authService.logout();
      await _tokenStorage.clearAllTokens();

      state = AuthProviderState(
        isAuthenticated: false,
        isEmailVerified: false,
        isProfileComplete: false,
        hasCompletedOnboarding: false,
        user: null,
        isLoading: false,
      );
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        );
      }
      // Ensure we end in logged-out state even on error so 401 flow is consistent
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        isLoading: false,
      );
    }
  }

  /// Update profile completion status
  void updateProfileStatus(bool isComplete) {
    state = state.copyWith(isProfileComplete: isComplete);
  }

  /// Update email verification status
  void updateEmailVerificationStatus(bool isVerified) {
    state = state.copyWith(isEmailVerified: isVerified);
  }

  /// Update onboarding completion status
  Future<void> updateOnboardingStatus(bool isCompleted) async {
    if (isCompleted) {
      await _onboardingService.markOnboardingCompleted();
    } else {
      await _onboardingService.resetOnboardingStatus();
    }
    
    state = state.copyWith(hasCompletedOnboarding: isCompleted);
  }

  /// Update user data
  void updateUser(UserData? user) {
    state = state.copyWith(user: user);
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthProviderNotifier, AuthProviderState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  final onboardingService = OnboardingService();
  
  return AuthProviderNotifier(authService, tokenStorage, onboardingService);
});
