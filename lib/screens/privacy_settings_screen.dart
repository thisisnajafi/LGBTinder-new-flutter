import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_settings_detail.dart';
import '../features/settings/providers/settings_provider.dart';

/// Privacy settings screen - Manage privacy and visibility settings
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _showProfile = true;
  bool _showAge = true;
  bool _showDistance = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  String _profileVisibility = 'everyone';

  String _discoveryVisibility = 'everyone';
  bool _discoveryVisibilitySaving = false;

  bool _showInDiscovery = true;
  bool _showInTopPicks = true;
  bool _allowSwipeBack = false;

  bool _shareDataForMatching = true;
  bool _shareDataForAnalytics = false;
  bool _shareDataForAds = false;

  bool _blockMessagesFromNonMatches = false;
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
    } catch (e) {
      AppLogger.warning(
        'Silently caught exception',
        tag: 'privacy_settings_screen',
        error: e,
      );
    }
  }

  Future<void> _saveDiscoveryVisibility(String value) async {
    setState(() => _discoveryVisibilitySaving = true);
    try {
      final service = ref.read(matchingPreferencesServiceProvider);
      final current = await ref.read(matchingPreferencesProvider.future);
      await service.updatePreferences(
        current.copyWith(discoveryVisibility: value),
      );
      ref.invalidate(matchingPreferencesProvider);
      ref.invalidate(settingsSummaryProvider);
      if (mounted) {
        setState(() {
          _discoveryVisibility = value;
          _discoveryVisibilitySaving = false;
        });
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
      title: 'Privacy & safety',
      body: AppSettingsDetailList(
        children: [
          AppGroupedListSection(
            title: 'Profile visibility',
            padding: AppSettingsLayout.firstSectionPadding,
            children: [
              _switch(
                label: 'Show my profile',
                subtitle: 'Allow others to see your profile',
                value: _showProfile,
                onChanged: (v) => setState(() => _showProfile = v),
              ),
              _switch(
                label: 'Show age',
                subtitle: 'Display your age on profile',
                value: _showAge,
                onChanged: (v) => setState(() => _showAge = v),
              ),
              _switch(
                label: 'Show distance',
                subtitle: 'Display distance to other users',
                value: _showDistance,
                onChanged: (v) => setState(() => _showDistance = v),
              ),
              _switch(
                label: 'Show online status',
                subtitle: 'Let others see when you\'re online',
                value: _showOnlineStatus,
                onChanged: (v) => setState(() => _showOnlineStatus = v),
              ),
              _switch(
                label: 'Show last seen',
                subtitle: 'Display when you were last active',
                value: _showLastSeen,
                onChanged: (v) => setState(() => _showLastSeen = v),
                showDivider: false,
              ),
            ],
          ),
          AppSettingsOptionSection(
            title: 'Who can see my profile',
            padding: AppSettingsLayout.sectionPadding,
            value: _profileVisibility,
            onChanged: (v) => setState(() => _profileVisibility = v),
            options: const [
              MapEntry('everyone', 'Everyone'),
              MapEntry('matches', 'Matches only'),
              MapEntry('premium', 'Premium users only'),
            ],
          ),
          AppSettingsOptionSection(
            title: 'Discovery visibility',
            padding: AppSettingsLayout.sectionPadding,
            footnote:
                'Who can see your profile in discovery. Hidden means fewer matches.',
            value: _discoveryVisibility,
            onChanged: _discoveryVisibilitySaving
                ? null
                : _saveDiscoveryVisibility,
            options: const [
              MapEntry('everyone', 'Everyone'),
              MapEntry('people_i_like', 'Only people I\'ve liked'),
              MapEntry('hidden', 'Hidden from discovery'),
            ],
          ),
          AppGroupedListSection(
            title: 'Discovery',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              _switch(
                label: 'Show me in discovery',
                subtitle:
                    'Allow others to find you (synced with option above when Everyone)',
                value: _showInDiscovery,
                onChanged: (v) => setState(() => _showInDiscovery = v),
              ),
              _switch(
                label: 'Show me in top picks',
                subtitle: 'Appear in curated top picks',
                value: _showInTopPicks,
                onChanged: (v) => setState(() => _showInTopPicks = v),
              ),
              _switch(
                label: 'Allow swipe back',
                subtitle: 'Let others undo swipes on you',
                value: _allowSwipeBack,
                onChanged: (v) => setState(() => _allowSwipeBack = v),
                showDivider: false,
              ),
            ],
          ),
          AppGroupedListSection(
            title: 'Data sharing',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              _switch(
                label: 'Share data for matching',
                subtitle: 'Use your data to improve matches',
                value: _shareDataForMatching,
                onChanged: (v) => setState(() => _shareDataForMatching = v),
              ),
              _switch(
                label: 'Share data for analytics',
                subtitle: 'Help us improve the app',
                value: _shareDataForAnalytics,
                onChanged: (v) => setState(() => _shareDataForAnalytics = v),
              ),
              _switch(
                label: 'Share data for ads',
                subtitle: 'Personalized advertising',
                value: _shareDataForAds,
                onChanged: (v) => setState(() => _shareDataForAds = v),
                showDivider: false,
              ),
            ],
          ),
          AppGroupedListSection(
            title: 'Messaging privacy',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              _switch(
                label: 'Block messages from non-matches',
                subtitle: 'Only receive messages from matches',
                value: _blockMessagesFromNonMatches,
                onChanged: (v) =>
                    setState(() => _blockMessagesFromNonMatches = v),
              ),
              _switch(
                label: 'Show read receipts',
                subtitle: 'Let others know when you read messages',
                value: _showReadReceipts,
                onChanged: (v) => setState(() => _showReadReceipts = v),
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
