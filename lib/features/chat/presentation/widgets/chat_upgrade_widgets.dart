import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../../routes/app_router.dart';

/// Full-screen chat image viewer with pinch-to-zoom.
class ChatImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const ChatImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  static void open(BuildContext context, {required String imageUrl, String? heroTag}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ChatImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = PhotoView(
      imageProvider: NetworkImage(imageUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CloseButton(color: AppColors.textPrimaryDark),
      ),
      body: heroTag != null
          ? Hero(tag: heroTag!, child: image)
          : image,
    );
  }
}

/// Upgrade CTA when basid daily send limit is reached.
class ChatUpgradeBottomSheet extends StatelessWidget {
  const ChatUpgradeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppActionBottomSheet.show<void>(
      context: context,
      showCancel: false,
      body: const ChatUpgradeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBottomSheetCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.lockCircle,
              size: 48,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Text(
              'Daily message limit reached',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Upgrade to silder or golden to send unlimited messages in this chat.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            Semantics(
              label: 'View subscription plans',
              button: true,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.subscriptionPlans);
                  },
                  child: const Text('View plans'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dismissible premium upgrade banner for basid users on chat list.
class ChatPremiumBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onUpgrade;

  const ChatPremiumBanner({
    super.key,
    required this.onDismiss,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Upgrade to unlock unlimited chat messages',
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.15),
              AppColors.secondaryLight.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            AppSvgIcon(
              assetPath: AppIcons.crown,
              size: 28,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock full chat access',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'See all messages and send without daily limits.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onUpgrade, child: const Text('Upgrade')),
            IconButton(
              onPressed: onDismiss,
              icon: AppSvgIcon(
                assetPath: AppIcons.close,
                size: 18,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
