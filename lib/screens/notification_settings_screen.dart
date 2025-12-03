// Screen: NotificationSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Notification settings screen - Manage notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  // Push notifications
  bool _pushEnabled = true;
  bool _newMatches = true;
  bool _newMessages = true;
  bool _messageLikes = true;
  bool _superlikes = true;
  bool _topPicks = false;
  bool _boosts = false;
  bool _profileViews = true;
  bool _likes = true;

  // Email notifications
  bool _emailEnabled = true;
  bool _emailMatches = false;
  bool _emailMessages = false;
  bool _emailPromotions = true;
  bool _emailUpdates = true;

  // In-app notifications
  bool _inAppEnabled = true;
  bool _inAppMatches = true;
  bool _inAppMessages = true;
  bool _inAppLikes = true;

  // Sound & vibration
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _soundType = 'default';

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
        title: 'Notifications',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Push notifications
          SectionHeader(
            title: 'Push Notifications',
            icon: Icons.notifications,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: _pushEnabled,
            onChanged: (value) {
              setState(() {
                _pushEnabled = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_pushEnabled) ...[
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'New Matches',
              subtitle: 'When someone likes you back',
              value: _newMatches,
              onChanged: (value) {
                setState(() {
                  _newMatches = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'New Messages',
              subtitle: 'When you receive a message',
              value: _newMessages,
              onChanged: (value) {
                setState(() {
                  _newMessages = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Message Likes',
              subtitle: 'When someone likes your message',
              value: _messageLikes,
              onChanged: (value) {
                setState(() {
                  _messageLikes = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Superlikes',
              subtitle: 'When someone superlikes you',
              value: _superlikes,
              onChanged: (value) {
                setState(() {
                  _superlikes = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Top Picks',
              subtitle: 'Daily top picks for you',
              value: _topPicks,
              onChanged: (value) {
                setState(() {
                  _topPicks = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Boosts',
              subtitle: 'Boost reminders and updates',
              value: _boosts,
              onChanged: (value) {
                setState(() {
                  _boosts = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Profile Views',
              subtitle: 'When someone views your profile',
              value: _profileViews,
              onChanged: (value) {
                setState(() {
                  _profileViews = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Likes',
              subtitle: 'When someone likes you',
              value: _likes,
              onChanged: (value) {
                setState(() {
                  _likes = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Email notifications
          SectionHeader(
            title: 'Email Notifications',
            icon: Icons.email,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailEnabled,
            onChanged: (value) {
              setState(() {
                _emailEnabled = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_emailEnabled) ...[
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'New Matches',
              subtitle: 'Email when you get a new match',
              value: _emailMatches,
              onChanged: (value) {
                setState(() {
                  _emailMatches = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'New Messages',
              subtitle: 'Email when you receive messages',
              value: _emailMessages,
              onChanged: (value) {
                setState(() {
                  _emailMessages = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Promotions',
              subtitle: 'Special offers and promotions',
              value: _emailPromotions,
              onChanged: (value) {
                setState(() {
                  _emailPromotions = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Updates',
              subtitle: 'App updates and news',
              value: _emailUpdates,
              onChanged: (value) {
                setState(() {
                  _emailUpdates = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Sound & vibration
          SectionHeader(
            title: 'Sound & Vibration',
            icon: Icons.volume_up,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
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
}
