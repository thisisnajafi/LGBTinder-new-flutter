// Screen: SafetyCenterScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/buttons/gradient_button.dart';
import 'nearby_safe_places_screen.dart';
import 'blocked_users_screen.dart';
import 'report_history_screen.dart';
import 'emergency_contacts_screen.dart';

/// Safety center screen - Safety tools and resources
class SafetyCenterScreen extends ConsumerWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppSettingsDetailScaffold(
      title: 'Safety center',
      subtitle: 'Tools and resources to help you stay safe',
      body: AppSettingsDetailList(
        children: [
          PremiumShell(
            child: Column(
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.shieldTick,
                  size: 48,
                  color: AppColors.accentViolet,
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Your safety matters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'We\'re here to help you stay safe while connecting',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Quick actions',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.block,
                title: 'Blocked users',
                subtitle: 'View and manage blocked users',
                accent: AppColors.feedbackError,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BlockedUsersScreen(),
                    ),
                  );
                },
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.report,
                title: 'Report history',
                subtitle: 'View your reports and their status',
                accent: AppColors.feedbackWarning,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportHistoryScreen(),
                    ),
                  );
                },
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.location,
                title: 'Nearby safe places',
                subtitle: 'Hospitals, police, and fire stations near you',
                accent: AppColors.feedbackInfo,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NearbySafePlacesScreen(),
                    ),
                  );
                },
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.call,
                title: 'Emergency contacts',
                subtitle: 'Add trusted contacts for emergencies',
                accent: AppColors.feedbackSuccess,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EmergencyContactsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Safety tips',
            children: [
              for (final tip in const [
                'Never share personal information like your address or financial details',
                'Meet in public places for first dates and let someone know where you\'re going',
                'Trust your instincts — if something feels off, it probably is',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.tickCircle,
                        size: 18,
                        color: AppColors.feedbackSuccess,
                      ),
                      const SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Text(
                          tip,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSettingsLayout.horizontalPadding,
              AppSpacing.spacingXL,
              AppSettingsLayout.horizontalPadding,
              0,
            ),
            child: GradientButton(
              text: 'Report a problem',
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Report a problem',
                      style: theme.textTheme.headlineSmall,
                    ),
                    content: Text(
                      'For reporting specific users or content, use the report buttons in the app. For general issues, contact our support team.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support contact feature coming soon'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Contact support'),
                      ),
                    ],
                  ),
                );
              },
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
