import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';
import 'premium/premium_design_system.dart';

/// Pushed-page shell with the same header and bounce-scroll chrome as Messenger.
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
  final RefreshCallback? onRefresh;

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
    this.onRefresh,
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
    return PremiumDetailScaffold(
      title: title,
      action: action,
      showBackButton: showBackButton,
      onBack: showBackButton ? (onBack ?? () => defaultBack(context)) : null,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      onRefresh: onRefresh,
      body: expandBody
          ? body
          : ListView(
              physics: AppScroll.bouncing,
              children: [body],
            ),
    );
  }
}
