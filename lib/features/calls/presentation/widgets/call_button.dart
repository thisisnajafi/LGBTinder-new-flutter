import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../providers/call_provider.dart';

/// Call button widget
/// Button to initiate audio or video calls
class CallButton extends ConsumerWidget {
  final int targetUserId;
  final String callType; // 'audio' or 'video'
  final VoidCallback? onCallInitiated;
  final VoidCallback? onCallFailed;
  final double size;
  final bool showLabel;

  const CallButton({
    Key? key,
    required this.targetUserId,
    this.callType = 'audio',
    this.onCallInitiated,
    this.onCallFailed,
    this.size = 48,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call button
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: callType == 'video'
                  ? [Colors.blue.shade400, Colors.blue.shade600]
                  : [AppColors.primaryLight, AppColors.primaryLight.withOpacity(0.8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (callType == 'video' ? Colors.blue : AppColors.primaryLight).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: callState.isInitiatingCall ? null : () => _initiateCall(context, ref),
              borderRadius: BorderRadius.circular(size / 2),
              child: Center(
                child: callState.isInitiatingCall
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        callType == 'video' ? Icons.videocam : Icons.call,
                        color: Colors.white,
                        size: size * 0.5,
                      ),
              ),
            ),
          ),
        ),

        // Label (if enabled)
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            callType == 'video' ? 'Video Call' : 'Audio Call',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _initiateCall(BuildContext context, WidgetRef ref) async {
    final callNotifier = ref.read(callProvider.notifier);

    final request = InitiateCallRequest(
      receiverId: targetUserId,
      callType: callType,
    );

    final success = await callNotifier.initiateCall(request);

    if (success) {
      onCallInitiated?.call();
      // Navigate to call screen
      // Navigator.of(context).pushNamed('/call/active');
    } else {
      onCallFailed?.call();
      // Error is already handled in the provider
    }
  }
}

/// Call button with eligibility check
class SmartCallButton extends ConsumerWidget {
  final int targetUserId;
  final String callType;
  final VoidCallback? onCallInitiated;
  final VoidCallback? onCallFailed;
  final double size;
  final bool showLabel;

  const SmartCallButton({
    Key? key,
    required this.targetUserId,
    this.callType = 'audio',
    this.onCallInitiated,
    this.onCallFailed,
    this.size = 48,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, just use the regular call button
    // In a real implementation, this would check eligibility first
    return CallButton(
      targetUserId: targetUserId,
      callType: callType,
      onCallInitiated: onCallInitiated,
      onCallFailed: onCallFailed,
      size: size,
      showLabel: showLabel,
    );
  }
}

/// Floating call button
class FloatingCallButton extends StatelessWidget {
  final int targetUserId;
  final String callType;
  final VoidCallback? onCallInitiated;
  final VoidCallback? onCallFailed;

  const FloatingCallButton({
    Key? key,
    required this.targetUserId,
    this.callType = 'audio',
    this.onCallInitiated,
    this.onCallFailed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: CallButton(
        targetUserId: targetUserId,
        callType: callType,
        onCallInitiated: onCallInitiated,
        onCallFailed: onCallFailed,
        size: 56,
        showLabel: false,
      ),
    );
  }
}

/// Call button row (audio + video)
class CallButtonRow extends ConsumerWidget {
  final int targetUserId;
  final VoidCallback? onCallInitiated;
  final VoidCallback? onCallFailed;
  final double spacing;
  final bool showLabels;

  const CallButtonRow({
    Key? key,
    required this.targetUserId,
    this.onCallInitiated,
    this.onCallFailed,
    this.spacing = 16,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio call button
        CallButton(
          targetUserId: targetUserId,
          callType: 'audio',
          onCallInitiated: onCallInitiated,
          onCallFailed: onCallFailed,
          size: 48,
          showLabel: showLabels,
        ),

        SizedBox(width: spacing),

        // Video call button
        CallButton(
          targetUserId: targetUserId,
          callType: 'video',
          onCallInitiated: onCallInitiated,
          onCallFailed: onCallFailed,
          size: 48,
          showLabel: showLabels,
        ),
      ],
    );
  }
}

/// Premium call button (requires premium subscription)
class PremiumCallButton extends ConsumerWidget {
  final int targetUserId;
  final String callType;
  final bool isPremium;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onCallInitiated;
  final VoidCallback? onCallFailed;
  final double size;
  final bool showLabel;

  const PremiumCallButton({
    Key? key,
    required this.targetUserId,
    this.callType = 'video',
    this.isPremium = false,
    this.onUpgradePressed,
    this.onCallInitiated,
    this.onCallFailed,
    this.size = 48,
    this.showLabel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPremium) {
      return CallButton(
        targetUserId: targetUserId,
        callType: callType,
        onCallInitiated: onCallInitiated,
        onCallFailed: onCallFailed,
        size: size,
        showLabel: showLabel,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium call button (locked)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade600],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onUpgradePressed ?? () => _showUpgradeDialog(context),
              borderRadius: BorderRadius.circular(size / 2),
              child: Center(
                child: Icon(
                  callType == 'video' ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: size * 0.4,
                ),
              ),
            ),
          ),
        ),

        // Label
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            'Premium',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: Text(
          'Video calling is a premium feature. Upgrade to premium to start video calls with your matches!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onUpgradePressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}