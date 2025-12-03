// Screen: ForgotPasswordScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import 'login_screen.dart';

/// Forgot password screen - Password reset
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Send password reset email via API
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        AlertDialogCustom.show(
          context,
          title: 'Email Sent',
          message: 'We\'ve sent a password reset link to ${_emailController.text}. Please check your email.',
          icon: Icons.email,
          iconColor: AppColors.accentPurple,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
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
        title: 'Forgot Password',
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
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.accentPurple,
                ),
                SizedBox(height: AppSpacing.spacingXL),
                Text(
                  'Reset Password',
                  style: AppTypography.h1.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  _emailSent
                      ? 'Check your email for reset instructions'
                      : 'Enter your email address and we\'ll send you a link to reset your password',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                if (!_emailSent) ...[
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
                  SizedBox(height: AppSpacing.spacingXXL),
                  // Send reset button
                  GradientButton(
                    text: 'Send Reset Link',
                    onPressed: _isLoading ? null : _handleResetPassword,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      border: Border.all(color: AppColors.onlineGreen),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppColors.onlineGreen,
                        ),
                        SizedBox(height: AppSpacing.spacingMD),
                        Text(
                          'Email Sent!',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.onlineGreen,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingSM),
                        Text(
                          'Please check your inbox and follow the instructions to reset your password.',
                          style: AppTypography.body.copyWith(color: textColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  GradientButton(
                    text: 'Back to Sign In',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    isFullWidth: true,
                  ),
                ],
                SizedBox(height: AppSpacing.spacingLG),
                // Back to login
                if (!_emailSent)
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      'Back to Sign In',
                      style: AppTypography.button.copyWith(
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
