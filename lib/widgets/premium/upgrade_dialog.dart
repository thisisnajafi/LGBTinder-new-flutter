import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Upgrade Dialog
/// 
/// Shows a beautiful dialog prompting user to upgrade to premium
class UpgradeDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String> features;
  final VoidCallback? onUpgrade;
  final String? limitInfo;

  const UpgradeDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.features,
    this.onUpgrade,
    this.limitInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPurple,
                    AppColors.primaryLight,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            // Limit info (if provided)
            if (limitInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.backgroundDark.withOpacity(0.5)
                      : AppColors.backgroundLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.accentPurple,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        limitInfo!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Features
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.feedbackSuccess,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onUpgrade != null) {
                    onUpgrade!();
                  } else {
                    context.push('/subscription-plans');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Upgrade to Premium',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Maybe Later Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show swipe limit dialog
  static void showSwipeLimitDialog(BuildContext context, int used, int limit) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        title: 'Daily Swipe Limit Reached',
        message: 'You\'ve used all your free swipes for today!',
        limitInfo: 'Used: $used/$limit swipes',
        features: const [
          'Unlimited daily swipes',
          '5 superlikes per day',
          'See who liked you',
          'Advanced filters',
          'Rewind last swipe',
          'Ad-free experience',
        ],
      ),
    );
  }

  /// Show superlike limit dialog
  static void showSuperlikeLimitDialog(BuildContext context, int used, int limit) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        title: 'Superlike Limit Reached',
        message: 'You\'ve used all your free superlikes for today!',
        limitInfo: 'Used: $used/$limit superlikes',
        features: const [
          '5 superlikes per day',
          'Unlimited daily swipes',
          'See who liked you',
          'Stand out with priority likes',
          'Advanced filters',
          'Boost your profile',
        ],
      ),
    );
  }

  /// Show message limit dialog
  static void showMessageLimitDialog(BuildContext context, int current, int limit) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        title: 'Conversation Limit Reached',
        message: 'You can only have $limit active conversations on the free plan.',
        limitInfo: 'Active conversations: $current/$limit',
        features: const [
          'Unlimited conversations',
          'Read receipts',
          'Video & voice calls',
          'Priority message delivery',
          'Message reactions',
          'Send photos & videos',
        ],
      ),
    );
  }

  /// Show feature locked dialog
  static void showFeatureLockedDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => UpgradeDialog(
        title: 'Premium Feature',
        message: '$featureName is a premium feature.',
        features: const [
          'Advanced filters',
          'See who liked you',
          'Rewind last swipe',
          'Passport mode',
          'Boost your profile',
          'Incognito browsing',
        ],
      ),
    );
  }
}

