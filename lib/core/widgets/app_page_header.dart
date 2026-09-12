import 'package:flutter/material.dart';

import 'premium/premium_page.dart';

/// Flat page header — aliases [PremiumPageHeader] so leftover screens match.
class AppPageHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppPageHeader({
    required this.title,
    this.action,
    this.showBackButton = false,
    this.onBack,
    super.key,
  });

  static const double horizontalPadding = PremiumPageHeader.horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return PremiumPageHeader(
      title: title,
      action: action,
      showBackButton: showBackButton,
      onBack: onBack,
    );
  }
}
