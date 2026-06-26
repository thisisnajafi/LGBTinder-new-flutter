// Screen: SafetySettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/utils/app_icons.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/settings/data/models/privacy_settings.dart';
import '../core/location/location_providers.dart';
import '../core/location/location_required_exception.dart';
import '../core/location/widgets/location_permission_sheet.dart';
import '../routes/app_router.dart';
import 'nearby_safe_places_screen.dart';
import 'blocked_users_screen.dart';
import 'report_history_screen.dart';
import 'emergency_contacts_screen.dart';

/// Safety settings screen - Manage safety and privacy settings
class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends ConsumerState<SafetySettingsScreen> {
  bool _shareLocation = false;
  bool _showDistance = true;
  bool _allowMessages = true;
  bool _readReceipts = true;
  bool _safetyAlerts = true;
  bool _blockUnknownUsers = false;

  bool _privacyLoading = true;
  bool _privacySaving = false;
  PrivacySettings? _privacy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrivacySettings());
  }

  Future<void> _loadPrivacySettings() async {
    try {
      await ref.read(settingsProvider.notifier).loadPrivacySettings();
      final privacy = ref.read(settingsProvider).privacySettings;
      if (mounted && privacy != null) {
        _applyPrivacy(privacy);
      }
    } finally {
      if (mounted) setState(() => _privacyLoading = false);
    }
  }

  void _applyPrivacy(PrivacySettings privacy) {
    setState(() {
      _privacy = privacy;
      _shareLocation = privacy.locationSharing;
      _showDistance = privacy.showDistance;
      _allowMessages = privacy.allowMessaging;
      _blockUnknownUsers = privacy.blockUnknownMessages;
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
          const SnackBar(content: Text('Safety settings saved')),
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
    _savePrivacy(update(current));
  }

  Future<void> _shareLiveLocationWithContacts() async {
    final duration = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spacingMD),
                child: Text(
                  'Share live location',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ListTile(
                title: const Text('15 minutes'),
                onTap: () => Navigator.pop(ctx, 15),
              ),
              ListTile(
                title: const Text('30 minutes'),
                onTap: () => Navigator.pop(ctx, 30),
              ),
              ListTile(
                title: const Text('1 hour'),
                onTap: () => Navigator.pop(ctx, 60),
              ),
              ListTile(
                title: const Text('2 hours'),
                onTap: () => Navigator.pop(ctx, 120),
              ),
            ],
          ),
        );
      },
    );

    if (duration == null || !mounted) return;

    try {
      await ref.read(safetyLocationServiceProvider).shareLiveLocation(
            durationMinutes: duration,
            message: 'Sharing my live location with you',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location shared for $duration minutes'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } on LocationRequiredException catch (e) {
      if (!mounted) return;
      await LocationPermissionSheet.show(
        context,
        permanentlyDenied: e.permanentlyDenied,
        onEnable: _shareLiveLocationWithContacts,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Safety settings',
      subtitle: 'Privacy, alerts, and emergency tools',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Privacy',
            children: [
              PremiumToggleRow(
                title: 'Share location in discovery',
                subtitle: 'Allow distance-based matching using your location',
                value: _shareLocation,
                iconPath: AppIcons.location,
                onChanged: (value) =>
                    _togglePrivacy((p) => p.copyWith(locationSharing: value)),
                enabled: !_privacyLoading && !_privacySaving,
              ),
              PremiumToggleRow(
                title: 'Show distance',
                subtitle: 'Display distance to other users',
                value: _showDistance,
                iconPath: AppIcons.map,
                onChanged: (value) =>
                    _togglePrivacy((p) => p.copyWith(showDistance: value)),
                enabled: !_privacyLoading && !_privacySaving,
              ),
              PremiumToggleRow(
                title: 'Allow messages',
                subtitle: 'Let others message you',
                value: _allowMessages,
                iconPath: AppIcons.message,
                onChanged: (value) =>
                    _togglePrivacy((p) => p.copyWith(allowMessaging: value)),
                enabled: !_privacyLoading && !_privacySaving,
              ),
              PremiumToggleRow(
                title: 'Read receipts',
                subtitle: 'Show when messages are read',
                value: _readReceipts,
                iconPath: AppIcons.tickCircle,
                onChanged: (value) => setState(() => _readReceipts = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Safety features',
            children: [
              PremiumToggleRow(
                title: 'Safety alerts',
                subtitle: 'Get notified about potential safety concerns',
                value: _safetyAlerts,
                iconPath: AppIcons.shield,
                onChanged: (value) => setState(() => _safetyAlerts = value),
              ),
              PremiumToggleRow(
                title: 'Block unknown users',
                subtitle: 'Only allow messages from matched users',
                value: _blockUnknownUsers,
                iconPath: AppIcons.block,
                onChanged: (value) => _togglePrivacy(
                      (p) => p.copyWith(blockUnknownMessages: value),
                    ),
                enabled: !_privacyLoading && !_privacySaving,
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.locationTick,
                title: 'Share live location now',
                subtitle: 'Send GPS to emergency contacts for a limited time',
                onTap: _shareLiveLocationWithContacts,
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.location,
                title: 'Nearby safe places',
                subtitle: 'Hospitals, police, and fire stations near you',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NearbySafePlacesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Safety actions',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.block,
                title: 'Blocked users',
                subtitle: 'Manage blocked users',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const BlockedUsersScreen(),
                    ),
                  );
                },
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.report,
                title: 'Report history',
                subtitle: 'View your reports',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportHistoryScreen(),
                    ),
                  );
                },
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.call,
                title: 'Emergency contacts',
                subtitle: 'Set up emergency contacts',
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EmergencyContactsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Account help',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.help,
                title: 'Contact support',
                subtitle: 'Request account changes or removal through support',
                onTap: () => context.push(AppRoutes.supportTickets),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
