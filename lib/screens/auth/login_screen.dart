// Screen: LoginScreen
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:email_validator/email_validator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/auth_page_scaffold.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/widgets/social_login_button.dart';
import '../../features/auth/data/models/login_request.dart';
import '../../features/auth/data/models/email_verification_required_exception.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../core/utils/app_icons.dart';
import '../../shared/analytics/app_event_tracker.dart';

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
  bool _trackedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _trackedView) return;
      _trackedView = true;
      ref.read(appEventTrackerProvider).track(
            'auth_view',
            meta: {'screen': 'login'},
          );
    });
  }

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
      ref.read(appEventTrackerProvider).track(
            'auth_submit',
            meta: {'screen': 'login'},
          );
      final authService = ref.read(authServiceProvider);
      final deviceName = await _getDeviceName();
      
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceName: deviceName,
      );

      final response = await authService.login(request);
      await ref.read(authProvider.notifier).login(response);

      if (mounted) {
        // Check user state and navigate accordingly
        // Priority: email verification > profile completion > home
        if (response.userState == 'email_verification_required') {
          ref.read(appEventTrackerProvider).track('auth_state', meta: {'state': 'email_verification_required'});
          // Email verification needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email to continue'),
              backgroundColor: AppColors.warningYellow,
            ),
          );
          final target = Uri(
            path: AppRoutes.emailVerification,
            queryParameters: {
              'email': _emailController.text.trim(),
              'isNewUser': 'false',
            },
          ).toString();
          context.push(target);
        } else if (response.userState == 'ready_for_app' ||
            response.profileCompleted) {
          ref.read(appEventTrackerProvider).track('auth_success', meta: {'screen': 'login'});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login successful'),
              backgroundColor: AppColors.onlineGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          context.go(AppRoutes.home);
        } else if (response.userState == 'profile_completion_required' || 
                   response.needsProfileCompletion || 
                   !response.profileCompleted) {
          ref.read(appEventTrackerProvider).track('auth_state', meta: {'state': 'profile_completion_required'});
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
          final lastName = response.user?.lastName ?? '';
          if (firstName.isNotEmpty) {
            final params = <String, String>{'firstName': firstName};
            if (lastName.trim().isNotEmpty) {
              params['lastName'] = lastName.trim();
            }
            context.go(
              Uri(
                path: AppRoutes.profileWizard,
                queryParameters: params,
              ).toString(),
            );
          } else {
            context.go(AppRoutes.profileWizard);
          }
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
            final target = Uri(
              path: AppRoutes.emailVerification,
              queryParameters: {'email': e.email, 'isNewUser': 'false'},
            ).toString();
            context.push(target);
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
      ref.read(appEventTrackerProvider).track(
        'auth_error',
        meta: {'screen': 'login', 'code': e.code, 'message': e.message},
      );
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
                final target = Uri(
                  path: AppRoutes.emailVerification,
                  queryParameters: {'email': email, 'isNewUser': 'false'},
                ).toString();
                context.push(target);
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
      ref.read(appEventTrackerProvider).track('auth_exception', meta: {'screen': 'login', 'error': e.toString()});
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
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AuthPageScaffold(
      title: 'Sign In',
      subtitle: 'Welcome back',
      body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIconPath: AppIcons.email,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!EmailValidator.validate(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingLG),
                AuthTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIconPath: AppIcons.lockOutlined,
                  suffixIcon: AuthVisibilityToggle(
                    obscure: _obscurePassword,
                    onToggle: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRoutes.forgotPassword);
                      },
                      child: Text(
                        'Forgot Password?',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.accentViolet,
                          fontWeight: FontWeight.w600,
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
                const AuthOrDivider(),
                SizedBox(height: AppSpacing.spacingLG),
                SocialLoginButton(
                  getDeviceName: _getDeviceName,
                ),
                SizedBox(height: AppSpacing.spacingLG),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRoutes.register);
                      },
                      child: Text(
                        'Sign Up',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.accentViolet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}
