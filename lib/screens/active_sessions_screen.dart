import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../shared/models/api_error.dart';
import '../shared/models/api_response.dart';
import '../shared/services/error_handler_service.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/error_handling/error_display_widget.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../widgets/modals/confirmation_dialog.dart';

/// Active sessions screen — view and remotely log out signed-in devices.
class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  ConsumerState<ActiveSessionsScreen> createState() =>
      _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends ConsumerState<ActiveSessionsScreen> {
  bool _isLoading = false;
  bool _isRevokingAll = false;
  int? _revokingSessionId;
  String? _loadError;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  int _sessionId(Map<String, dynamic> session) {
    final raw = session['id'] ?? session['token_id'] ?? session['session_id'];
    if (raw is int) return raw;
    return int.parse(raw.toString());
  }

  String _deviceLabel(Map<String, dynamic> session) {
    return session['device']?.toString() ??
        session['device_name']?.toString() ??
        'Unknown device';
  }

  List<Map<String, dynamic>> _parseSessions(ApiResponse<dynamic> response) {
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((session) => Map<String, dynamic>.from(session))
          .toList();
    }
    if (data is Map) {
      final nested = data['data'] ?? data['sessions'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((session) => Map<String, dynamic>.from(session))
            .toList();
      }
    }
    final metaSessions = response.meta?['sessions'];
    if (metaSessions is List) {
      return metaSessions
          .whereType<Map>()
          .map((session) => Map<String, dynamic>.from(session))
          .toList();
    }
    return [];
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<dynamic>(
        ApiEndpoints.userSessions,
        forceRefresh: true,
      );

      if (!mounted) return;
      setState(() {
        if (response.isSuccess) {
          _sessions = _parseSessions(response);
        } else {
          _sessions = [];
          _loadError = response.message.isNotEmpty
              ? response.message
              : 'Could not load active sessions';
        }
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _sessions = [];
        _loadError = ErrorHandlerService.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessions = [];
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _removeSessionLocally(int sessionId) {
    setState(() {
      _sessions = _sessions.where((s) => _sessionId(s) != sessionId).toList();
    });
  }

  void _removeOtherSessionsLocally() {
    setState(() {
      _sessions =
          _sessions.where((s) => s['is_current'] == true).toList();
    });
  }

  Future<void> _handleLogOutSession(Map<String, dynamic> session) async {
    final sessionId = _sessionId(session);
    final deviceName = _deviceLabel(session);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log out device',
      message:
          'Log out "$deviceName"? That device will need to sign in again.',
      confirmText: 'Log out',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _revokingSessionId = sessionId);

    try {
      await ref.read(sessionApiServiceProvider).revokeSession(sessionId);
      if (!mounted) return;

      _removeSessionLocally(sessionId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out $deviceName'),
          backgroundColor: AppColors.feedbackSuccess,
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to log out device',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out device: $e'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _revokingSessionId = null);
      }
    }
  }

  Future<void> _handleLogOutAllOtherSessions() async {
    final otherCount =
        _sessions.where((s) => s['is_current'] != true).length;
    if (otherCount == 0) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Log out all other devices',
      message:
          'Log out $otherCount other device${otherCount == 1 ? '' : 's'}? '
          'You will stay signed in on this device.',
      confirmText: 'Log out all',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRevokingAll = true);

    try {
      final revokedCount =
          await ref.read(sessionApiServiceProvider).revokeAllOtherSessions();
      if (!mounted) return;

      _removeOtherSessionsLocally();
      final countLabel = revokedCount > 0 ? '$revokedCount ' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged out ${countLabel}other device${revokedCount == 1 ? '' : 's'}',
          ),
          backgroundColor: AppColors.feedbackSuccess,
        ),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackBar(
        context,
        e,
        customMessage: 'Failed to log out other devices',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out other devices: $e'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRevokingAll = false);
      }
    }
  }

  String _formatTime(dynamic raw) {
    final time = raw is DateTime
        ? raw
        : DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String _platformIconPath(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
      case 'android':
        return AppIcons.phone;
      case 'web':
        return AppIcons.getIconPath('monitor');
      default:
        return AppIcons.getIconPath('monitor');
    }
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView.builder(
        padding: AppSettingsLayout.firstSectionPadding,
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
          child: SkeletonLoader(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return ListView(
        padding: AppSettingsLayout.firstSectionPadding,
        children: [
          ErrorDisplayWidget(
            errorMessage: _loadError,
            onRetry: _loadSessions,
            title: 'Could not load sessions',
          ),
        ],
      );
    }

    final otherSessions =
        _sessions.where((s) => s['is_current'] != true).toList();
    final currentMatches =
        _sessions.where((s) => s['is_current'] == true).toList();
    final currentSession =
        currentMatches.isEmpty ? null : currentMatches.first;

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'This device',
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
            ),
            children: [
              if (currentSession != null)
                _SessionTile(
                  session: currentSession,
                  isCurrent: true,
                  platformIconPath: _platformIconPath(
                    currentSession['platform']?.toString() ?? '',
                  ),
                  formatTime: _formatTime,
                )
              else
                Text(
                  'No current session',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          if (otherSessions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Other devices',
              trailing: _isRevokingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _handleLogOutAllOtherSessions,
                      child: Text(
                        'Log out all',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.feedbackError,
                        ),
                      ),
                    ),
              children: [
                for (final session in otherSessions)
                  _SessionTile(
                    session: session,
                    isCurrent: false,
                    platformIconPath: _platformIconPath(
                      session['platform']?.toString() ?? '',
                    ),
                    formatTime: _formatTime,
                    isRevoking: _revokingSessionId == _sessionId(session),
                    onLogOut: () => _handleLogOutSession(session),
                  ),
              ],
            ),
          ] else
            Padding(
              padding: AppSettingsLayout.sectionPadding,
              child: EmptyState(
                title: 'No other sessions',
                message: 'You\'re only logged in on this device',
                iconPath: AppIcons.tickCircle,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Active sessions',
      subtitle: 'Devices where your account is signed in',
      body: _buildBody(Theme.of(context)),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isCurrent;
  final String platformIconPath;
  final String Function(dynamic) formatTime;
  final bool isRevoking;
  final VoidCallback? onLogOut;

  const _SessionTile({
    required this.session,
    required this.isCurrent,
    required this.platformIconPath,
    required this.formatTime,
    this.isRevoking = false,
    this.onLogOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final deviceName = session['device']?.toString() ??
        session['device_name']?.toString() ??
        'Unknown device';
    final location = session['location']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: isCurrent
              ? AppColors.accentPink.withValues(alpha: 0.35)
              : AppColors.accentViolet.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: platformIconPath,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deviceName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            'Current',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          Row(
            children: [
              Expanded(
                child: _Meta(
                  label: 'IP address',
                  value: session['ip_address']?.toString() ?? '—',
                ),
              ),
              _Meta(
                label: 'Last active',
                value: formatTime(session['last_active']),
                alignEnd: true,
              ),
            ],
          ),
          if (!isCurrent && onLogOut != null) ...[
            const SizedBox(height: AppSpacing.spacingMD),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRevoking ? null : onLogOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.feedbackError,
                  side: BorderSide(
                    color: AppColors.feedbackError.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacingSM,
                  ),
                ),
                icon: isRevoking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppSvgIcon(
                        assetPath: AppIcons.logout,
                        size: 16,
                        color: AppColors.feedbackError,
                      ),
                label: Text(isRevoking ? 'Logging out…' : 'Log out device'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _Meta({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
