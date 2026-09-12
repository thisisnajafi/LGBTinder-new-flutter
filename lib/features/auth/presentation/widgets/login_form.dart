import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/auth_page_scaffold.dart';
import '../../../../routes/app_router.dart';

/// Email + password fields. Parent loading/remember state must not live here
/// so keystrokes stay off [LoginScreen] (PERF-SCR-LOGIN-002).
class LoginCredentialsFields extends StatelessWidget {
  const LoginCredentialsFields({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!EmailValidator.validate(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIconPath: AppIcons.email,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          validator: validateEmail,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        AuthTextField(
          controller: passwordController,
          labelText: 'Password',
          hintText: 'Enter your password',
          obscureText: true,
          prefixIconPath: AppIcons.lockOutlined,
          textInputAction: TextInputAction.done,
          validator: validatePassword,
        ),
      ],
    );
  }
}

/// Remember-me + forgot-password row with local checkbox state.
class LoginRememberForgotRow extends StatefulWidget {
  const LoginRememberForgotRow({super.key});

  @override
  State<LoginRememberForgotRow> createState() => _LoginRememberForgotRowState();
}

class _LoginRememberForgotRowState extends State<LoginRememberForgotRow> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
                activeColor: AppColors.accentPurple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Flexible(
                child: AppText(
                  'Remember me',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.forgotPassword),
          child: AppText(
            'Forgot Password?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.accentViolet,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// Sign-up link under the social button.
class LoginSignUpFooter extends StatelessWidget {
  const LoginSignUpFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.register),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign Up',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.accentViolet,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
