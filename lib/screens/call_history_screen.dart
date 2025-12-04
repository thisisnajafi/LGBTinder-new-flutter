// Screen: CallHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/avatar/avatar_with_status.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../pages/chat_page.dart';
import '../features/calls/providers/call_provider.dart';
import '../features/calls/data/models/call.dart';

/// Call history screen - View call history
class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  bool _isLoading = false;
  List<Call> _calls = [];

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider);
      final callHistory = await callProviderInstance.getCallHistory();

      setState(() {
        _calls = callHistory.calls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'Missed';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
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
        title: 'Call History',
        showBackButton: true,
      ),
      body: _isLoading
          ? ListView.builder(
              itemCount: 5,
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                );
              },
            )
          : _calls.isEmpty
              ? EmptyState(
                  title: 'No Call History',
                  message: 'Your call history will appear here',
                  icon: Icons.call,
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                  itemCount: _calls.length,
                  itemBuilder: (context, index) {
                    final call = _calls[index];
                    return _buildCallItem(
                      call: call,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    );
                  },
                ),
    );
  }

  Widget _buildCallItem({
    required Call call,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final isMissed = call.status == 'missed';
    final isOutgoing = call.callerId == 0; // Assuming current user has ID 0 for demo, need to get from auth
    final callType = call.isVideoCall ? Icons.videocam : Icons.call;
    final iconColor = isMissed
        ? AppColors.notificationRed
        : (isOutgoing ? AppColors.onlineGreen : AppColors.accentPurple);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(userId: isOutgoing ? call.receiverId : call.callerId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            AvatarWithStatus(
              imageUrl: isOutgoing ? call.receiver?.avatarUrl : call.caller?.avatarUrl,
              name: isOutgoing
                  ? '${call.receiver?.firstName ?? 'Unknown'} ${call.receiver?.lastName ?? 'User'}'
                  : '${call.caller?.firstName ?? 'Unknown'} ${call.caller?.lastName ?? 'User'}',
              isOnline: false,
              size: 56.0,
            ),
            SizedBox(width: AppSpacing.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOutgoing ? Icons.call_made : Icons.call_received,
                        size: 16,
                        color: iconColor,
                      ),
                      SizedBox(width: AppSpacing.spacingXS),
                      Expanded(
                        child: Text(
                          'User ${isOutgoing ? call.receiverId : call.callerId}', // TODO: Fetch user name from profile API - requires profile provider integration
                          style: AppTypography.h3.copyWith(
                            color: isMissed ? AppColors.notificationRed : textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Row(
                    children: [
                      Icon(
                        callType,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                      SizedBox(width: AppSpacing.spacingXS),
                      Text(
                        _formatDuration(call.duration ?? 0),
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(call.startedAt ?? DateTime.now()), // TODO: Use proper timestamp from API - requires API integration
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                IconButton(
                  icon: Icon(
                    callType,
                    color: AppColors.accentPurple,
                  ),
                  onPressed: () {
                    // Initiate call - implementation needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Call initiation will be implemented'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
