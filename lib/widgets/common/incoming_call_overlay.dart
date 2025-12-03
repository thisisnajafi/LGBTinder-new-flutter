import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart' as radius;
import '../../screens/video_call_screen.dart';
import '../../screens/voice_call_screen.dart';
import '../../features/calls/providers/call_provider.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';

/// Data model for incoming call information
class IncomingCallData {
  final String callId;
  final String callType; // 'video' or 'voice'
  final int callerId;
  final String callerName;
  final String? callerAvatar;
  final String? channelName;
  final String? token;

  IncomingCallData({
    required this.callId,
    required this.callType,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    this.channelName,
    this.token,
  });
}

/// Overlay widget for incoming call notifications
class IncomingCallOverlay extends ConsumerStatefulWidget {
  final IncomingCallData callData;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    Key? key,
    required this.callData,
    required this.onDismiss,
  }) : super(key: key);

  @override
  ConsumerState<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends ConsumerState<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _ringTimer;
  int _ringCount = 0;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Start animation
    _animationController.forward();

    // Start ringing animation
    _startRinging();

    // Auto-dismiss after 30 seconds if not answered
    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _rejectCall();
      }
    });
  }

  void _startRinging() {
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && _ringCount < 20) { // Max 20 rings
        setState(() {
          _ringCount++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ringTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    try {
      final callProviderInstance = ref.read(callProvider);
      await callProviderInstance.acceptCall(int.parse(widget.callData.callId));

      // Navigate to appropriate call screen with call data
      if (mounted) {
        if (widget.callData.callType == 'video') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                userId: widget.callData.callerId,
                userName: widget.callData.callerName,
                userAvatarUrl: widget.callData.callerAvatar,
                isIncoming: true,
              ),
              fullscreenDialog: true,
              settings: RouteSettings(
                arguments: {
                  'callData': widget.callData,
                },
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VoiceCallScreen(
                userId: widget.callData.callerId,
                userName: widget.callData.callerName,
                userAvatarUrl: widget.callData.callerAvatar,
                isIncoming: true,
              ),
              fullscreenDialog: true,
              settings: RouteSettings(
                arguments: {
                  'callData': widget.callData,
                },
              ),
            ),
          );
        }

        widget.onDismiss();
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to accept call',
        );
        widget.onDismiss();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
        widget.onDismiss();
      }
    }
  }

  Future<void> _rejectCall() async {
    try {
      final callProviderInstance = ref.read(callProvider);
      await callProviderInstance.rejectCall(int.parse(widget.callData.callId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call from ${widget.callData.callerName} declined'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Log error but don't show to user for rejected calls
      debugPrint('Error rejecting call: $e');
    } finally {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.7),
        body: SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              padding: EdgeInsets.all(AppSpacing.spacingXL),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(radius.AppRadius.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caller avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentPurple.withOpacity(0.8),
                          AppColors.accentPink.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: widget.callData.callerAvatar != null
                        ? ClipOval(
                            child: Image.network(
                              widget.callData.callerAvatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  widget.callData.callType == 'video'
                                      ? Icons.videocam
                                      : Icons.call,
                                  size: 60,
                                  color: Colors.white,
                                );
                              },
                            ),
                          )
                        : Icon(
                            widget.callData.callType == 'video'
                                ? Icons.videocam
                                : Icons.call,
                            size: 60,
                            color: Colors.white,
                          ),
                  ),

                  SizedBox(height: AppSpacing.spacingLG),

                  // Call type indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: widget.callData.callType == 'video'
                          ? AppColors.accentPurple.withOpacity(0.1)
                          : AppColors.onlineGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(radius.AppRadius.radiusMD),
                    ),
                    child: Text(
                      widget.callData.callType == 'video'
                          ? 'Video Call'
                          : 'Voice Call',
                      style: AppTypography.bodySmall.copyWith(
                        color: widget.callData.callType == 'video'
                            ? AppColors.accentPurple
                            : AppColors.onlineGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.spacingMD),

                  // Caller name
                  Text(
                    widget.callData.callerName,
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacing.spacingXS),

                  // Incoming call text
                  Text(
                    'Incoming call...',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),

                  SizedBox(height: AppSpacing.spacingXL),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reject button
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.notificationRed,
                        ),
                        child: IconButton(
                          onPressed: _rejectCall,
                          icon: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),

                      SizedBox(width: AppSpacing.spacingXL),

                      // Accept button
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.onlineGreen,
                        ),
                        child: IconButton(
                          onPressed: _acceptCall,
                          icon: Icon(
                            widget.callData.callType == 'video'
                                ? Icons.videocam
                                : Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.spacingLG),

                  // Swipe to dismiss hint
                  Text(
                    'Swipe down to dismiss',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Service to manage incoming call overlays
class IncomingCallManager {
  static OverlayEntry? _currentOverlay;
  static IncomingCallData? _currentCallData;

  /// Show incoming call overlay
  static void showIncomingCall(BuildContext context, IncomingCallData callData) {
    // Remove any existing overlay
    hideIncomingCall();

    _currentCallData = callData;

    _currentOverlay = OverlayEntry(
      builder: (context) => IncomingCallOverlay(
        callData: callData,
        onDismiss: () {
          hideIncomingCall();
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Hide incoming call overlay
  static void hideIncomingCall() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _currentCallData = null;
  }

  /// Check if there's an active incoming call
  static bool hasActiveIncomingCall() {
    return _currentOverlay != null;
  }

  /// Get current call data
  static IncomingCallData? getCurrentCallData() {
    return _currentCallData;
  }
}
