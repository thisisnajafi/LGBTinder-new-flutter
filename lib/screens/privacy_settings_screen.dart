import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/cache/cache_invalidator.dart';
import '../features/discover/providers/discover_cache_provider.dart';
import '../features/settings/providers/privacy_preferences_provider.dart';
import '../features/settings/providers/settings_provider.dart';
import '../widgets/loading/skeleton_loader.dart';

/// Privacy settings — every §5.6 control round-trips GET/PUT `/privacy/settings`.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSkeleton = ref.watch(
      privacyPreferencesProvider.select((s) => s.isLoading && s.settings == null),
    );

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
                const _ProfileVisibilityGroup(),
                const _WhoCanSeeGroup(),
                const _DiscoveryVisibilityGroup(),
                const _DiscoveryTogglesGroup(),
                const _DataSharingGroup(),
                const _MessagingPrivacyGroup(),
              ],
            ),
    );
  }
}

PremiumToggleRow _privacyToggle({
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

class _ProfileVisibilityGroup extends ConsumerWidget {
  const _ProfileVisibilityGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(privacyPreferencesProvider.select((s) {
      final p = s.settings;
      return (
        p?.profileVisible,
        p?.showAge,
        p?.showDistance,
        p?.showOnlineStatus,
        p?.showLastSeen,
      );
    }));
    final settings = ref.read(privacyPreferencesProvider).settings;
    if (settings == null) return const SizedBox.shrink();
    final notifier = ref.read(privacyPreferencesProvider.notifier);
    return PremiumSettingsGroup(
      title: 'Profile visibility',
      subtitle: 'What others see on your profile',
      children: [
        _privacyToggle(
          label: 'Show my profile',
          subtitle: 'Allow others to see your profile',
          value: slice.$1 ?? settings.profileVisible,
          iconPath: AppIcons.profileCircle,
          onChanged: (v) =>
              notifier.patch((p) => p.copyWith(profileVisible: v)),
        ),
        _privacyToggle(
          label: 'Show age',
          subtitle: 'Display your age on profile',
          value: slice.$2 ?? settings.showAge,
          iconPath: AppIcons.getIconPath('cake'),
          onChanged: (v) => notifier.patch((p) => p.copyWith(showAge: v)),
        ),
        _privacyToggle(
          label: 'Show distance',
          subtitle: 'Display distance to other users',
          value: slice.$3 ?? settings.showDistance,
          iconPath: AppIcons.location,
          onChanged: (v) =>
              notifier.patch((p) => p.copyWith(showDistance: v)),
        ),
        _privacyToggle(
          label: 'Show online status',
          subtitle: "Let others see when you're online",
          value: slice.$4 ?? settings.showOnlineStatus,
          iconPath: AppIcons.online,
          onChanged: (v) =>
              notifier.patch((p) => p.copyWith(showOnlineStatus: v)),
        ),
        _privacyToggle(
          label: 'Show last seen',
          subtitle: 'Display when you were last active',
          value: slice.$5 ?? settings.showLastSeen,
          iconPath: AppIcons.clock,
          onChanged: (v) =>
              notifier.patch((p) => p.copyWith(showLastSeen: v)),
        ),
      ],
    );
  }
}

class _WhoCanSeeGroup extends ConsumerWidget {
  const _WhoCanSeeGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      privacyPreferencesProvider.select((s) => s.settings?.visibilityLevel),
    );
    if (value == null) return const SizedBox.shrink();
    return AppSettingsOptionSection(
      title: 'Who can see my profile',
      padding: AppSettingsLayout.sectionPadding,
      value: value,
      onChanged: (v) => ref
          .read(privacyPreferencesProvider.notifier)
          .patch((p) => p.copyWith(visibilityLevel: v)),
      options: const [
        MapEntry('everyone', 'Everyone'),
        MapEntry('matches', 'Matches only'),
        MapEntry('premium', 'Premium users only'),
      ],
    );
  }
}

class _DiscoveryVisibilityGroup extends ConsumerWidget {
  const _DiscoveryVisibilityGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingAsync = ref.watch(matchingPreferencesProvider);
    final hidden = ref.watch(
      privacyPreferencesProvider.select((s) => s.settings?.hideFromDiscovery),
    );
    final matching = matchingAsync.valueOrNull;
    final discoveryVisibility = matching?.discoveryVisibility ??
        (hidden == true ? 'hidden' : 'everyone');

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
        ref.read(privacyPreferencesProvider.notifier).patch(
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

    return AppSettingsOptionSection(
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
    );
  }
}

class _DiscoveryTogglesGroup extends ConsumerWidget {
  const _DiscoveryTogglesGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(privacyPreferencesProvider.select((s) {
      final p = s.settings;
      return (p?.showInDiscovery, p?.showInTopPicks, p?.allowSwipeBack);
    }));
    final settings = ref.read(privacyPreferencesProvider).settings;
    if (settings == null) return const SizedBox.shrink();
    final notifier = ref.read(privacyPreferencesProvider.notifier);
    final matching = ref.read(matchingPreferencesProvider).valueOrNull;

    Future<void> saveDiscoveryVisibility(String value) async {
      final service = ref.read(matchingPreferencesServiceProvider);
      final current = await ref.read(matchingPreferencesProvider.future);
      await service.updatePreferences(
        current.copyWith(discoveryVisibility: value),
      );
      ref.invalidate(matchingPreferencesProvider);
      ref.invalidate(settingsSummaryProvider);
      await ref.read(cacheInvalidatorProvider).purgeDiscoveryCards();
      await ref.read(discoverCacheProvider.notifier).clearAndRefresh();
      notifier.patch((p) => p.copyWith(hideFromDiscovery: value == 'hidden'));
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

    return Column(
      children: [
        const SizedBox(height: AppSpacing.spacingXL),
        PremiumSettingsGroup(
          title: 'Discovery',
          subtitle: 'How you appear in the stack',
          children: [
            _privacyToggle(
              label: 'Show me in discovery',
              subtitle:
                  'Allow others to find you (synced with option above when Everyone)',
              value: slice.$1 ?? settings.showInDiscovery,
              iconPath: AppIcons.discover,
              onChanged: setShowInDiscovery,
            ),
            _privacyToggle(
              label: 'Show me in top picks',
              subtitle: 'Appear in curated top picks',
              value: slice.$2 ?? settings.showInTopPicks,
              iconPath: AppIcons.crown,
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(showInTopPicks: v)),
            ),
            _privacyToggle(
              label: 'Allow swipe back',
              subtitle: 'Let others undo swipes on you',
              value: slice.$3 ?? settings.allowSwipeBack,
              iconPath: AppIcons.refresh,
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(allowSwipeBack: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _DataSharingGroup extends ConsumerWidget {
  const _DataSharingGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(privacyPreferencesProvider.select((s) {
      final p = s.settings;
      return (p?.dataCollection, p?.analyticsSharing, p?.adsSharing);
    }));
    final settings = ref.read(privacyPreferencesProvider).settings;
    if (settings == null) return const SizedBox.shrink();
    final notifier = ref.read(privacyPreferencesProvider.notifier);
    return Column(
      children: [
        const SizedBox(height: AppSpacing.spacingXL),
        PremiumSettingsGroup(
          title: 'Data sharing',
          children: [
            _privacyToggle(
              label: 'Share data for matching',
              subtitle:
                  'Used only to suggest better matches. You can turn this off anytime.',
              value: slice.$1 ?? settings.dataCollection,
              iconPath: AppIcons.heart,
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(dataCollection: v)),
            ),
            _privacyToggle(
              label: 'Share data for analytics',
              subtitle:
                  'Anonymous usage helps us fix bugs and improve features. Not sold as a profile.',
              value: slice.$2 ?? settings.analyticsSharing,
              iconPath: AppIcons.getIconPath('chart'),
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(analyticsSharing: v)),
            ),
            _privacyToggle(
              label: 'Share data for ads',
              subtitle:
                  'Lets partners show more relevant ads. Off means less personalized ads.',
              value: slice.$3 ?? settings.adsSharing,
              iconPath: AppIcons.getIconPath('notification-bing'),
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(adsSharing: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessagingPrivacyGroup extends ConsumerWidget {
  const _MessagingPrivacyGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(privacyPreferencesProvider.select((s) {
      final p = s.settings;
      return (p?.blockUnknownMessages, p?.showReadReceipts);
    }));
    final settings = ref.read(privacyPreferencesProvider).settings;
    if (settings == null) return const SizedBox.shrink();
    final notifier = ref.read(privacyPreferencesProvider.notifier);
    return Column(
      children: [
        const SizedBox(height: AppSpacing.spacingXL),
        PremiumSettingsGroup(
          title: 'Messaging privacy',
          children: [
            _privacyToggle(
              label: 'Block messages from non-matches',
              subtitle: 'Only receive messages from matches',
              value: slice.$1 ?? settings.blockUnknownMessages,
              iconPath: AppIcons.message,
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(blockUnknownMessages: v)),
            ),
            _privacyToggle(
              label: 'Show read receipts',
              subtitle: 'Let others know when you read messages',
              value: slice.$2 ?? settings.showReadReceipts,
              iconPath: AppIcons.tickCircle,
              onChanged: (v) =>
                  notifier.patch((p) => p.copyWith(showReadReceipts: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrivacySkeleton extends StatelessWidget {
  const _PrivacySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      itemCount: 10,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          child: SkeletonLoader(
            height: AppSpacing.spacingXXXL + AppSpacing.spacingSM,
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          ),
        );
      },
    );
  }
}
