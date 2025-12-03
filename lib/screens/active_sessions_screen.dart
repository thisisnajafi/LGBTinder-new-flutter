// Screen: ActiveSessionsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/modals/confirmation_dialog.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';

/// Active sessions screen - Manage active sessions
class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
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
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load sessions from API
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _sessions = [
          {
            'id': 'session_1',
            'device': 'iPhone 14 Pro',
            'location': 'New York, USA',
            'ip_address': '192.168.1.1',
            'last_active': DateTime.now().subtract(const Duration(minutes: 5)),
            'is_current': true,
            'platform': 'iOS',
          },
          {
            'id': 'session_2',
            'device': 'Samsung Galaxy S23',
            'location': 'Los Angeles, USA',
            'ip_address': '192.168.1.2',
            'last_active': DateTime.now().subtract(const Duration(hours: 2)),
            'is_current': false,
            'platform': 'Android',
          },
          {
            'id': 'session_3',
            'device': 'Chrome Browser',
            'location': 'Chicago, USA',
            'ip_address': '192.168.1.3',
            'last_active': DateTime.now().subtract(const Duration(days: 1)),
            'is_current': false,
            'platform': 'Web',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
      // TODO: Terminate session via API
      setState(() {
        _sessions.removeWhere((session) => session['id'] == sessionId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session terminated')),
      );
    }
  }

  Future<void> _handleTerminateAllSessions() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Terminate All Sessions',
      message: 'Are you sure you want to terminate all other sessions? You will remain logged in on this device.',
      confirmText: 'Terminate All',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      // TODO: Terminate all sessions via API
      setState(() {
        _sessions = _sessions.where((session) => session['is_current'] == true).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All other sessions terminated')),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      case 'web':
        return Icons.language;
      default:
        return Icons.device_unknown;
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

    final otherSessions = _sessions.where((s) => s['is_current'] != true).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Active Sessions',
        showBackButton: true,
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 3,
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 120,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                );
              },
            )
          : ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                // Current session
                SectionHeader(
                  title: 'This Device',
                  icon: Icons.phone_iphone,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                if (_sessions.any((s) => s['is_current'] == true))
                  _buildSessionCard(
                    session: _sessions.firstWhere((s) => s['is_current'] == true),
                    isCurrent: true,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  )
                else
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'No current session',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                  ),
                SizedBox(height: AppSpacing.spacingXXL),
                // Other sessions
                if (otherSessions.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionHeader(
                        title: 'Other Devices',
                        icon: Icons.devices,
                      ),
                      TextButton(
                        onPressed: _handleTerminateAllSessions,
                        child: Text(
                          'Terminate All',
                          style: AppTypography.button.copyWith(
                            color: AppColors.notificationRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ...otherSessions.map((session) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                      child: _buildSessionCard(
                        session: session,
                        isCurrent: false,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                    );
                  }),
                ] else
                  EmptyState(
                    title: 'No Other Sessions',
                    message: 'You\'re only logged in on this device',
                    icon: Icons.check_circle,
                  ),
              ],
            ),
    );
  }

  Widget _buildSessionCard({
    required Map<String, dynamic> session,
    required bool isCurrent,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isCurrent ? AppColors.accentPurple : borderColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Icon(
                  _getPlatformIcon(session['platform']),
                  color: AppColors.accentPurple,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          session['device'],
                          style: AppTypography.h3.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrent) ...[
                          SizedBox(width: AppSpacing.spacingSM),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingSM,
                              vertical: AppSpacing.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                            ),
                            child: Text(
                              'CURRENT',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      session['location'],
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCurrent)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.notificationRed,
                  ),
                  onPressed: () => _handleTerminateSession(session['id']),
                ),
            ],
          ),
          DividerCustom(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IP Address',
                    style: AppTypography.caption.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    session['ip_address'],
                    style: AppTypography.body.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last Active',
                    style: AppTypography.caption.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    _formatTime(session['last_active']),
                    style: AppTypography.body.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
