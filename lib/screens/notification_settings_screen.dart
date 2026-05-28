import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_settings_detail.dart';

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

  AppGroupedSwitchTile _switch({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return AppGroupedSwitchTile(
      label: label,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      showDivider: showDivider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Notifications',
      body: AppSettingsDetailList(
        children: [
          AppGroupedListSection(
            title: 'Push notifications',
            padding: AppSettingsLayout.firstSectionPadding,
            children: [
              _switch(
                label: 'Enable push notifications',
                subtitle: 'Receive notifications on your device',
                value: _pushEnabled,
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
              if (_pushEnabled) ...[
                _switch(
                  label: 'New matches',
                  subtitle: 'When someone likes you back',
                  value: _newMatches,
                  onChanged: (v) => setState(() => _newMatches = v),
                ),
                _switch(
                  label: 'New messages',
                  subtitle: 'When you receive a message',
                  value: _newMessages,
                  onChanged: (v) => setState(() => _newMessages = v),
                ),
                _switch(
                  label: 'Message likes',
                  subtitle: 'When someone likes your message',
                  value: _messageLikes,
                  onChanged: (v) => setState(() => _messageLikes = v),
                ),
                _switch(
                  label: 'Superlikes',
                  subtitle: 'When someone superlikes you',
                  value: _superlikes,
                  onChanged: (v) => setState(() => _superlikes = v),
                ),
                _switch(
                  label: 'Top picks',
                  subtitle: 'Daily top picks for you',
                  value: _topPicks,
                  onChanged: (v) => setState(() => _topPicks = v),
                ),
                _switch(
                  label: 'Boosts',
                  subtitle: 'Boost reminders and updates',
                  value: _boosts,
                  onChanged: (v) => setState(() => _boosts = v),
                ),
                _switch(
                  label: 'Profile views',
                  subtitle: 'When someone views your profile',
                  value: _profileViews,
                  onChanged: (v) => setState(() => _profileViews = v),
                ),
                _switch(
                  label: 'Likes',
                  subtitle: 'When someone likes you',
                  value: _likes,
                  onChanged: (v) => setState(() => _likes = v),
                  showDivider: false,
                ),
              ],
            ],
          ),
          AppGroupedListSection(
            title: 'Email notifications',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              _switch(
                label: 'Enable email notifications',
                subtitle: 'Receive notifications via email',
                value: _emailEnabled,
                onChanged: (v) => setState(() => _emailEnabled = v),
              ),
              if (_emailEnabled) ...[
                _switch(
                  label: 'New matches',
                  subtitle: 'Email when you get a new match',
                  value: _emailMatches,
                  onChanged: (v) => setState(() => _emailMatches = v),
                ),
                _switch(
                  label: 'New messages',
                  subtitle: 'Email when you receive messages',
                  value: _emailMessages,
                  onChanged: (v) => setState(() => _emailMessages = v),
                ),
                _switch(
                  label: 'Promotions',
                  subtitle: 'Special offers and promotions',
                  value: _emailPromotions,
                  onChanged: (v) => setState(() => _emailPromotions = v),
                ),
                _switch(
                  label: 'Updates',
                  subtitle: 'App updates and news',
                  value: _emailUpdates,
                  onChanged: (v) => setState(() => _emailUpdates = v),
                  showDivider: false,
                ),
              ],
            ],
          ),
          AppGroupedListSection(
            title: 'Sound & vibration',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              _switch(
                label: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _soundEnabled,
                onChanged: (v) => setState(() => _soundEnabled = v),
              ),
              _switch(
                label: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: _vibrationEnabled,
                onChanged: (v) => setState(() => _vibrationEnabled = v),
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
