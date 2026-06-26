// Screen: GroupNotificationSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Group notification settings screen - Manage group chat notification preferences
class GroupNotificationSettingsScreen extends ConsumerStatefulWidget {
  final int? groupId;

  const GroupNotificationSettingsScreen({super.key, this.groupId});

  @override
  ConsumerState<GroupNotificationSettingsScreen> createState() =>
      _GroupNotificationSettingsScreenState();
}

class _GroupNotificationSettingsScreenState
    extends ConsumerState<GroupNotificationSettingsScreen> {
  bool _groupNotificationsEnabled = true;
  String _defaultNotificationLevel = 'all';
  bool _muteAllGroups = false;
  bool _showGroupPreviews = true;
  bool _groupSoundEnabled = true;
  bool _groupVibrationEnabled = true;

  bool _groupMuted = false;
  String _groupNotificationLevel = 'all';
  bool _groupShowPreviews = true;

  bool _dndEnabled = false;
  TimeOfDay _dndStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEndTime = const TimeOfDay(hour: 8, minute: 0);
  List<int> _dndDays = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from API
  }

  Future<void> _saveSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  void _setDefaultLevel(String value) {
    setState(() => _defaultNotificationLevel = value);
    _saveSettings();
  }

  void _setGroupLevel(String value) {
    setState(() => _groupNotificationLevel = value);
    _saveSettings();
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPicked(picked);
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroupSpecific = widget.groupId != null;

    return AppSettingsDetailScaffold(
      title: isGroupSpecific ? 'Group notifications' : 'Group notifications',
      subtitle: isGroupSpecific
          ? 'Notification level for this group'
          : 'Global group chat alerts and quiet hours',
      body: AppSettingsDetailList(
        children: [
          if (!isGroupSpecific) ...[
            PremiumSettingsGroup(
              title: 'Global',
              children: [
                PremiumToggleRow(
                  title: 'Enable group notifications',
                  subtitle: 'Receive notifications for group chats',
                  value: _groupNotificationsEnabled,
                  iconPath: AppIcons.getIconPath('people'),
                  onChanged: (value) {
                    setState(() => _groupNotificationsEnabled = value);
                    _saveSettings();
                  },
                ),
                PremiumToggleRow(
                  title: 'Mute all groups',
                  subtitle: 'Disable notifications for every group',
                  value: _muteAllGroups,
                  iconPath: AppIcons.bellSlash,
                  onChanged: (value) {
                    setState(() => _muteAllGroups = value);
                    _saveSettings();
                  },
                ),
                _SettingOption(
                  label: 'All messages',
                  isSelected: _defaultNotificationLevel == 'all',
                  onSelect: () => _setDefaultLevel('all'),
                ),
                _SettingOption(
                  label: 'Mentions only',
                  isSelected: _defaultNotificationLevel == 'mentions',
                  onSelect: () => _setDefaultLevel('mentions'),
                ),
                _SettingOption(
                  label: 'Muted',
                  isSelected: _defaultNotificationLevel == 'none',
                  onSelect: () => _setDefaultLevel('none'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
          ] else ...[
            PremiumSettingsGroup(
              title: 'This group',
              children: [
                PremiumToggleRow(
                  title: 'Mute this group',
                  subtitle: 'Disable notifications for this group',
                  value: _groupMuted,
                  iconPath: AppIcons.bellSlash,
                  onChanged: (value) {
                    setState(() => _groupMuted = value);
                    _saveSettings();
                  },
                ),
                if (!_groupMuted) ...[
                  _SettingOption(
                    label: 'All messages',
                    isSelected: _groupNotificationLevel == 'all',
                    onSelect: () => _setGroupLevel('all'),
                  ),
                  _SettingOption(
                    label: 'Mentions only',
                    isSelected: _groupNotificationLevel == 'mentions',
                    onSelect: () => _setGroupLevel('mentions'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
          ],
          PremiumSettingsGroup(
            title: 'Message previews',
            children: [
              PremiumToggleRow(
                title: 'Show message previews',
                subtitle: 'Display message content in notifications',
                value: isGroupSpecific ? _groupShowPreviews : _showGroupPreviews,
                iconPath: AppIcons.eye,
                onChanged: (value) {
                  setState(() {
                    if (isGroupSpecific) {
                      _groupShowPreviews = value;
                    } else {
                      _showGroupPreviews = value;
                    }
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Sound & vibration',
            children: [
              PremiumToggleRow(
                title: 'Sound',
                subtitle: 'Play sound for group notifications',
                value: _groupSoundEnabled,
                iconPath: AppIcons.getIconPath('volume-high'),
                onChanged: (value) {
                  setState(() => _groupSoundEnabled = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Vibration',
                subtitle: 'Vibrate for group notifications',
                value: _groupVibrationEnabled,
                iconPath: AppIcons.fingerPrint,
                onChanged: (value) {
                  setState(() => _groupVibrationEnabled = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Do not disturb',
            children: [
              PremiumToggleRow(
                title: 'Enable do not disturb',
                subtitle: 'Silence group notifications during set hours',
                value: _dndEnabled,
                iconPath: AppIcons.getIconPath('moon'),
                onChanged: (value) {
                  setState(() => _dndEnabled = value);
                  _saveSettings();
                },
              ),
              if (_dndEnabled) ...[
                PremiumSettingsTile(
                  iconPath: AppIcons.clock,
                  title: 'Start time',
                  subtitle: _dndStartTime.format(context),
                  onTap: () => _pickTime(
                    initial: _dndStartTime,
                    onPicked: (time) => setState(() => _dndStartTime = time),
                  ),
                ),
                PremiumSettingsTile(
                  iconPath: AppIcons.clock,
                  title: 'End time',
                  subtitle: _dndEndTime.format(context),
                  onTap: () => _pickTime(
                    initial: _dndEndTime,
                    onPicked: (time) => setState(() => _dndEndTime = time),
                  ),
                ),
                _DaySelector(
                  selectedDays: _dndDays,
                  onChanged: (days) {
                    setState(() => _dndDays = days);
                    _saveSettings();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  static const _days = [
    (0, 'Sun'),
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Days',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: _days.map((day) {
              final isSelected = selectedDays.contains(day.$1);
              return PremiumTapScale(
                onTap: () {
                  final next = List<int>.from(selectedDays);
                  if (isSelected) {
                    next.remove(day.$1);
                  } else {
                    next.add(day.$1);
                  }
                  onChanged(next);
                },
                semanticLabel: day.$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentViolet
                        : (isDark
                            ? AppColors.cardBackgroundDark
                            : AppColors.cardBackgroundLight),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentViolet
                          : borderColor,
                    ),
                  ),
                  child: Text(
                    day.$2,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  const _SettingOption({
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumTapScale(
      onTap: onSelect,
      semanticLabel: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentViolet.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: isSelected
                ? AppColors.accentViolet
                : AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              AppSvgIcon(
                assetPath: AppIcons.tickCircle,
                size: 20,
                color: AppColors.accentViolet,
              ),
          ],
        ),
      ),
    );
  }
}
