import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/animation_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/notifications/data/models/notification_preferences.dart';
import '../features/notifications/providers/notification_preferences_provider.dart';
import '../features/settings/data/models/sound_preferences.dart';
import '../features/settings/providers/sound_preferences_provider.dart';
import '../widgets/loading/skeleton_loader.dart';

/// Notification settings screen — wired to GET/PUT /notifications/preferences.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSkeleton = ref.watch(
      notificationPreferencesProvider
          .select((s) => s.isLoading && s.preferences == null),
    );

    ref.listen<NotificationPreferencesUiState>(
      notificationPreferencesProvider,
      (previous, next) {
        final error = next.saveError;
        if (error == null || error == previous?.saveError) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notification preferences'),
          ),
        );
      },
    );

    return AppSettingsDetailScaffold(
      title: 'Notifications',
      subtitle: 'Choose what reaches you and how',
      onRefresh: () async {
        await ref.read(notificationPreferencesProvider.notifier).reload();
        await ref.read(soundPreferencesProvider.notifier).refresh();
      },
      body: showSkeleton
          ? const _AlertsSkeleton()
          : const _NotificationGroups(),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
    SoundPreferences? sound,
  ) {
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final fadeDuration =
        disableAnimations ? Duration.zero : AppAnimations.imageFadeIn;

    Widget fadeNested({
      required bool enabled,
      required List<Widget> children,
    }) {
      return AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: fadeDuration,
        curve: AppAnimations.curveDefault,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(children: children),
        ),
      );
    }

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

    return [
      PremiumSettingsGroup(
        title: 'Push notifications',
        subtitle: 'Alerts on this device',
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        children: [
          toggle(
            label: 'Enable push notifications',
            subtitle: 'Receive notifications on your device',
            value: prefs.pushEnabled,
            iconPath: AppIcons.notification,
            onChanged: (v) =>
                notifier.patch((current) => current.copyWith(pushEnabled: v)),
          ),
          fadeNested(
            enabled: prefs.pushEnabled,
            children: [
            toggle(
              label: 'New matches',
              subtitle: 'When someone likes you back',
              value: prefs.matches,
              iconPath: AppIcons.heart,
              onChanged: (v) =>
                  notifier.patch((current) => current.copyWith(matches: v)),
            ),
            toggle(
              label: 'New messages',
              subtitle: 'When you receive a message',
              value: prefs.messages,
              iconPath: AppIcons.message,
              onChanged: (v) =>
                  notifier.patch((current) => current.copyWith(messages: v)),
            ),
            toggle(
              label: 'Message likes',
              subtitle: 'When someone likes your message',
              value: prefs.messageLikes,
              iconPath: AppIcons.like,
              onChanged: (v) => notifier.patch(
                (current) => current.withCustomFlag('message_likes', v),
              ),
            ),
            toggle(
              label: 'Superlikes',
              subtitle: 'When someone superlikes you',
              value: prefs.superlikes,
              iconPath: AppIcons.getIconPath('star'),
              onChanged: (v) =>
                  notifier.patch((current) => current.copyWith(superlikes: v)),
            ),
            toggle(
              label: 'Top picks',
              subtitle: 'Daily top picks for you',
              value: prefs.topPicks,
              iconPath: AppIcons.crown,
              onChanged: (v) => notifier.patch(
                (current) => current.withCustomFlag('top_picks', v),
              ),
            ),
            toggle(
              label: 'Boosts',
              subtitle: 'Boost reminders and updates',
              value: prefs.boosts,
              iconPath: AppIcons.getIconPath('flash'),
              onChanged: (v) => notifier.patch(
                (current) => current.withCustomFlag('boosts', v),
              ),
            ),
            toggle(
              label: 'Profile views',
              subtitle: 'When someone views your profile',
              value: prefs.profileViews,
              iconPath: AppIcons.eye,
              onChanged: (v) => notifier.patch(
                (current) => current.copyWith(profileViews: v),
              ),
            ),
            toggle(
              label: 'Likes',
              subtitle: 'When someone likes you',
              value: prefs.likes,
              iconPath: AppIcons.like1,
              onChanged: (v) =>
                  notifier.patch((current) => current.copyWith(likes: v)),
            ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.spacingXL),
      PremiumSettingsGroup(
        title: 'Email notifications',
        subtitle: 'Updates in your inbox',
        children: [
          toggle(
            label: 'Enable email notifications',
            subtitle: 'Receive notifications via email',
            value: prefs.emailEnabled,
            iconPath: AppIcons.email,
            onChanged: (v) =>
                notifier.patch((current) => current.copyWith(emailEnabled: v)),
          ),
          fadeNested(
            enabled: prefs.emailEnabled,
            children: [
            toggle(
              label: 'New matches',
              subtitle: 'Email when you get a new match',
              value: prefs.emailMatches,
              iconPath: AppIcons.heart,
              onChanged: (v) => notifier.patch(
                (current) => current.withCustomFlag('email_matches', v),
              ),
            ),
            toggle(
              label: 'New messages',
              subtitle: 'Email when you receive messages',
              value: prefs.emailMessages,
              iconPath: AppIcons.message,
              onChanged: (v) => notifier.patch(
                (current) => current.withCustomFlag('email_messages', v),
              ),
            ),
            toggle(
              label: 'Promotions',
              subtitle: 'Special offers and promotions',
              value: prefs.marketingEmails,
              iconPath: AppIcons.getIconPath('gift'),
              onChanged: (v) => notifier.patch(
                (current) => current.copyWith(marketingEmails: v),
              ),
            ),
            toggle(
              label: 'Updates',
              subtitle: 'App updates and news',
              value: prefs.weeklyDigest,
              iconPath: AppIcons.getIconPath('info-circle'),
              onChanged: (v) => notifier.patch(
                (current) => current.copyWith(weeklyDigest: v),
              ),
            ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.spacingXL),
      PremiumSettingsGroup(
        title: 'Quiet hours',
        subtitle: 'Mute push alerts overnight',
        children: [
          toggle(
            label: 'Enable quiet hours',
            subtitle: 'No push banners during this window',
            value: prefs.quietHoursEnabled,
            iconPath: AppIcons.getIconPath('clock'),
            onChanged: (v) => notifier.patch(
              (current) => current.copyWith(quietHoursEnabled: v),
            ),
          ),
          AnimatedSize(
            duration: fadeDuration,
            curve: AppAnimations.curveDefault,
            alignment: Alignment.topCenter,
            child: prefs.quietHoursEnabled
                ? Column(
                    children: [
                      PremiumSettingsTile(
                        iconPath: AppIcons.getIconPath('timer'),
                        title: 'From',
                        subtitle: prefs.quietHoursStart ?? '22:00',
                        onTap: () => _pickQuietHour(
                          context,
                          notifier,
                          isStart: true,
                          current: prefs.quietHoursStart,
                        ),
                      ),
                      PremiumSettingsTile(
                        iconPath: AppIcons.getIconPath('timer-pause'),
                        title: 'To',
                        subtitle: prefs.quietHoursEnd ?? '07:00',
                        onTap: () => _pickQuietHour(
                          context,
                          notifier,
                          isStart: false,
                          current: prefs.quietHoursEnd,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.spacingXL),
      PremiumSettingsGroup(
        title: 'Sound & vibration',
        children: [
          toggle(
            label: 'Sound',
            subtitle: 'Play sound for notifications',
            value: prefs.soundEnabled,
            iconPath: AppIcons.getIconPath('volume-high'),
            onChanged: (v) => notifier.patch(
              (current) => current.withCustomFlag('sound_enabled', v),
            ),
          ),
          toggle(
            label: 'Vibration',
            subtitle: 'Vibrate for notifications',
            value: sound?.vibrationEnabled ?? true,
            iconPath: AppIcons.getIconPath('mobile'),
            onChanged: (v) {
              final current = sound ?? const SoundPreferences();
              ref.read(soundPreferencesProvider.notifier).updatePreferences(
                    current.copyWith(vibrationEnabled: v),
                  );
            },
          ),
        ],
      ),
    ];
  }

  Future<void> _pickQuietHour(
    BuildContext context,
    NotificationPreferencesNotifier notifier, {
    required bool isStart,
    required String? current,
  }) async {
    final raw = current ?? (isStart ? '22:00' : '07:00');
    final parts = raw.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? (isStart ? 22 : 7),
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    notifier.patch((currentPrefs) {
      return isStart
          ? currentPrefs.copyWith(quietHoursStart: formatted)
          : currentPrefs.copyWith(quietHoursEnd: formatted);
    });
  }
}

class _NotificationGroups extends ConsumerWidget {
  const _NotificationGroups();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(
      notificationPreferencesProvider.select((s) => s.preferences),
    );
    final sound = ref.watch(soundPreferencesProvider).valueOrNull;
    if (prefs == null) return const SizedBox.shrink();
    return AppSettingsDetailList(
      children: const NotificationSettingsScreen()._buildGroups(
        context,
        ref,
        prefs,
        sound,
      ),
    );
  }
}

class _AlertsSkeleton extends StatelessWidget {
  const _AlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      itemCount: 8,
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
