// Screen: GroupNotificationSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';

/// Group notification settings screen - Manage group chat notification preferences
class GroupNotificationSettingsScreen extends ConsumerStatefulWidget {
  final int? groupId; // Optional: if null, shows global settings; if set, shows group-specific settings
  const GroupNotificationSettingsScreen({Key? key, this.groupId}) : super(key: key);

  @override
  ConsumerState<GroupNotificationSettingsScreen> createState() => _GroupNotificationSettingsScreenState();
}

class _GroupNotificationSettingsScreenState extends ConsumerState<GroupNotificationSettingsScreen> {
  // Global group notification settings
  bool _groupNotificationsEnabled = true;
  String _defaultNotificationLevel = 'all'; // 'all', 'mentions', 'none'
  bool _muteAllGroups = false;
  bool _showGroupPreviews = true;
  bool _groupSoundEnabled = true;
  bool _groupVibrationEnabled = true;

  // Group-specific settings (if groupId is provided)
  bool _groupMuted = false;
  String _groupNotificationLevel = 'all';
  bool _groupShowPreviews = true;
  DateTime? _muteUntil;

  // Do Not Disturb settings
  bool _dndEnabled = false;
  TimeOfDay _dndStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEndTime = const TimeOfDay(hour: 8, minute: 0);
  List<int> _dndDays = []; // 0 = Sunday, 6 = Saturday

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from API
    // if (widget.groupId != null) {
    //   // Load group-specific settings
    // } else {
    //   // Load global settings
    // }
  }

  Future<void> _saveSettings() async {
    setState(() {
      // Show loading state
    });

    try {
      // TODO: Save settings via API
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
    } finally {
      if (mounted) {
        setState(() {
          // Hide loading state
        });
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
        title: widget.groupId != null ? 'Group Notifications' : 'Group Notification Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          if (widget.groupId == null) ...[
            // Global settings
            SectionHeader(
              title: 'Global Group Notifications',
              icon: Icons.groups,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSwitchTile(
              title: 'Enable Group Notifications',
              subtitle: 'Receive notifications for group chats',
              value: _groupNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _groupNotificationsEnabled = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildSwitchTile(
              title: 'Mute All Groups',
              subtitle: 'Disable notifications for all groups',
              value: _muteAllGroups,
              onChanged: (value) {
                setState(() {
                  _muteAllGroups = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSelectorTile(
              title: 'Default Notification Level',
              subtitle: 'Default notification setting for new groups',
              value: _defaultNotificationLevel,
              options: [
                {'value': 'all', 'label': 'All Messages', 'icon': Icons.chat_bubble},
                {'value': 'mentions', 'label': 'Mentions Only', 'icon': Icons.alternate_email},
                {'value': 'none', 'label': 'Muted', 'icon': Icons.notifications_off},
              ],
              onChanged: (value) {
                setState(() {
                  _defaultNotificationLevel = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),
          ] else ...[
            // Group-specific settings
            SectionHeader(
              title: 'Group Notifications',
              icon: Icons.group,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildSwitchTile(
              title: 'Mute This Group',
              subtitle: 'Disable notifications for this group',
              value: _groupMuted,
              onChanged: (value) {
                setState(() {
                  _groupMuted = value;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            if (!_groupMuted) ...[
              SizedBox(height: AppSpacing.spacingMD),
              _buildSelectorTile(
                title: 'Notification Level',
                subtitle: 'When to receive notifications',
                value: _groupNotificationLevel,
                options: [
                  {'value': 'all', 'label': 'All Messages', 'icon': Icons.chat_bubble},
                  {'value': 'mentions', 'label': 'Mentions Only', 'icon': Icons.alternate_email},
                ],
                onChanged: (value) {
                  setState(() {
                    _groupNotificationLevel = value;
                  });
                  _saveSettings();
                },
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
            ],
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),
          ],

          // Message previews
          SectionHeader(
            title: 'Message Previews',
            icon: Icons.preview,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Show Message Previews',
            subtitle: 'Display message content in notifications',
            value: widget.groupId != null ? _groupShowPreviews : _showGroupPreviews,
            onChanged: (value) {
              setState(() {
                if (widget.groupId != null) {
                  _groupShowPreviews = value;
                } else {
                  _showGroupPreviews = value;
                }
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
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
            subtitle: 'Play sound for group notifications',
            value: _groupSoundEnabled,
            onChanged: (value) {
              setState(() {
                _groupSoundEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate for group notifications',
            value: _groupVibrationEnabled,
            onChanged: (value) {
              setState(() {
                _groupVibrationEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Do Not Disturb
          SectionHeader(
            title: 'Do Not Disturb',
            icon: Icons.bedtime,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSwitchTile(
            title: 'Enable Do Not Disturb',
            subtitle: 'Silence group notifications during specified hours',
            value: _dndEnabled,
            onChanged: (value) {
              setState(() {
                _dndEnabled = value;
              });
              _saveSettings();
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          if (_dndEnabled) ...[
            SizedBox(height: AppSpacing.spacingMD),
            _buildTimeSelectorTile(
              title: 'Start Time',
              time: _dndStartTime,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _dndStartTime,
                );
                if (picked != null) {
                  setState(() {
                    _dndStartTime = picked;
                  });
                  _saveSettings();
                }
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildTimeSelectorTile(
              title: 'End Time',
              time: _dndEndTime,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _dndEndTime,
                );
                if (picked != null) {
                  setState(() {
                    _dndEndTime = picked;
                  });
                  _saveSettings();
                }
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildDaysSelectorTile(
              title: 'Days',
              selectedDays: _dndDays,
              onChanged: (days) {
                setState(() {
                  _dndDays = days;
                });
                _saveSettings();
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
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
    required List<Map<String, dynamic>> options,
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
                onTap: () => onChanged(option['value']),
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
                      if (option['icon'] != null)
                        Icon(
                          option['icon'],
                          color: isSelected
                              ? AppColors.accentPurple
                              : secondaryTextColor,
                          size: 20,
                        ),
                      if (option['icon'] != null)
                        SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Text(
                          option['label'],
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

  Widget _buildTimeSelectorTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
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
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  time.format(context),
                  style: AppTypography.body.copyWith(
                    color: AppColors.accentPurple,
                  ),
                ),
                SizedBox(width: AppSpacing.spacingSM),
                Icon(
                  Icons.access_time,
                  color: secondaryTextColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysSelectorTile({
    required String title,
    required List<int> selectedDays,
    required Function(List<int>) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    
    final days = [
      {'value': 0, 'label': 'Sun', 'full': 'Sunday'},
      {'value': 1, 'label': 'Mon', 'full': 'Monday'},
      {'value': 2, 'label': 'Tue', 'full': 'Tuesday'},
      {'value': 3, 'label': 'Wed', 'full': 'Wednesday'},
      {'value': 4, 'label': 'Thu', 'full': 'Thursday'},
      {'value': 5, 'label': 'Fri', 'full': 'Friday'},
      {'value': 6, 'label': 'Sat', 'full': 'Saturday'},
    ];

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
          SizedBox(height: AppSpacing.spacingMD),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: days.map((day) {
              final isSelected = selectedDays.contains(day['value']);
              return GestureDetector(
                onTap: () {
                  final newDays = List<int>.from(selectedDays);
                  if (isSelected) {
                    newDays.remove(day['value']);
                  } else {
                    newDays.add(day['value'] as int);
                  }
                  onChanged(newDays);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPurple
                        : backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : borderColor,
                    ),
                  ),
                  child: Text(
                    day['label'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
