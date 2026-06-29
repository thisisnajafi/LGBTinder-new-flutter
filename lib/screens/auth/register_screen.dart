// Screen: RegisterScreen
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_validator/email_validator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/auth_page_scaffold.dart';
import '../../features/auth/presentation/widgets/terms_agreement_tile.dart';
import '../../features/auth/presentation/widgets/social_login_button.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/data/models/register_request.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';

/// Register screen - User registration
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer();
    _privacyTap = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      
      final request = RegisterRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      final response = await authService.register(request);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.emailSent 
                ? 'Verification code sent to ${response.email}'
                : 'Registration successful. Please check your email.'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );

        // Navigate to email verification screen
        if (mounted) {
          final target = Uri(
            path: AppRoutes.emailVerification,
            queryParameters: {
              'email': response.email,
              'isNewUser': 'true',
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
            },
          ).toString();
          context.push(target);
        }
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Registration failed',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Registration failed',
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
    } catch (_) {}
    return 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    _termsTap.onTap = () => context.push(AppRoutes.termsOfService);
    _privacyTap.onTap = () => context.push(AppRoutes.privacyPolicy);

    return AuthPageScaffold(
      title: 'Create Account',
      subtitle: 'Join the community',
      body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                  prefixIconPath: AppIcons.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (value.length < 2) {
                      return 'First name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingLG),
                AuthTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                  prefixIconPath: AppIcons.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (value.length < 2) {
                      return 'Last name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingLG),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIconPath: AppIcons.emailOutlined,
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
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingLG),
                AuthTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  obscureText: _obscureConfirmPassword,
                  prefixIconPath: AppIcons.lockOutlined,
                  suffixIcon: AuthVisibilityToggle(
                    obscure: _obscureConfirmPassword,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingMD),
                TermsAgreementTile(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() => _agreeToTerms = value);
                  },
                  termsRecognizer: _termsTap,
                  privacyRecognizer: _privacyTap,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Register button
                GradientButton(
                  text: 'Create Account',
                  onPressed: _isLoading ? null : _handleRegister,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.spacingLG),
                const AuthOrDivider(),
                SizedBox(height: AppSpacing.spacingLG),
                SocialLoginButton(getDeviceName: _getDeviceName),
                SizedBox(height: AppSpacing.spacingLG),
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push(AppRoutes.login);
                      },
                      child: Text(
                        'Sign In',
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
