import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';
import '../../routes/app_router.dart';
import 'app_page_header.dart';

/// Flat scaffold shell — SafeArea, [AppPageHeader], and body (REF-05).
class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool expandBody;

  const AppPageScaffold({
    required this.title,
    required this.body,
    this.action,
    this.showBackButton = false,
    this.onBack,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.expandBody = true,
    super.key,
  });

  static void defaultBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    final content = expandBody ? Expanded(child: body) : body;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: title,
              action: action,
              showBackButton: showBackButton,
              onBack: onBack ?? () => defaultBack(context),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            content,
          ],
        ),
      ),
    );
  }
}
