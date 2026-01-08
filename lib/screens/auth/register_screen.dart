// Screen: RegisterScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/data/models/register_request.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'package:go_router/go_router.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';

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
  final _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
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
        referralCode: _referralCodeController.text.trim().isEmpty 
            ? null 
            : _referralCodeController.text.trim(),
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
          context.go('/email-verification?email=${Uri.encodeComponent(response.email)}&isNewUser=true');
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
        title: 'Create Account',
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
                SizedBox(height: AppSpacing.spacingXL),
                Text(
                  'Join LGBTFinder',
                  style: AppTypography.h1.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'Create your account to get started',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                // First Name field
                TextFormField(
                  controller: _firstNameController,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
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
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: secondaryTextColor,
                    ),
                  ),
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
                // Last Name field
                TextFormField(
                  controller: _lastNameController,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
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
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: secondaryTextColor,
                    ),
                  ),
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
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: secondaryTextColor,
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
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: secondaryTextColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.spacingLG),
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
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
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: secondaryTextColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: secondaryTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
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
                SizedBox(height: AppSpacing.spacingLG),
                // Referral code field (optional)
                TextFormField(
                  controller: _referralCodeController,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Referral Code (Optional)',
                    hintText: 'Enter referral code if you have one',
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
                    prefixIcon: Icon(
                      Icons.card_giftcard_outlined,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                // Terms agreement
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.accentPurple,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: AppTypography.body.copyWith(color: textColor),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.accentPurple,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.accentPurple,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign In',
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
