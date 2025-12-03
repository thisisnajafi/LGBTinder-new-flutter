import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../providers/call_provider.dart';

/// Call controls widget
/// Control buttons for active calls (mute, speaker, camera, etc.)
class CallControls extends ConsumerWidget {
  final String callId;
  final bool isVideoCall;
  final VoidCallback? onEndCall;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onSwitchCamera;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOn;
  final bool canSwitchCamera;

  const CallControls({
    Key? key,
    required this.callId,
    this.isVideoCall = false,
    this.onEndCall,
    this.onToggleMute,
    this.onToggleSpeaker,
    this.onToggleCamera,
    this.onSwitchCamera,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOn = true,
    this.canSwitchCamera = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Call duration
          Text(
            callState.formattedCallDuration,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 24),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute button
              _ControlButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                label: isMuted ? 'Unmute' : 'Mute',
                color: isMuted ? Colors.red : Colors.grey.shade600,
                onPressed: onToggleMute,
              ),

              // Speaker button
              _ControlButton(
                icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                label: isSpeakerOn ? 'Speaker' : 'Earpiece',
                color: isSpeakerOn ? AppColors.primaryLight : Colors.grey.shade600,
                onPressed: onToggleSpeaker,
              ),

              // Camera button (video calls only)
              if (isVideoCall) ...[
                _ControlButton(
                  icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
                  label: isCameraOn ? 'Camera' : 'Camera Off',
                  color: isCameraOn ? Colors.green : Colors.red,
                  onPressed: onToggleCamera,
                ),

                // Switch camera button (video calls only)
                if (canSwitchCamera)
                  _ControlButton(
                    icon: Icons.flip_camera_ios,
                    label: 'Switch',
                    color: Colors.grey.shade600,
                    onPressed: onSwitchCamera,
                  ),
              ],

              // End call button
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEndCall ?? () => _endCall(context, ref),
                    borderRadius: BorderRadius.circular(32),
                    child: const Center(
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _endCall(BuildContext context, WidgetRef ref) async {
    final callNotifier = ref.read(callProvider.notifier);

    final request = CallActionRequest(
      callId: callId,
      action: 'end',
    );

    final success = await callNotifier.endCall(request);

    if (success) {
      // Navigate back or close call screen
      Navigator.of(context).pop();
    }
  }
}

/// Individual control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final double size;

  const _ControlButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.size = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(size / 2),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: size * 0.4,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Minimal call controls (for overlay)
class MinimalCallControls extends ConsumerWidget {
  final String callId;
  final bool isVideoCall;
  final VoidCallback? onEndCall;
  final VoidCallback? onToggleMute;
  final bool isMuted;

  const MinimalCallControls({
    Key? key,
    required this.callId,
    this.isVideoCall = false,
    this.onEndCall,
    this.onToggleMute,
    this.isMuted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Call duration
          Text(
            callState.formattedCallDuration,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 16),

          // Mute button
          IconButton(
            onPressed: onToggleMute,
            icon: Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: isMuted ? Colors.red : Colors.white,
            ),
            iconSize: 24,
          ),

          // End call button
          Container(
            margin: const EdgeInsets.only(left: 8),
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onEndCall ?? () => _endCall(context, ref),
              icon: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall(BuildContext context, WidgetRef ref) async {
    final callNotifier = ref.read(callProvider.notifier);

    final request = CallActionRequest(
      callId: callId,
      action: 'end',
    );

    final success = await callNotifier.endCall(request);

    if (success) {
      Navigator.of(context).pop();
    }
  }
}

/// Call controls overlay (for full screen calls)
class CallControlsOverlay extends ConsumerWidget {
  final String callId;
  final bool isVideoCall;
  final bool isVisible;
  final VoidCallback? onEndCall;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onSwitchCamera;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOn;
  final bool canSwitchCamera;

  const CallControlsOverlay({
    Key? key,
    required this.callId,
    this.isVideoCall = false,
    this.isVisible = true,
    this.onEndCall,
    this.onToggleMute,
    this.onToggleSpeaker,
    this.onToggleCamera,
    this.onSwitchCamera,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOn = true,
    this.canSwitchCamera = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: CallControls(
        callId: callId,
        isVideoCall: isVideoCall,
        onEndCall: onEndCall,
        onToggleMute: onToggleMute,
        onToggleSpeaker: onToggleSpeaker,
        onToggleCamera: onToggleCamera,
        onSwitchCamera: onSwitchCamera,
        isMuted: isMuted,
        isSpeakerOn: isSpeakerOn,
        isCameraOn: isCameraOn,
        canSwitchCamera: canSwitchCamera,
      ),
    );
  }
}

/// Quick call controls (floating)
class FloatingCallControls extends ConsumerWidget {
  final String callId;
  final VoidCallback? onEndCall;
  final VoidCallback? onToggleMute;
  final bool isMuted;

  const FloatingCallControls({
    Key? key,
    required this.callId,
    this.onEndCall,
    this.onToggleMute,
    this.isMuted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mute button
          FloatingActionButton.small(
            onPressed: onToggleMute,
            backgroundColor: isMuted ? Colors.red : Colors.grey.shade700,
            child: Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          // End call button
          FloatingActionButton(
            onPressed: onEndCall ?? () => _endCall(context, ref),
            backgroundColor: Colors.red,
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall(BuildContext context, WidgetRef ref) async {
    final callNotifier = ref.read(callProvider.notifier);

    final request = CallActionRequest(
      callId: callId,
      action: 'end',
    );

    final success = await callNotifier.endCall(request);

    if (success) {
      Navigator.of(context).pop();
    }
  }
}