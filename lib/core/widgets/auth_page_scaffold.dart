import 'package:flutter/material.dart';

import '../navigation/auth_navigation.dart';
import '../theme/app_colors.dart';
import 'premium/premium_page.dart';

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
