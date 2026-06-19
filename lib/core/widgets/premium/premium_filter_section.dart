import 'package:flutter/material.dart';

import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import 'premium_shell.dart';

/// Glass-wrapped filter group for the discovery filter screen.
class PremiumFilterSection extends StatelessWidget {
  const PremiumFilterSection({
    super.key,
    required this.iconPath,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final String iconPath;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: PremiumShell(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PremiumSectionHeader(
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            child,
          ],
        ),
      ),
    );
  }
}
