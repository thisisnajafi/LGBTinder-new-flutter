import 'package:email_validator/email_validator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/auth_page_scaffold.dart';
import '../../../../routes/app_router.dart';
import 'terms_agreement_tile.dart';

/// Name / email / password fields. Loading and terms stay off this subtree
/// (PERF-SCR-REGISTER-001).
class RegisterCredentialsFields extends StatelessWidget {
  const RegisterCredentialsFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  static String? validateName(String? value, String emptyMessage) {
    if (value == null || value.isEmpty) {
      return emptyMessage;
    }
    if (value.length < 2) {
      return emptyMessage.contains('first')
          ? 'First name must be at least 2 characters'
          : 'Last name must be at least 2 characters';
    }
    return null;
  }

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
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: firstNameController,
          labelText: 'First Name',
          hintText: 'Enter your first name',
          prefixIconPath: AppIcons.user,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              validateName(value, 'Please enter your first name'),
        ),
        SizedBox(height: AppSpacing.spacingLG),
        AuthTextField(
          controller: lastNameController,
          labelText: 'Last Name',
          hintText: 'Enter your last name',
          prefixIconPath: AppIcons.user,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              validateName(value, 'Please enter your last name'),
        ),
        SizedBox(height: AppSpacing.spacingLG),
        AuthTextField(
          controller: emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIconPath: AppIcons.emailOutlined,
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
          textInputAction: TextInputAction.next,
          validator: validatePassword,
        ),
        SizedBox(height: AppSpacing.spacingLG),
        AuthTextField(
          controller: confirmPasswordController,
          labelText: 'Confirm Password',
          hintText: 'Confirm your password',
          obscureText: true,
          prefixIconPath: AppIcons.lockOutlined,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              validateConfirm(value, passwordController.text),
        ),
      ],
    );
  }
}

/// Terms row with local rebuilds; [agreed] is read on submit by the parent.
class RegisterTermsBlock extends StatefulWidget {
  const RegisterTermsBlock({super.key, required this.agreed});

  final ValueNotifier<bool> agreed;

  @override
  State<RegisterTermsBlock> createState() => _RegisterTermsBlockState();
}

class _RegisterTermsBlockState extends State<RegisterTermsBlock> {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _termsTap.onTap = () => context.push(AppRoutes.termsOfService);
    _privacyTap.onTap = () => context.push(AppRoutes.privacyPolicy);

    return ValueListenableBuilder<bool>(
      valueListenable: widget.agreed,
      builder: (context, agreed, _) {
        return TermsAgreementTile(
          value: agreed,
          onChanged: (value) => widget.agreed.value = value,
          termsRecognizer: _termsTap,
          privacyRecognizer: _privacyTap,
        );
      },
    );
  }
}

/// Sign-in link under the social button.
class RegisterSignInFooter extends StatelessWidget {
  const RegisterSignInFooter({super.key});

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
          'Already have an account? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.login),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign In',
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
