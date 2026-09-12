import 'package:flutter/material.dart';

import '../navigation/auth_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import 'premium/premium_page.dart';
import 'premium/premium_text_field.dart';

/// Premium shell for unauthenticated screens (login, register, forgot password).
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AuthNavigation.backScope(
      context: context,
      child: PremiumDetailScaffold(
        title: title,
        subtitle: subtitle,
        onBack: onBack ?? () => AuthNavigation.popOrWelcome(context),
        body: body,
      ),
    );
  }
}

/// Shared divider between email/password and social sign-in.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final line = isDark
        ? AppColors.borderMediumDark
        : AppColors.borderMediumLight;
    final muted = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      children: [
        Expanded(child: Divider(color: line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
        ),
        Expanded(child: Divider(color: line)),
      ],
    );
  }
}

/// Premium-styled text field shared across auth forms.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIconPath,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? prefixIconPath;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return PremiumTextField(
      controller: controller,
      label: labelText,
      hintText: hintText,
      keyboardType: keyboardType,
      obscureText: obscureText,
      prefixIconPath: prefixIconPath,
      suffixIcon: suffixIcon,
      enableObscureToggle: suffixIcon == null && obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
      autocorrect: autocorrect,
    );
  }
}

/// Password visibility toggle with 48dp touch target.
class AuthVisibilityToggle extends StatelessWidget {
  const AuthVisibilityToggle({
    super.key,
    required this.obscure,
    required this.onToggle,
  });

  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return IconButton(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: AppSvgIcon(
        assetPath: obscure ? AppIcons.visibility : AppIcons.visibilityOff,
        size: 20,
        color: color,
      ),
      onPressed: onToggle,
    );
  }
}

/// Headline block for auth forms.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: text,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
