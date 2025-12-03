import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/token_storage_service.dart';
import '../../../../core/network/dio_client.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_state_response.dart';
import '../models/verify_email_request.dart';
import '../models/verify_email_response.dart';
import '../models/complete_registration_request.dart';
import '../models/complete_registration_response.dart';
import '../models/email_verification_required_exception.dart';
import '../models/send_otp_request.dart';
import '../models/verify_otp_request.dart';
import '../models/otp_response.dart';
import '../models/reset_password_request.dart';
import '../models/social_auth_request.dart';
import '../models/social_auth_response.dart';
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
            await _tokenStorage.saveProfileCompletionToken(loginResponse.token!);
            await _dioClient.updateAuthToken(loginResponse.token);
          }

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
            await _tokenStorage.saveProfileCompletionToken(verifyResponse.token!);
            // Also update Dio client with the token for subsequent requests
            await _dioClient.updateAuthToken(verifyResponse.token);
          }

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

  /// Complete profile registration
  Future<CompleteRegistrationResponse> completeRegistration(
    CompleteRegistrationRequest request,
  ) async {
    try {
      // Get profile completion token
      final profileToken = await _tokenStorage.getProfileCompletionToken();
      if (profileToken == null || profileToken.isEmpty) {
        throw Exception('Profile completion token not found. Please verify your email first.');
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

        // Save auth token if provided
        if (socialResponse.token != null) {
          await _tokenStorage.saveAuthToken(socialResponse.token!);
          await _dioClient.updateAuthToken(socialResponse.token);
        }

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

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.isAuthenticated();
  }
}

