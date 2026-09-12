// Screen: CallSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/common/call_quota_display.dart';
import '../../features/calls/providers/call_providers.dart';
import '../../features/calls/data/models/call.dart';
import '../../features/calls/utils/call_settings_draft.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';

/// Call settings screen - Configure call preferences
class CallSettingsScreen extends ConsumerStatefulWidget {
  const CallSettingsScreen({super.key});

  @override
  ConsumerState<CallSettingsScreen> createState() => _CallSettingsScreenState();
}

class _CallSettingsScreenState extends ConsumerState<CallSettingsScreen> {
  final CallSettingsDraft _draft = CallSettingsDraft();
  CallSettings? _settings;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _draft.setBusy(true);

    try {
      final settings = await ref.read(callRepositoryProvider).getCallSettings();

      _draft.hydrate(
        videoEnabled: settings.enableVideo,
        audioEnabled: settings.enableAudio,
        callWaiting: settings.enableCallWaiting,
        autoAcceptCalls: settings.autoAcceptFromMatches,
      );
      if (mounted) {
        setState(() => _settings = settings);
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load call settings',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load call settings: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    } finally {
      if (mounted) _draft.setBusy(false);
    }
  }

  Future<void> _saveSettings() async {
    _draft.setBusy(true);

    try {
      final updatedSettings = (_settings ?? CallSettings()).copyWith(
        enableVideo: _draft.videoEnabled,
        enableAudio: _draft.audioEnabled,
        enableCallWaiting: _draft.callWaiting,
        autoAcceptFromMatches: _draft.autoAcceptCalls,
      );

      await ref.read(callRepositoryProvider).updateCallSettings(
            UpdateCallSettingsRequest(settings: updatedSettings),
          );

      if (mounted) {
        setState(() => _settings = updatedSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call settings saved successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to save call settings',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save call settings: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    } finally {
      if (mounted) _draft.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Call settings',
      subtitle: 'Video, audio, and incoming call preferences',
      body: ListenableBuilder(
        listenable: _draft,
        builder: (context, _) {
          if (_draft.isBusy && _settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return AppSettingsDetailList(
            children: [
              PremiumSettingsGroup(
                title: 'Video & audio',
                children: [
                  PremiumToggleRow(
                    title: 'Enable video',
                    subtitle: 'Allow video during calls',
                    value: _draft.videoEnabled,
                    iconPath: AppIcons.video,
                    onChanged: _draft.setVideoEnabled,
                    enabled: !_draft.isBusy,
                  ),
                  PremiumToggleRow(
                    title: 'Enable audio',
                    subtitle: 'Allow voice during calls',
                    value: _draft.audioEnabled,
                    iconPath: AppIcons.microphone,
                    onChanged: _draft.setAudioEnabled,
                    enabled: !_draft.isBusy,
                  ),
                  PremiumToggleRow(
                    title: 'Call waiting',
                    subtitle: 'Alert you when another call comes in',
                    value: _draft.callWaiting,
                    iconPath: AppIcons.getIconPath('volume-high'),
                    onChanged: _draft.setCallWaiting,
                    enabled: !_draft.isBusy,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              PremiumSettingsGroup(
                title: 'Call behavior',
                children: [
                  PremiumToggleRow(
                    title: 'Auto accept from matches',
                    subtitle: 'Automatically accept calls from matches',
                    value: _draft.autoAcceptCalls,
                    iconPath: AppIcons.callIncoming,
                    onChanged: _draft.setAutoAcceptCalls,
                    enabled: !_draft.isBusy,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              const PremiumSettingsGroup(
                title: 'Usage & limits',
                children: [
                  CallQuotaDisplay(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSettingsLayout.horizontalPadding,
                  AppSpacing.spacingXL,
                  AppSettingsLayout.horizontalPadding,
                  0,
                ),
                child: GradientButton(
                  text: 'Save settings',
                  onPressed: _draft.isBusy ? null : _saveSettings,
                  isFullWidth: true,
                  iconPath: AppIcons.tickCircle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
