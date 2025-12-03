// Screen: LoginScreen
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/data/models/login_request.dart';
import '../../features/auth/data/models/email_verification_required_exception.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'package:go_router/go_router.dart';
import '../../pages/home_page.dart';
import '../../pages/profile_wizard_page.dart';
import 'forgot_password_screen.dart';
import '../../core/utils/app_icons.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';

/// Login screen - User authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (e) {
      // Fallback if device info fails
    }
    return 'Unknown Device';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final deviceName = await _getDeviceName();
      
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceName: deviceName,
      );

      final response = await authService.login(request);

      if (mounted) {
        // Check user state and navigate accordingly
        // Priority: email verification > profile completion > home
        if (response.userState == 'email_verification_required') {
          // Email verification needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email to continue'),
              backgroundColor: AppColors.warningYellow,
            ),
          );
          context.go('/email-verification?email=${Uri.encodeComponent(_emailController.text.trim())}&isNewUser=false');
        } else if (response.userState == 'profile_completion_required' || 
                   response.needsProfileCompletion || 
                   !response.profileCompleted) {
          // Profile completion needed - token is already saved in auth service
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your profile to continue'),
              backgroundColor: AppColors.accentPurple,
              duration: Duration(seconds: 2),
            ),
          );
          // Pass first_name from login response to profile wizard
          final firstName = response.firstName ?? response.user?.firstName ?? '';
          if (firstName.isNotEmpty) {
            context.go('/profile-wizard?firstName=${Uri.encodeComponent(firstName)}');
          } else {
            context.go('/profile-wizard');
          }
        } else {
          // Everything is complete, go to home
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login successful'),
              backgroundColor: AppColors.onlineGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          context.go('/home');
        }
      }
    } on EmailVerificationRequiredException catch (e) {
      // Email verification required - request code and redirect
      if (mounted) {
        setState(() {
          _isLoading = true; // Keep loading while requesting code
        });
        
        try {
          // Get auth service and request verification code
          final authService = ref.read(authServiceProvider);
          await authService.requestVerificationCodeForExistingUser(e.email);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Verification code sent to your email'),
                backgroundColor: AppColors.onlineGreen,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Navigate to email verification screen
            context.go('/email-verification?email=${Uri.encodeComponent(e.email)}&isNewUser=false');
          }
        } catch (codeError) {
          if (mounted) {
            ErrorHandlerService.handleError(
              context,
              codeError,
              customMessage: 'Failed to send verification code',
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } on ApiError catch (e) {
      // Check if this is a 403 error that might be email verification required
      // This is a fallback in case the exception wasn't thrown in auth service
      if (e.code == 403 && e.responseData != null) {
        final responseData = e.responseData!;
        final nestedData = responseData['data'] as Map<String, dynamic>?;
        if (nestedData != null && nestedData['user_state'] == 'email_verification_required') {
          // Handle as email verification required
          final email = nestedData['email'] as String? ?? _emailController.text.trim();
          if (mounted) {
            setState(() {
              _isLoading = true; // Keep loading while requesting code
            });
            
            try {
              // Get auth service and request verification code
              final authService = ref.read(authServiceProvider);
              await authService.requestVerificationCodeForExistingUser(email);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Verification code sent to your email'),
                    backgroundColor: AppColors.onlineGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                // Navigate to email verification screen
                context.go('/email-verification?email=${Uri.encodeComponent(email)}&isNewUser=false');
              }
            } catch (codeError) {
              if (mounted) {
                ErrorHandlerService.handleError(
                  context,
                  codeError,
                  customMessage: 'Failed to send verification code',
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          }
          return; // Exit early, don't show error
        }
      }
      
      if (mounted) {
        // Show the actual API error message without prepending "Login failed"
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Login failed',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Sign In',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.spacingXXL),
                Text(
                  'Welcome Back',
                  style: AppTypography.h1.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'Sign in to continue',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    labelStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                    hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: AppSpacing.spacingMD,
                      horizontal: AppSpacing.spacingLG,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: AppSvgIcon(
                        assetPath: AppIcons.email,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingLG),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    labelStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                    hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: AppSpacing.spacingMD,
                      horizontal: AppSpacing.spacingLG,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: AppSvgIcon(
                        assetPath: AppIcons.lockOutlined,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    suffixIcon: IconButton(
                      padding: const EdgeInsets.all(12.0),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: AppSvgIcon(
                        assetPath: _obscurePassword ? AppIcons.visibility : AppIcons.visibilityOff,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingMD),
                // Remember me & Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppColors.accentPurple,
                        ),
                        Text(
                          'Remember me',
                          style: AppTypography.body.copyWith(color: textColor),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.button.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Login button
                GradientButton(
                  text: 'Sign In',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.spacingLG),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTypography.button.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
