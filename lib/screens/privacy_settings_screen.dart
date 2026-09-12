import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/cache/cache_invalidator.dart';
import '../features/discover/providers/discover_cache_provider.dart';
import '../features/settings/data/models/matching_preferences.dart';
import '../features/settings/data/models/privacy_settings.dart';
import '../features/settings/providers/privacy_preferences_provider.dart';
import '../features/settings/providers/settings_provider.dart';
import '../widgets/loading/skeleton_loader.dart';

/// Privacy settings — every §5.6 control round-trips GET/PUT `/privacy/settings`.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacyPreferencesProvider);
    final matchingAsync = ref.watch(matchingPreferencesProvider);

    ref.listen<PrivacyPreferencesUiState>(
      privacyPreferencesProvider,
      (previous, next) {
        final error = next.saveError;
        if (error == null || error == previous?.saveError) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save privacy settings')),
        );
      },
    );

    final settings = privacy.settings;
    final showSkeleton = privacy.isLoading && settings == null;

    return AppSettingsDetailScaffold(
      title: 'Privacy & safety',
      subtitle: 'Control visibility, discovery, and your data',
      onRefresh: () async {
        await ref.read(privacyPreferencesProvider.notifier).reload();
        ref.invalidate(matchingPreferencesProvider);
      },
      body: showSkeleton
          ? const _PrivacySkeleton()
          : AppSettingsDetailList(
              children: [
                if (settings != null)
                  ..._buildSections(context, ref, settings, matchingAsync),
              ],
            ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    WidgetRef ref,
    PrivacySettings settings,
    AsyncValue<MatchingPreferences> matchingAsync,
  ) {
    final notifier = ref.read(privacyPreferencesProvider.notifier);
    final matching = matchingAsync.valueOrNull;
    final discoveryVisibility = matching?.discoveryVisibility ??
        (settings.hideFromDiscovery ? 'hidden' : 'everyone');

    Widget toggle({
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

    Future<void> saveDiscoveryVisibility(String value) async {
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
        notifier.patch(
          (p) => p.copyWith(hideFromDiscovery: value == 'hidden'),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }

    Future<void> setShowInDiscovery(bool show) async {
      notifier.patch((p) => p.copyWith(showInDiscovery: show));
      if (matching == null) return;
      if (!show && matching.discoveryVisibility != 'hidden') {
        await saveDiscoveryVisibility('hidden');
      } else if (show && matching.discoveryVisibility == 'hidden') {
        await saveDiscoveryVisibility('everyone');
      }
    }

    return [
      PremiumSettingsGroup(
        title: 'Profile visibility',
        subtitle: 'What others see on your profile',
        children: [
          toggle(
            label: 'Show my profile',
            subtitle: 'Allow others to see your profile',
            value: settings.profileVisible,
            iconPath: AppIcons.profileCircle,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(profileVisible: v)),
          ),
          toggle(
            label: 'Show age',
            subtitle: 'Display your age on profile',
            value: settings.showAge,
            iconPath: AppIcons.getIconPath('cake'),
            onChanged: (v) => notifier.patch((p) => p.copyWith(showAge: v)),
          ),
          toggle(
            label: 'Show distance',
            subtitle: 'Display distance to other users',
            value: settings.showDistance,
            iconPath: AppIcons.location,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(showDistance: v)),
          ),
          toggle(
            label: 'Show online status',
            subtitle: "Let others see when you're online",
            value: settings.showOnlineStatus,
            iconPath: AppIcons.online,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(showOnlineStatus: v)),
          ),
          toggle(
            label: 'Show last seen',
            subtitle: 'Display when you were last active',
            value: settings.showLastSeen,
            iconPath: AppIcons.clock,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(showLastSeen: v)),
          ),
        ],
      ),
      AppSettingsOptionSection(
        title: 'Who can see my profile',
        padding: AppSettingsLayout.sectionPadding,
        value: settings.visibilityLevel,
        onChanged: (v) =>
            notifier.patch((p) => p.copyWith(visibilityLevel: v)),
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
        value: discoveryVisibility,
        onChanged: matchingAsync.isLoading ? null : saveDiscoveryVisibility,
        options: const [
          MapEntry('everyone', 'Everyone'),
          MapEntry('people_i_like', "Only people I've liked"),
          MapEntry('hidden', 'Hidden from discovery'),
        ],
      ),
      const SizedBox(height: AppSpacing.spacingXL),
      PremiumSettingsGroup(
        title: 'Discovery',
        subtitle: 'How you appear in the stack',
        children: [
          toggle(
            label: 'Show me in discovery',
            subtitle:
                'Allow others to find you (synced with option above when Everyone)',
            value: settings.showInDiscovery,
            iconPath: AppIcons.discover,
            onChanged: setShowInDiscovery,
          ),
          toggle(
            label: 'Show me in top picks',
            subtitle: 'Appear in curated top picks',
            value: settings.showInTopPicks,
            iconPath: AppIcons.crown,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(showInTopPicks: v)),
          ),
          toggle(
            label: 'Allow swipe back',
            subtitle: 'Let others undo swipes on you',
            value: settings.allowSwipeBack,
            iconPath: AppIcons.refresh,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(allowSwipeBack: v)),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.spacingXL),
      PremiumSettingsGroup(
        title: 'Data sharing',
        children: [
          toggle(
            label: 'Share data for matching',
            subtitle:
                'Used only to suggest better matches. You can turn this off anytime.',
            value: settings.dataCollection,
            iconPath: AppIcons.heart,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(dataCollection: v)),
          ),
          toggle(
            label: 'Share data for analytics',
            subtitle:
                'Anonymous usage helps us fix bugs and improve features. Not sold as a profile.',
            value: settings.analyticsSharing,
            iconPath: AppIcons.getIconPath('chart'),
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(analyticsSharing: v)),
          ),
          toggle(
            label: 'Share data for ads',
            subtitle:
                'Lets partners show more relevant ads. Off means less personalized ads.',
            value: settings.adsSharing,
            iconPath: AppIcons.getIconPath('notification-bing'),
            onChanged: (v) => notifier.patch((p) => p.copyWith(adsSharing: v)),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.spacingXL),
      PremiumSettingsGroup(
        title: 'Messaging privacy',
        children: [
          toggle(
            label: 'Block messages from non-matches',
            subtitle: 'Only receive messages from matches',
            value: settings.blockUnknownMessages,
            iconPath: AppIcons.message,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(blockUnknownMessages: v)),
          ),
          toggle(
            label: 'Show read receipts',
            subtitle: 'Let others know when you read messages',
            value: settings.showReadReceipts,
            iconPath: AppIcons.tickCircle,
            onChanged: (v) =>
                notifier.patch((p) => p.copyWith(showReadReceipts: v)),
          ),
        ],
      ),
    ];
  }
}

class _PrivacySkeleton extends StatelessWidget {
  const _PrivacySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      children: [
        for (var i = 0; i < 10; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
            child: SkeletonLoader(
              height: AppSpacing.spacingXXXL + AppSpacing.spacingSM,
              borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            ),
          ),
      ],
    );
  }
}
