import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_grouped_list_card.dart';
import '../core/widgets/app_settings_detail.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../widgets/modals/confirmation_dialog.dart';

/// Active sessions screen - Manage active sessions
class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  ConsumerState<ActiveSessionsScreen> createState() =>
      _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends ConsumerState<ActiveSessionsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.userSessions,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as List<dynamic>? ?? [];
        setState(() {
          _sessions =
              data.map((session) => session as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sessions = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTerminateSession(String sessionId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Terminate Session',
      message: 'Are you sure you want to terminate this session?',
      confirmText: 'Terminate',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.post<Map<String, dynamic>>(
          '${ApiEndpoints.userSessions}/revoke/$sessionId',
          data: {},
          fromJson: (json) => json as Map<String, dynamic>,
        );
        await _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session terminated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to terminate session: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleTerminateAllSessions() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Terminate All Sessions',
      message:
          'Are you sure you want to terminate all other sessions? You will remain logged in on this device.',
      confirmText: 'Terminate All',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.post<Map<String, dynamic>>(
          '${ApiEndpoints.userSessions}/revoke-all',
          data: {},
          fromJson: (json) => json as Map<String, dynamic>,
        );
        await _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All other sessions terminated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to terminate sessions: $e')),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherSessions =
        _sessions.where((s) => s['is_current'] != true).toList();
    final currentMatches =
        _sessions.where((s) => s['is_current'] == true).toList();
    final currentSession =
        currentMatches.isEmpty ? null : currentMatches.first;

    return AppSettingsDetailScaffold(
      title: 'Active sessions',
      body: _isLoading
          ? ListView.builder(
              padding: AppSettingsLayout.firstSectionPadding,
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 120,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                ),
              ),
            )
          : AppSettingsDetailList(
              children: [
                AppGroupedListSection(
                  title: 'This device',
                  padding: AppSettingsLayout.firstSectionPadding,
                  children: [
                    if (currentSession != null)
                      _SessionTile(
                        session: currentSession,
                        isCurrent: true,
                        platformIconPath:
                            _platformIconPath(currentSession['platform']?.toString() ?? ''),
                        formatTime: _formatTime,
                      )
                    else
                      const AppSettingsInset(
                        child: Text('No current session'),
                      ),
                  ],
                ),
                if (otherSessions.isNotEmpty) ...[
                  Padding(
                    padding: AppSettingsLayout.sectionPadding,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Other devices',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.60),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _handleTerminateAllSessions,
                          child: Text(
                            'Terminate all',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.feedbackError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSettingsLayout.horizontalPadding,
                    ),
                    child: Material(
                      color: theme.colorScheme.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusMD),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < otherSessions.length; i++)
                            _SessionTile(
                              session: otherSessions[i],
                              isCurrent: false,
                              platformIconPath: _platformIconPath(
                                otherSessions[i]['platform']?.toString() ?? '',
                              ),
                              formatTime: _formatTime,
                              onTerminate: () => _handleTerminateSession(
                                otherSessions[i]['id'].toString(),
                              ),
                              showDivider: i < otherSessions.length - 1,
                            ),
                        ],
                      ),
                    ),
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
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isCurrent;
  final String platformIconPath;
  final String Function(dynamic) formatTime;
  final VoidCallback? onTerminate;
  final bool showDivider;

  const _SessionTile({
    required this.session,
    required this.isCurrent,
    required this.platformIconPath,
    required this.formatTime,
    this.onTerminate,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSettingsInset(
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
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusXS),
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
                                session['device']?.toString() ?? 'Unknown device',
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
                        const SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          session['location']?.toString() ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrent && onTerminate != null)
                    IconButton(
                      tooltip: 'Terminate session',
                      onPressed: onTerminate,
                      icon: AppSvgIcon(
                        assetPath: AppIcons.close,
                        size: 18,
                        color: AppColors.feedbackError,
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
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppSpacing.spacingMD,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
      ],
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
