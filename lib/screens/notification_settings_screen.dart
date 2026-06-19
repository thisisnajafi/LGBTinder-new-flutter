import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Notification settings screen - Manage notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _newMatches = true;
  bool _newMessages = true;
  bool _messageLikes = true;
  bool _superlikes = true;
  bool _topPicks = false;
  bool _boosts = false;
  bool _profileViews = true;
  bool _likes = true;

  bool _emailEnabled = true;
  bool _emailMatches = false;
  bool _emailMessages = false;
  bool _emailPromotions = true;
  bool _emailUpdates = true;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  Widget _premiumToggle({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? iconPath,
  }) {
    return PremiumToggleRow(
      title: label,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      iconPath: iconPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Notifications',
      subtitle: 'Choose what reaches you and how',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Push notifications',
            subtitle: 'Alerts on this device',
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            children: [
              _premiumToggle(
                label: 'Enable push notifications',
                subtitle: 'Receive notifications on your device',
                value: _pushEnabled,
                iconPath: AppIcons.notification,
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
              if (_pushEnabled) ...[
                _premiumToggle(
                  label: 'New matches',
                  subtitle: 'When someone likes you back',
                  value: _newMatches,
                  iconPath: AppIcons.heart,
                  onChanged: (v) => setState(() => _newMatches = v),
                ),
                _premiumToggle(
                  label: 'New messages',
                  subtitle: 'When you receive a message',
                  value: _newMessages,
                  iconPath: AppIcons.message,
                  onChanged: (v) => setState(() => _newMessages = v),
                ),
                _premiumToggle(
                  label: 'Message likes',
                  subtitle: 'When someone likes your message',
                  value: _messageLikes,
                  iconPath: AppIcons.like,
                  onChanged: (v) => setState(() => _messageLikes = v),
                ),
                _premiumToggle(
                  label: 'Superlikes',
                  subtitle: 'When someone superlikes you',
                  value: _superlikes,
                  iconPath: AppIcons.getIconPath('star'),
                  onChanged: (v) => setState(() => _superlikes = v),
                ),
                _premiumToggle(
                  label: 'Top picks',
                  subtitle: 'Daily top picks for you',
                  value: _topPicks,
                  iconPath: AppIcons.crown,
                  onChanged: (v) => setState(() => _topPicks = v),
                ),
                _premiumToggle(
                  label: 'Boosts',
                  subtitle: 'Boost reminders and updates',
                  value: _boosts,
                  iconPath: AppIcons.getIconPath('flash'),
                  onChanged: (v) => setState(() => _boosts = v),
                ),
                _premiumToggle(
                  label: 'Profile views',
                  subtitle: 'When someone views your profile',
                  value: _profileViews,
                  iconPath: AppIcons.eye,
                  onChanged: (v) => setState(() => _profileViews = v),
                ),
                _premiumToggle(
                  label: 'Likes',
                  subtitle: 'When someone likes you',
                  value: _likes,
                  iconPath: AppIcons.like1,
                  onChanged: (v) => setState(() => _likes = v),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Email notifications',
            subtitle: 'Updates in your inbox',
            children: [
              _premiumToggle(
                label: 'Enable email notifications',
                subtitle: 'Receive notifications via email',
                value: _emailEnabled,
                iconPath: AppIcons.email,
                onChanged: (v) => setState(() => _emailEnabled = v),
              ),
              if (_emailEnabled) ...[
                _premiumToggle(
                  label: 'New matches',
                  subtitle: 'Email when you get a new match',
                  value: _emailMatches,
                  iconPath: AppIcons.heart,
                  onChanged: (v) => setState(() => _emailMatches = v),
                ),
                _premiumToggle(
                  label: 'New messages',
                  subtitle: 'Email when you receive messages',
                  value: _emailMessages,
                  iconPath: AppIcons.message,
                  onChanged: (v) => setState(() => _emailMessages = v),
                ),
                _premiumToggle(
                  label: 'Promotions',
                  subtitle: 'Special offers and promotions',
                  value: _emailPromotions,
                  iconPath: AppIcons.getIconPath('gift'),
                  onChanged: (v) => setState(() => _emailPromotions = v),
                ),
                _premiumToggle(
                  label: 'Updates',
                  subtitle: 'App updates and news',
                  value: _emailUpdates,
                  iconPath: AppIcons.getIconPath('info-circle'),
                  onChanged: (v) => setState(() => _emailUpdates = v),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Sound & vibration',
            children: [
              _premiumToggle(
                label: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _soundEnabled,
                iconPath: AppIcons.getIconPath('speaker'),
                onChanged: (v) => setState(() => _soundEnabled = v),
              ),
              _premiumToggle(
                label: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: _vibrationEnabled,
                iconPath: AppIcons.getIconPath('mobile'),
                onChanged: (v) => setState(() => _vibrationEnabled = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
