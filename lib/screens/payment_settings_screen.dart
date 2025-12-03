// Screen: Payment Settings Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../core/providers/feature_flags_provider.dart';
import '../features/payments/providers/google_play_billing_provider.dart';

/// Payment Settings Screen - Configure payment systems and features
class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Payment Settings',
        showBackButton: true,
      ),
      body: ListView(
        children: [
          // Payment Systems Section
          SectionHeader(
            title: 'Payment Systems',
            icon: Icons.payment,
          ),

          // Google Play Billing Toggle
          _buildFeatureToggle(
            context: context,
            title: 'Google Play Billing',
            subtitle: 'Use Google Play for secure in-app purchases (Recommended for Android)',
            featureKey: 'google_play_billing',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          // Stripe Payments Toggle
          _buildFeatureToggle(
            context: context,
            title: 'Stripe Payments',
            subtitle: 'Use Stripe for web-based payments (Fallback option)',
            featureKey: 'stripe_payments',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          DividerCustom(),

          // Features Section
          SectionHeader(
            title: 'Features',
            icon: Icons.settings,
          ),

          // Offline Mode Toggle
          _buildFeatureToggle(
            context: context,
            title: 'Offline Mode',
            subtitle: 'Queue purchases when offline and process when connected',
            featureKey: 'offline_mode',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          // Purchase Restoration Toggle
          _buildFeatureToggle(
            context: context,
            title: 'Purchase Restoration',
            subtitle: 'Automatically restore purchases on app reinstall',
            featureKey: 'purchase_restoration',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          DividerCustom(),

          // Status Section
          SectionHeader(
            title: 'Status',
            icon: Icons.info,
          ),

          // Current Payment System
          _buildStatusCard(
            title: 'Active Payment System',
            content: Consumer(
              builder: (context, ref, child) {
                final paymentSystem = ref.watch(activePaymentSystemProvider);
                return Text(
                  paymentSystem.displayName,
                  style: AppTypography.body.copyWith(
                    color: paymentSystem.isAvailable ? AppColors.onlineGreen : AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          // Billing Availability
          _buildStatusCard(
            title: 'Google Play Billing',
            content: Consumer(
              builder: (context, ref, child) {
                final billingAsync = ref.watch(billingAvailabilityProvider);
                return billingAsync.when(
                  data: (isAvailable) => Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: isAvailable ? AppColors.onlineGreen : AppColors.accentRed,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Text(
                        isAvailable ? 'Available' : 'Not Available',
                        style: AppTypography.body.copyWith(
                          color: isAvailable ? AppColors.onlineGreen : AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) => Text(
                    'Error checking',
                    style: AppTypography.body.copyWith(color: AppColors.accentRed),
                  ),
                );
              },
            ),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          // Pending Purchases
          _buildStatusCard(
            title: 'Pending Purchases',
            content: Consumer(
              builder: (context, ref, child) {
                final pendingAsync = ref.watch(pendingPurchasesCountProvider);
                return pendingAsync.when(
                  data: (count) => Text(
                    '$count pending',
                    style: AppTypography.body.copyWith(
                      color: count > 0 ? AppColors.accentYellow : AppColors.onlineGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) => Text(
                    'Error',
                    style: AppTypography.body.copyWith(color: AppColors.accentRed),
                  ),
                );
              },
            ),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),

          SizedBox(height: AppSpacing.spacingXXL),

          // Reset Settings Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            child: OutlinedButton(
              onPressed: _showResetConfirmation,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentRed),
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                ),
              ),
              child: Text(
                'Reset to Defaults',
                style: AppTypography.button.copyWith(color: AppColors.accentRed),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.spacingLG),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String featureKey,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final featureNotifier = ref.watch(featureFlagNotifierProvider);
        final isEnabled = featureNotifier[featureKey] ?? false;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingLG,
            vertical: AppSpacing.spacingSM,
          ),
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      subtitle,
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  ref.read(featureFlagNotifierProvider.notifier).setFeatureFlag(featureKey, value);
                  _showFeatureToggleSnackBar(title, value);
                },
                activeColor: AppColors.accentPurple,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard({
    required String title,
    required Widget content,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingSM,
      ),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content,
        ],
      ),
    );
  }

  void _showFeatureToggleSnackBar(String featureName, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$featureName ${enabled ? 'enabled' : 'disabled'}',
        ),
        backgroundColor: enabled ? AppColors.onlineGreen : AppColors.accentYellow,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all payment settings to their default values. '
          'Pending purchases may be lost. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    // Reset all feature flags to defaults
    final featureFlags = ref.read(featureFlagsProvider);
    final defaults = featureFlags.getAllFeatureFlags();
    final featureNotifier = ref.read(featureFlagNotifierProvider.notifier);

    defaults.forEach((key, value) {
      featureNotifier.setFeatureFlag(key, value);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: AppColors.onlineGreen,
      ),
    );
  }
}
