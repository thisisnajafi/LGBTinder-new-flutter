// Screen: PrivacySettingsScreen (Task 6 — discovery visibility bound to PUT /api/preferences/matching)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/modals/confirmation_dialog.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/settings/data/models/matching_preferences.dart';

/// Privacy settings screen - Manage privacy and visibility settings
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  // Profile visibility
  bool _showProfile = true;
  bool _showAge = true;
  bool _showDistance = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  String _profileVisibility = 'everyone'; // 'everyone', 'matches', 'premium'

  // Discovery visibility (Task 6 — persisted via GET/PUT /api/preferences/matching)
  String _discoveryVisibility = 'everyone'; // 'everyone' | 'people_i_like' | 'hidden'
  bool _discoveryVisibilitySaving = false;

  // Discovery (local / not yet backed by API)
  bool _showInDiscovery = true;
  bool _showInTopPicks = true;
  bool _allowSwipeBack = false;

  // Data sharing
  bool _shareDataForMatching = true;
  bool _shareDataForAnalytics = false;
  bool _shareDataForAds = false;

  // Blocking
  bool _blockMessagesFromNonMatches = false;
  bool _hideProfileFromBlocked = true;

  // Activity status
  bool _showActiveStatus = true;
  bool _showReadReceipts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDiscoveryVisibility());
  }

  Future<void> _loadDiscoveryVisibility() async {
    try {
      final prefs = await ref.read(matchingPreferencesProvider.future);
      if (mounted) {
        setState(() {
          _discoveryVisibility = prefs.discoveryVisibility;
          _showInDiscovery = prefs.discoveryVisibility != 'hidden';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDiscoveryVisibility(String value) async {
    setState(() => _discoveryVisibilitySaving = true);
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      final current = await ref.read(matchingPreferencesProvider.future);
      await service.updatePreferences(current.copyWith(discoveryVisibility: value));
      ref.invalidate(matchingPreferencesProvider);
      ref.invalidate(settingsSummaryProvider);
      if (mounted) setState(() {
        _discoveryVisibility = value;
        _discoveryVisibilitySaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discovery visibility updated')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _discoveryVisibilitySaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

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
        title: 'Privacy',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Profile visibility
          SectionHeader(
            title: 'Profile Visibility',
            icon: Icons.visibility,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Show My Profile',
            subtitle: 'Allow others to see your profile',
            value: _showProfile,
            onChanged: (value) {
              setState(() {
                _showProfile = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Show Age',
            subtitle: 'Display your age on profile',
            value: _showAge,
            onChanged: (value) {
              setState(() {
                _showAge = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Show Distance',
            subtitle: 'Display distance to other users',
            value: _showDistance,
            onChanged: (value) {
              setState(() {
                _showDistance = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Show Online Status',
            subtitle: 'Let others see when you\'re online',
            value: _showOnlineStatus,
            onChanged: (value) {
              setState(() {
                _showOnlineStatus = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Show Last Seen',
            subtitle: 'Display when you were last active',
            value: _showLastSeen,
            onChanged: (value) {
              setState(() {
                _showLastSeen = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSelectorTile(
            title: 'Who Can See My Profile',
            subtitle: 'Control who can view your profile',
            value: _profileVisibility,
            options: [
              {'value': 'everyone', 'label': 'Everyone'},
              {'value': 'matches', 'label': 'Matches Only'},
              {'value': 'premium', 'label': 'Premium Users Only'},
            ],
            onChanged: (value) {
              setState(() {
                _profileVisibility = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Discovery visibility (Task 6 — backed by PUT /api/preferences/matching)
          SectionHeader(
            title: 'Discovery visibility',
            icon: Icons.explore,
          ),
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            'Who can see your profile in discovery. Hidden means fewer matches.',
            style: AppTypography.caption.copyWith(color: secondaryTextColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSelectorTile(
            title: 'Who can see you',
            subtitle: _discoveryVisibilitySaving ? 'Saving…' : null,
            value: _discoveryVisibility,
            options: [
              {'value': 'everyone', 'label': 'Everyone'},
              {'value': 'people_i_like', 'label': 'Only people I\'ve liked'},
              {'value': 'hidden', 'label': 'Hidden from discovery'},
            ],
            onChanged: _discoveryVisibilitySaving
                ? (_) {}
                : (value) => _saveDiscoveryVisibility(value),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Discovery (other toggles — local only for now)
          SectionHeader(
            title: 'Discovery',
            icon: Icons.explore,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Show Me in Discovery',
            subtitle: 'Allow others to find you (synced with option above when Everyone)',
            value: _showInDiscovery,
            onChanged: (value) {
              setState(() {
                _showInDiscovery = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Show Me in Top Picks',
            subtitle: 'Appear in curated top picks',
            value: _showInTopPicks,
            onChanged: (value) {
              setState(() {
                _showInTopPicks = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Allow Swipe Back',
            subtitle: 'Let others undo swipes on you',
            value: _allowSwipeBack,
            onChanged: (value) {
              setState(() {
                _allowSwipeBack = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Data sharing
          SectionHeader(
            title: 'Data Sharing',
            icon: Icons.share,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Share Data for Matching',
            subtitle: 'Use your data to improve matches',
            value: _shareDataForMatching,
            onChanged: (value) {
              setState(() {
                _shareDataForMatching = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Share Data for Analytics',
            subtitle: 'Help us improve the app',
            value: _shareDataForAnalytics,
            onChanged: (value) {
              setState(() {
                _shareDataForAnalytics = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Share Data for Ads',
            subtitle: 'Personalized advertising',
            value: _shareDataForAds,
            onChanged: (value) {
              setState(() {
                _shareDataForAds = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Messaging privacy
          SectionHeader(
            title: 'Messaging Privacy',
            icon: Icons.chat_bubble,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Block Messages from Non-Matches',
            subtitle: 'Only receive messages from matches',
            value: _blockMessagesFromNonMatches,
            onChanged: (value) {
              setState(() {
                _blockMessagesFromNonMatches = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Show Read Receipts',
            subtitle: 'Let others know when you read messages',
            value: _showReadReceipts,
            onChanged: (value) {
              setState(() {
                _showReadReceipts = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTile({
    required String title,
    String? subtitle,
    required String value,
    required List<Map<String, String>> options,
    required Function(String) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.spacingMD),
          ...options.map((option) {
            final isSelected = value == option['value'];
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
              child: GestureDetector(
                onTap: () => onChanged(option['value']!),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPurple.withOpacity(0.2)
                        : backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: AppTypography.body.copyWith(
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.accentPurple,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
