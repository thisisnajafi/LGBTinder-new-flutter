// Screen: Payment Settings Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/providers/feature_flags_provider.dart';
import '../features/payments/providers/google_play_billing_provider.dart';

/// Payment Settings Screen - Configure payment systems and features
class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() =>
      _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Payment settings',
      subtitle: 'Billing systems, features, and status',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Payment systems',
            children: [
              _FeatureToggleRow(
                title: 'Google Play Billing',
                subtitle:
                    'Use Google Play for secure in-app purchases (recommended on Android)',
                featureKey: 'google_play_billing',
                iconPath: AppIcons.playCircle,
                onToggled: _showFeatureToggleSnackBar,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Features',
            children: [
              _FeatureToggleRow(
                title: 'Offline mode',
                subtitle:
                    'Queue purchases when offline and process when connected',
                featureKey: 'offline_mode',
                iconPath: AppIcons.cloudConnection,
                onToggled: _showFeatureToggleSnackBar,
              ),
              _FeatureToggleRow(
                title: 'Purchase restoration',
                subtitle: 'Automatically restore purchases on app reinstall',
                featureKey: 'purchase_restoration',
                iconPath: AppIcons.refreshCircle,
                onToggled: _showFeatureToggleSnackBar,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Status',
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final paymentSystem = ref.watch(activePaymentSystemProvider);
                  return PremiumInfoRow(
                    label: 'Active payment system',
                    value: paymentSystem.displayName,
                    badge: paymentSystem.isAvailable ? 'Active' : 'Unavailable',
                    badgeColor: paymentSystem.isAvailable
                        ? AppColors.onlineGreen
                        : AppColors.feedbackError,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final billingAsync = ref.watch(billingAvailabilityProvider);
                  return billingAsync.when(
                    data: (isAvailable) => PremiumInfoRow(
                      label: 'Google Play Billing',
                      value: isAvailable ? 'Available' : 'Not available',
                      badge: isAvailable ? 'Ready' : 'Unavailable',
                      badgeColor: isAvailable
                          ? AppColors.onlineGreen
                          : AppColors.feedbackError,
                    ),
                    loading: () => const _PaymentStatusLoadingRow(
                      label: 'Google Play Billing',
                    ),
                    error: (_, __) => const PremiumInfoRow(
                      label: 'Google Play Billing',
                      value: 'Error checking',
                      badge: 'Error',
                      badgeColor: AppColors.feedbackError,
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final pendingAsync = ref.watch(pendingPurchasesCountProvider);
                  return pendingAsync.when(
                    data: (count) => PremiumInfoRow(
                      label: 'Pending purchases',
                      value: count == 0 ? 'None' : '$count pending',
                      badge: count > 0 ? 'Action needed' : 'Clear',
                      badgeColor: count > 0
                          ? AppColors.feedbackWarning
                          : AppColors.onlineGreen,
                    ),
                    loading: () => const _PaymentStatusLoadingRow(
                      label: 'Pending purchases',
                    ),
                    error: (_, __) => const PremiumInfoRow(
                      label: 'Pending purchases',
                      value: 'Error',
                      badge: 'Error',
                      badgeColor: AppColors.feedbackError,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Reset',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.refreshLeft,
                title: 'Reset to defaults',
                subtitle: 'Restore all payment settings to their default values',
                destructive: true,
                onTap: _showResetConfirmation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeatureToggleSnackBar(String featureName, bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName ${enabled ? 'enabled' : 'disabled'}'),
        backgroundColor:
            enabled ? AppColors.onlineGreen : AppColors.feedbackWarning,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings'),
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.feedbackError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
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

class _FeatureToggleRow extends ConsumerWidget {
  const _FeatureToggleRow({
    required this.title,
    required this.subtitle,
    required this.featureKey,
    required this.iconPath,
    required this.onToggled,
  });

  final String title;
  final String subtitle;
  final String featureKey;
  final String iconPath;
  final void Function(String featureName, bool enabled) onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureNotifier = ref.watch(featureFlagNotifierProvider);
    final isEnabled = featureNotifier[featureKey] ?? false;

    return PremiumToggleRow(
      title: title,
      subtitle: subtitle,
      value: isEnabled,
      iconPath: iconPath,
      onChanged: (value) {
        ref.read(featureFlagNotifierProvider.notifier).setFeatureFlag(
              featureKey,
              value,
            );
        onToggled(title, value);
      },
    );
  }
}

class _PaymentStatusLoadingRow extends StatelessWidget {
  const _PaymentStatusLoadingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}
