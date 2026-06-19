import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/cache/cache_invalidator.dart';
import '../features/discover/providers/discover_cache_provider.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/settings/data/models/privacy_settings.dart';

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

  bool _privacyLoading = true;
  bool _privacySaving = false;
  PrivacySettings? _privacy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiscoveryVisibility();
      _loadPrivacySettings();
    });
  }

  Future<void> _loadPrivacySettings() async {
    try {
      await ref.read(settingsProvider.notifier).loadPrivacySettings();
      final privacy = ref.read(settingsProvider).privacySettings;
      if (mounted && privacy != null) {
        _applyPrivacy(privacy);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to load privacy settings',
        tag: 'privacy_settings_screen',
        error: e,
      );
    } finally {
      if (mounted) setState(() => _privacyLoading = false);
    }
  }

  void _applyPrivacy(PrivacySettings privacy) {
    setState(() {
      _privacy = privacy;
      _showProfile = privacy.profileVisible;
      _showAge = privacy.showAge;
      _showDistance = privacy.showDistance;
      _showOnlineStatus = privacy.showOnlineStatus;
      _blockMessagesFromNonMatches = privacy.blockUnknownMessages;
      _shareDataForMatching = privacy.dataCollection;
      _shareDataForAnalytics = privacy.analyticsSharing;
    });
  }

  Future<void> _savePrivacy(PrivacySettings updated) async {
    if (_privacySaving) return;
    setState(() => _privacySaving = true);
    try {
      await ref.read(settingsProvider.notifier).updatePrivacySettings(
            UpdatePrivacySettingsRequest(settings: updated),
          );
      if (mounted) {
        _applyPrivacy(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _privacySaving = false);
    }
  }

  void _togglePrivacy(PrivacySettings Function(PrivacySettings current) update) {
    final current = _privacy ?? PrivacySettings();
    final updated = update(current);
    _savePrivacy(updated);
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
      await ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh();
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
    required ValueChanged<bool>? onChanged,
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
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) => _togglePrivacy((p) => p.copyWith(profileVisible: v)),
              ),
              _switch(
                label: 'Show age',
                subtitle: 'Display your age on profile',
                value: _showAge,
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) => _togglePrivacy((p) => p.copyWith(showAge: v)),
              ),
              _switch(
                label: 'Show distance',
                subtitle: 'Display distance to other users',
                value: _showDistance,
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) => _togglePrivacy((p) => p.copyWith(showDistance: v)),
              ),
              _switch(
                label: 'Show online status',
                subtitle: 'Let others see when you\'re online',
                value: _showOnlineStatus,
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) => _togglePrivacy((p) => p.copyWith(showOnlineStatus: v)),
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
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) => _togglePrivacy((p) => p.copyWith(dataCollection: v)),
              ),
              _switch(
                label: 'Share data for analytics',
                subtitle: 'Help us improve the app',
                value: _shareDataForAnalytics,
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) => _togglePrivacy((p) => p.copyWith(analyticsSharing: v)),
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
                onChanged: _privacyLoading || _privacySaving
                    ? null
                    : (v) =>
                        _togglePrivacy((p) => p.copyWith(blockUnknownMessages: v)),
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
