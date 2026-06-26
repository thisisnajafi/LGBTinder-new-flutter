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
import '../../features/calls/providers/call_provider.dart';
import '../../features/calls/data/models/call_settings.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';

/// Call settings screen - Configure call preferences
class CallSettingsScreen extends ConsumerStatefulWidget {
  const CallSettingsScreen({super.key});

  @override
  ConsumerState<CallSettingsScreen> createState() => _CallSettingsScreenState();
}

class _CallSettingsScreenState extends ConsumerState<CallSettingsScreen> {
  bool _isLoading = false;
  CallSettings? _settings;

  bool _videoEnabled = true;
  bool _audioEnabled = true;
  bool _speakerEnabled = false;
  String? _ringtone;
  bool _autoAcceptCalls = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider);
      final settings = await callProviderInstance.getCallSettings();

      setState(() {
        _settings = settings;
        _videoEnabled = settings.videoEnabled;
        _audioEnabled = settings.audioEnabled;
        _speakerEnabled = settings.speakerEnabled;
        _ringtone = settings.ringtone;
        _autoAcceptCalls = settings.autoAcceptCalls;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load call settings',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load call settings: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider);
      final updatedSettings = CallSettings(
        videoEnabled: _videoEnabled,
        audioEnabled: _audioEnabled,
        speakerEnabled: _speakerEnabled,
        ringtone: _ringtone,
        autoAcceptCalls: _autoAcceptCalls,
      );

      await callProviderInstance.updateCallSettings(updatedSettings);

      setState(() {
        _settings = updatedSettings;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call settings saved successfully'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } on ApiError catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to save call settings',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save call settings: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Call settings',
      subtitle: 'Video, audio, and incoming call preferences',
      body: _isLoading && _settings == null
          ? const Center(child: CircularProgressIndicator())
          : AppSettingsDetailList(
              children: [
                PremiumSettingsGroup(
                  title: 'Video & audio',
                  children: [
                    PremiumToggleRow(
                      title: 'Enable video',
                      subtitle: 'Allow video during calls',
                      value: _videoEnabled,
                      iconPath: AppIcons.video,
                      onChanged: (value) => setState(() => _videoEnabled = value),
                      enabled: !_isLoading,
                    ),
                    PremiumToggleRow(
                      title: 'Enable audio',
                      subtitle: 'Allow voice during calls',
                      value: _audioEnabled,
                      iconPath: AppIcons.microphone,
                      onChanged: (value) => setState(() => _audioEnabled = value),
                      enabled: !_isLoading,
                    ),
                    PremiumToggleRow(
                      title: 'Speaker mode',
                      subtitle: 'Route audio through the speaker by default',
                      value: _speakerEnabled,
                      iconPath: AppIcons.getIconPath('volume-high'),
                      onChanged: (value) =>
                          setState(() => _speakerEnabled = value),
                      enabled: !_isLoading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: 'Call behavior',
                  children: [
                    PremiumToggleRow(
                      title: 'Auto accept calls',
                      subtitle: 'Automatically accept incoming calls',
                      value: _autoAcceptCalls,
                      iconPath: AppIcons.callIncoming,
                      onChanged: (value) =>
                          setState(() => _autoAcceptCalls = value),
                      enabled: !_isLoading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: 'Usage & limits',
                  children: const [
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
                    onPressed: _isLoading ? null : _saveSettings,
                    isFullWidth: true,
                    iconPath: AppIcons.tickCircle,
                  ),
                ),
              ],
            ),
    );
  }
}
