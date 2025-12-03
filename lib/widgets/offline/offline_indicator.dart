// Widget: OfflineIndicator
// Offline status indicator
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';

/// Offline indicator widget
/// Displays a banner when device is offline
class OfflineIndicator extends ConsumerWidget {
  final bool isOnline;

  const OfflineIndicator({
    Key? key,
    required this.isOnline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      color: AppColors.notificationRed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Text(
            'No internet connection',
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
