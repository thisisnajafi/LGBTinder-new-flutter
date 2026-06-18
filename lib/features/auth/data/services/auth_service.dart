import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/token_storage_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/api_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_state_response.dart';
import '../models/verify_email_request.dart';
import '../models/verify_email_response.dart';
import '../models/complete_registration_request.dart';
import '../models/complete_registration_response.dart';
import '../models/check_token_response.dart';
import '../models/otp_request.dart';
import '../models/otp_response.dart';
import '../models/social_auth_request.dart';
import '../models/social_auth_response.dart';
import '../models/verify_email_response.dart';
import '../models/complete_registration_response.dart';
import '../../../../shared/models/api_error.dart';

/// Authentication service for handling all auth-related API calls
class AuthService {
  final ApiService _apiService;
  final TokenStorageService _tokenStorage;
  final DioClient _dioClient;

  AuthService(
    this._apiService,
    this._tokenStorage,
    this._dioClient,
  );

  Future<void> _persistLoginResponse(LoginResponse response) async {
    final user = response.user;
    if (user == null) return;
    await _tokenStorage.saveUserSession(
      user: user,
      profileCompleted: response.profileCompleted,
      userState: response.userState,
    );
  }

  Future<void> _persistVerifyEmailResponse(VerifyEmailResponse response) async {
    await _tokenStorage.saveUserSession(
      user: UserData(
        id: response.userId,
        firstName: response.firstName?.trim().isNotEmpty == true
            ? response.firstName!.trim()
            : 'User',
        lastName: response.lastName?.trim() ?? '',
        email: response.email,
      ),
      profileCompleted: response.profileCompleted,
      userState: response.profileCompletionRequired
          ? 'profile_completion_required'
          : null,
    );
  }

  Future<void> _persistSocialResponse(SocialAuthResponse response) async {
    final userId = response.userId;
    final email = response.email;
    if (userId == null || email == null || email.isEmpty) return;
    await _tokenStorage.saveUserSession(
      user: UserData(
        id: userId,
        firstName: response.firstName ?? 'User',
        lastName: '',
        email: email,
      ),
      profileCompleted: response.profileCompleted,
      userState: response.userState,
    );
  }

  Future<void> _persistCompleteRegistration(CompleteRegistrationResponse response) async {
    final user = response.user;
    if (user == null) return;
    await _tokenStorage.saveUserSession(
      user: user,
      profileCompleted: response.profileCompleted,
      userState: response.userState,
    );
  }

  Future<void> _saveAuthTokensForLogin({
    required String token,
    required bool profileCompleted,
    String? userState,
  }) async {
    await _tokenStorage.saveAuthToken(token);
    if (!profileCompleted || userState == 'profile_completion_required') {
      await _tokenStorage.saveProfileCompletionToken(token);
    }
    await _dioClient.updateAuthToken(token);
  }

  Future<String?> _resolveProfileCompletionToken() async {
    final profileToken = await _tokenStorage.getProfileCompletionToken();
    if (profileToken != null && profileToken.isNotEmpty) {
      return profileToken;
    }

    // Magic-link, social auth, and token refresh may only persist auth_token.
    final authToken = await _tokenStorage.getAuthToken();
    if (authToken != null && authToken.isNotEmpty) {
      return authToken;
    }

    return null;
  }

  /// Register a new user
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return RegisterResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Login with email and password
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.loginPassword,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Handle both success and profile completion required cases
      // Profile completion required returns status: false but with valid data
      if (response.data != null) {
        final data = response.data!;
        
        // When status is false, response.data is the nested data object from the API response
        // The structure is: {status: false, message: "...", data: {user_state: "...", email: "...", ...}}
        // So response.data contains the nested data object directly
        final userState = data['user_state'] as String?;
        final isEmailVerificationRequired = userState == 'email_verification_required' ||
            response.message.toLowerCase().contains('verify your email');
        
        // If status is false and email verification is required, throw special exception
        if (!response.status && isEmailVerificationRequired) {
          // Extract email from data
          final email = data['email'] as String? ?? request.email;
          throw EmailVerificationRequiredException(email: email, message: response.message);
        }
        
        // Check if this is a profile completion required response
        final isProfileCompletionRequired = userState == 'profile_completion_required' ||
            response.message.toLowerCase().contains('profile completion required');
        
        // If status is false but it's a profile completion required case, handle it
        if (!response.status && isProfileCompletionRequired) {
          // This is a valid response for profile completion
          // data is already the nested data object, so use it directly
          final loginResponse = LoginResponse.fromJson(data);

          // Save profile completion token if provided
          if (loginResponse.token != null) {
            // Keep auth stage consistent: profile completion users are signed-in but constrained.
            await _tokenStorage.saveAuthToken(loginResponse.token!);
            await _tokenStorage.saveProfileCompletionToken(loginResponse.token!);
            await _dioClient.updateAuthToken(loginResponse.token);
          }
          await _persistLoginResponse(loginResponse);

          return loginResponse;
        }
        
        // Normal success case
        if (response.isSuccess) {
          final loginResponse = LoginResponse.fromJson(data);

          // Save auth token if provided
          if (loginResponse.token != null) {
            await _tokenStorage.saveAuthToken(loginResponse.token!);
            await _dioClient.updateAuthToken(loginResponse.token);
          }

          // Save refresh token if provided in response
          final refreshToken = data['refresh_token'] as String?;
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await _tokenStorage.saveRefreshToken(refreshToken);
          }

          await _persistLoginResponse(loginResponse);
          return loginResponse;
        }
      }
      
      // If we get here, it's a real error
      throw Exception(response.message.isNotEmpty 
          ? response.message 
          : 'Login failed');
    } on ApiError catch (e) {
      // Check if this is a 403 error with profile_completion_required or email_verification_required
      // These are not real errors - they're valid responses that need special handling
      if (e.code == 403) {
        try {
          // Try to get response data from ApiError's responseData field first
          Map<String, dynamic>? responseData = e.responseData;
          
          // Fallback: Try to get from DioException if responseData is not available
          if (responseData == null && e.originalError is DioException) {
            final dioError = e.originalError as DioException;
            if (dioError.response?.data != null) {
              final data = dioError.response!.data;
              if (data is Map<String, dynamic>) {
                responseData = data;
              }
            }
          }
          
          // If we have response data, check for special cases
          if (responseData != null) {
            // The response structure from backend is: {status: false, message: "...", data: {...}}
            // Extract the nested data object
            final nestedData = responseData['data'] as Map<String, dynamic>?;
            if (nestedData != null) {
              final userState = nestedData['user_state'] as String?;
              
              // Check for email verification required
              if (userState == 'email_verification_required') {
                final email = nestedData['email'] as String? ?? request.email;
                // Throw the exception to be caught by login screen
                throw EmailVerificationRequiredException(
                  email: email, 
                  message: responseData['message'] as String? ?? e.message,
                );
              }
              
              // Check for profile completion required
              if (userState == 'profile_completion_required') {
                final loginResponse = LoginResponse.fromJson(nestedData);

                // Save token as main auth token to log the user in
                // This token allows the user to complete their profile
                if (loginResponse.token != null) {
                  // Save as main auth token (user is logged in)
                  await _tokenStorage.saveAuthToken(loginResponse.token!);
                  // Also save as profile completion token for profile completion API calls
                  await _tokenStorage.saveProfileCompletionToken(loginResponse.token!);
                  // Update Dio client with the token for subsequent requests
                  await _dioClient.updateAuthToken(loginResponse.token);
                }
                await _persistLoginResponse(loginResponse);

                return loginResponse;
              }
            }
          }
        } catch (parseError) {
          // If parsing fails, fall through to rethrow the original ApiError
          // This ensures we don't hide real errors
        }
      }
      // If it's not a special case, rethrow the ApiError
      rethrow;
    } catch (e) {
      // Re-throw EmailVerificationRequiredException so it can be caught by login screen
      if (e is EmailVerificationRequiredException) {
        rethrow;
      }
      rethrow;
    }
  }

  /// Magic-link login: request a login code sent to email (POST auth/login). Body: email, device_name.
  Future<Map<String, dynamic>> requestMagicLink({
    required String email,
    String deviceName = 'app',
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'device_name': deviceName},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Magic-link login: verify the code received by email (POST auth/verify-login-code). Body: email, code, device_name.
  Future<LoginResponse> verifyMagicLinkCode({
    required String email,
    required String code,
    String deviceName = 'app',
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.verifyLoginCode,
      data: {'email': email, 'code': code, 'device_name': deviceName},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }
    final loginResponse = LoginResponse.fromJson(response.data!);
    if (loginResponse.token != null) {
      await _saveAuthTokensForLogin(
        token: loginResponse.token!,
        profileCompleted: loginResponse.profileCompleted,
        userState: loginResponse.userState,
      );
    }
    final refreshToken = response.data!['refresh_token'] as String?;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken);
    }
    await _persistLoginResponse(loginResponse);
    return loginResponse;
  }

  /// Check user state (for app launch)
  Future<UserStateResponse> checkUserState(String email) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.checkUserState,
        data: {'email': email},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Note: This endpoint returns 403 for email_verification_required or profile_completion_required
      // So we need to handle it in the error response
      if (response.isSuccess && response.data != null) {
        return UserStateResponse.fromJson(response.data!);
      } else {
        // Check if it's an error response with user state info
        if (response.data != null) {
          return UserStateResponse.fromJson(response.data!);
        }
        throw Exception(response.message);
      }
    } catch (e) {
      // Re-throw to let caller handle ApiError
      rethrow;
    }
  }

  /// Verify email with 6-digit code
  Future<VerifyEmailResponse> verifyEmail(VerifyEmailRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.sendVerification,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      // Check if response is successful
      if (response.status && response.data != null) {
        try {
          final verifyResponse = VerifyEmailResponse.fromJson(response.data!);

          // Save profile completion token if provided
          if (verifyResponse.token != null) {
            // Keep auth stage consistent with login profile-completion flow.
            await _tokenStorage.saveAuthToken(verifyResponse.token!);
            await _tokenStorage.saveProfileCompletionToken(verifyResponse.token!);
            // Also update Dio client with the token for subsequent requests
            await _dioClient.updateAuthToken(verifyResponse.token);
          }
          await _persistVerifyEmailResponse(verifyResponse);

          return verifyResponse;
        } catch (e) {
          // If parsing fails, throw a more descriptive error
          throw Exception('Failed to parse verification response: $e');
        }
      } else {
        // Response status is false or data is null
        throw Exception(response.message.isNotEmpty 
            ? response.message 
            : 'Email verification failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Resend verification code for new user registration
  Future<void> resendVerificationCode(String email) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.resendVerification,
        data: {'email': email},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.status) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to resend verification code');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Request verification code for existing user (for login flow)
  Future<void> requestVerificationCodeForExistingUser(String email) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.resendVerificationExisting,
        data: {'email': email},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.status) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to send verification code');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /auth/check-token — validate session and read profile completion state.
  Future<CheckTokenResponse> checkToken() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.checkToken,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess || response.data == null) {
      throw ApiError(
        message: response.message.isNotEmpty
            ? response.message
            : 'Invalid session',
        code: 401,
      );
    }

    return CheckTokenResponse.fromJson(response.data!);
  }

  /// Persist bootstrap routing state from [checkToken].
  Future<void> syncBootstrapSession(CheckTokenResponse state) async {
    final user = state.user;
    if (user == null) return;

    await _tokenStorage.saveUserSession(
      user: user,
      profileCompleted: state.isComplete,
      userState: state.userState,
    );

    if (state.isComplete) {
      await _tokenStorage.clearProfileCompletionToken();
    }
  }

  /// Complete profile registration
  Future<CompleteRegistrationResponse> completeRegistration(
    CompleteRegistrationRequest request,
  ) async {
    try {
      final profileToken = await _resolveProfileCompletionToken();
      if (profileToken == null || profileToken.isEmpty) {
        throw ApiError(
          message: 'Profile completion token not found. Please verify your email first.',
          code: 401,
        );
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.completeRegistration,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
        options: Options(
          headers: {
            'Authorization': 'Bearer $profileToken',
          },
        ),
      );

      if (response.isSuccess && response.data != null) {
        final completeResponse = CompleteRegistrationResponse.fromJson(response.data!);

        // Save full access token if provided
        if (completeResponse.token != null) {
          await _tokenStorage.saveAuthToken(completeResponse.token!);
          await _tokenStorage.clearProfileCompletionToken();
          await _dioClient.updateAuthToken(completeResponse.token);
        }
        await _persistCompleteRegistration(completeResponse);

        return completeResponse;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout - clear tokens
  Future<void> logout() async {
    await _tokenStorage.clearAllTokens();
    _dioClient.clearAuthToken();
  }

  /// Send OTP for password reset
  Future<OtpResponse> sendOtp(SendOtpRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.sendOtp,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null) {
        return OtpResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to send OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP for password reset
  Future<OtpResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.verifyOtp,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null) {
        return OtpResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to verify OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password with verified OTP
  Future<OtpResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null) {
        return OtpResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to reset password');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get Google OAuth authorization URL
  Future<ApiResponse<Map<String, dynamic>>> getGoogleAuthUrl() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.googleAuthUrl,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Handle social authentication callback
  Future<SocialAuthResponse> handleSocialCallback(SocialAuthRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.googleCallback,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null) {
        final socialResponse = SocialAuthResponse.fromJson(response.data!);

        if (socialResponse.token != null) {
          await _saveAuthTokensForLogin(
            token: socialResponse.token!,
            profileCompleted: socialResponse.profileCompleted,
            userState: socialResponse.userState,
          );
        }
        await _persistSocialResponse(socialResponse);

        return socialResponse;
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Social authentication failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get linked accounts (API: GET auth/linked-accounts). Returns data.linked_accounts.
  Future<List<Map<String, dynamic>>> getLinkedAccounts() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.authLinkedAccounts,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return [];
      final list = response.data!['linked_accounts'] as List<dynamic>? ?? [];
      return list
          .where((e) => e is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Unlink Google account (API: DELETE auth/google/unlink).
  Future<void> unlinkGoogle() async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.authGoogleUnlink,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.isAuthenticated();
  }
}

