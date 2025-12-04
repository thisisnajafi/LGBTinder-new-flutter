// Screen: VoiceCallScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/avatar/avatar_with_status.dart';
import '../widgets/buttons/icon_button_circle.dart';
import '../features/calls/providers/call_provider.dart';
import '../features/calls/data/models/call.dart';
import '../features/calls/data/models/call_action_request.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/services/agora_service.dart';
import '../shared/services/call_quality_monitor.dart';
import '../widgets/common/incoming_call_overlay.dart';

/// Voice call screen - Voice call interface
class VoiceCallScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final bool isIncoming;

  const VoiceCallScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCallActive = false;
  Duration _callDuration = Duration.zero;
  bool _isLoading = false;
  int? _currentCallId;
  String? _channelName;
  String? _token;

  final AgoraService _agoraService = AgoraService();
  late final CallQualityMonitor _qualityMonitor;

  @override
  void initState() {
    super.initState();
    _qualityMonitor = CallQualityMonitor(_agoraService);

    // Set up quality monitor callbacks
    _qualityMonitor.onQualityUpdate = (metrics) {
      // Update UI with quality metrics if needed
      debugPrint('Voice call quality update: $metrics');
    };

    _qualityMonitor.onCallEnded = (finalMetrics) {
      // Handle final metrics (could send to analytics)
      debugPrint('Voice call ended with metrics: ${finalMetrics.toJson()}');
      _handleCallCompletion(finalMetrics.callSuccessful, finalMetrics.failureReason);
    };

    if (widget.isIncoming) {
      _setupIncomingCall();
    } else {
      _startCall();
    }
  }

  void _setupIncomingCall() {
    // Get call data from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final callData = args?['callData'] as IncomingCallData?;

    if (callData != null) {
      setState(() {
        _currentCallId = int.tryParse(callData.callId) ?? 0;
        _channelName = callData.channelName;
        _token = callData.token;
      });

      // Start monitoring and join channel for incoming calls
      _qualityMonitor.startMonitoring(
        callId: callData.callId,
        callerId: widget.userId,
        receiverId: callData.callerId,
        callType: 'voice',
      );

      // Initialize Agora and join channel immediately for incoming calls
      if (_channelName != null && _token != null) {
        _initializeAgoraAndJoinChannel();
      }
    } else {
      // If no call data, this might be an error state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call data not available'),
          backgroundColor: AppColors.notificationRed,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _startCall() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider.notifier);
      final request = InitiateCallRequest(
        receiverId: widget.userId,
        callType: 'voice',
      );

      final call = await callProviderInstance.initiateCall(request);

      if (call != null) {
        setState(() {
          _currentCallId = call.id;
          _channelName = call.metadata['channel_name'] as String?;
          _token = call.metadata['token'] as String?;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to initiate call');
      }

      // Initialize Agora and join channel for voice call
      if (_channelName != null && _token != null) {
        await _initializeAgoraAndJoinChannel();
      } else {
        throw Exception('Invalid call response: missing channel or token');
      }

    } on ApiError catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to start call',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _endCall() async {
    // End call via API first
    if (_currentCallId != null) {
      try {
        final callProviderInstance = ref.read(callProvider.notifier);
        final endRequest = CallActionRequest(
          callId: _currentCallId.toString(),
          action: 'end',
        );
        await callProviderInstance.endCall(endRequest);
      } catch (e) {
        // Log error but don't prevent navigation
        print('Error ending call via API: $e');
      }
    }

    // Stop quality monitoring
    _qualityMonitor.stopMonitoring(callSuccessful: true);

    // Leave Agora channel and clean up
    try {
      await _agoraService.leaveChannel();
    } catch (e) {
      print('Error leaving Agora channel: $e');
      _qualityMonitor.recordError('Failed to leave Agora channel: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleMute() async {
    final newState = !_isMuted;
    setState(() {
      _isMuted = newState;
    });

    try {
      await _agoraService.toggleAudio(!newState); // Pass enabled state
    } catch (e) {
      // Revert on error
      setState(() {
        _isMuted = !newState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle mute: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleSpeaker() async {
    final newState = !_isSpeakerOn;
    setState(() {
      _isSpeakerOn = newState;
    });

    try {
      await _agoraService.setSpeakerphoneEnabled(newState);
    } catch (e) {
      // Revert on error
      setState(() {
        _isSpeakerOn = !newState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle speaker: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  Future<void> _acceptCall() async {
    if (_isLoading || _currentCallId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final callProviderInstance = ref.read(callProvider.notifier);
      final acceptRequest = CallActionRequest(
        callId: _currentCallId.toString(),
        action: 'accept',
      );
      await callProviderInstance.acceptCall(acceptRequest);

      setState(() {
        _isLoading = false;
      });

      // Initialize Agora for accepted call
      if (_channelName != null && _token != null) {
        await _initializeAgoraAndJoinChannel();
      } else {
        // For incoming calls, fetch call details to get channel/token
        if (_currentCallId != null) {
          await _fetchCallDetailsAndJoin();
        } else {
          setState(() {
            _isCallActive = true;
          });
        }
      }

    } on ApiError catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to accept call',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept call: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  Future<void> _initializeAgoraAndJoinChannel() async {
    try {
      // Initialize Agora service
      await _agoraService.initialize();

      // Set up event handlers
      _agoraService.onConnectionStateChanged = (isConnected) {
        if (mounted) {
          setState(() {
            _isCallActive = isConnected;
          });
        }
      };

      _agoraService.onUserJoined = (uid, elapsed) {
        // Handle remote user joined
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User joined the call')),
          );
        }
      };

      _agoraService.onUserOffline = (uid, reason) {
        // Handle remote user left
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User left the call')),
          );
        }
      };

      _agoraService.onError = (message) {
        // Record error in quality monitor
        _qualityMonitor.recordError(message);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.notificationRed,
            ),
          );
        }
      };

      // Join the channel for voice call
      await _agoraService.joinChannel(
        channelId: _channelName!,
        token: _token!,
        userId: widget.userId,
        isVideoCall: false, // Voice call
      );

      // Start quality monitoring
      _qualityMonitor.startMonitoring(
        callId: _currentCallId.toString(),
        callerId: widget.userId,
        receiverId: 0, // Would need to get from call data
        callType: 'voice',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start voice call: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _handleCallCompletion(bool successful, String? failureReason) {
    // Here you could send analytics data to your backend
    // or store locally for debugging
    debugPrint('Voice call completed - Successful: $successful, Reason: $failureReason');

    // Could show completion summary to user
    if (!successful && failureReason != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call ended: $failureReason'),
          backgroundColor: AppColors.notificationRed,
        ),
      );
    }
  }

  Future<void> _fetchCallDetailsAndJoin() async {
    try {
      final callProviderInstance = ref.read(callProvider.notifier);
      final call = await callProviderInstance.getCall(_currentCallId.toString());

      if (call.callId.isNotEmpty) {
        _channelName = call.callId;
        _token = call.metadata['agora_token'] as String?;

        if (_channelName != null && _token != null) {
          await _initializeAgoraAndJoinChannel();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get call details: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  void _minimizeCall() {
    // Create a floating call overlay
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AvatarWithStatus(
                  imageUrl: widget.userAvatarUrl,
                  name: widget.userName,
                  isOnline: _isCallActive,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isCallActive ? 'Call in progress' : 'Connecting...',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? AppColors.notificationRed : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _toggleMute,
                  iconSize: 20,
                ),
                IconButton(
                  icon: Icon(
                    Icons.call_end,
                    color: AppColors.notificationRed,
                  ),
                  onPressed: () {
                    overlayEntry.remove();
                    _endCall();
                  },
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(overlayEntry);

    // Navigate back to previous screen (usually chat)
    Navigator.of(context).pop();

    // Auto-remove overlay after 30 seconds if call ends
    Future.delayed(const Duration(seconds: 30), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  void dispose() {
    // Stop monitoring if still active
    if (_qualityMonitor.isMonitoring) {
      _qualityMonitor.stopMonitoring(callSuccessful: false, failureReason: 'Call screen disposed');
    }

    // Clean up resources
    _qualityMonitor.dispose();
    _agoraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isCallActive ? 'Call in progress' : (widget.isIncoming ? 'Incoming call' : 'Calling...'),
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.minimize, color: textColor),
                    onPressed: _minimizeCall,
                  ),
                ],
              ),
            ),
            // User info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarWithStatus(
                    imageUrl: widget.userAvatarUrl,
                    name: widget.userName,
                    isOnline: false,
                    size: 200.0,
                    showRing: true,
                  ),
                  SizedBox(height: AppSpacing.spacingXXL),
                  Text(
                    widget.userName,
                    style: AppTypography.h1.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  if (_isCallActive)
                    Text(
                      _formatDuration(_callDuration),
                      style: AppTypography.h2.copyWith(
                        color: secondaryTextColor,
                      ),
                    )
                  else
                    Text(
                      widget.isIncoming ? 'Incoming call...' : 'Calling...',
                      style: AppTypography.body.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            // Call controls
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingXXL),
              child: Column(
                children: [
                  if (!_isCallActive && widget.isIncoming) ...[
                    // Incoming call buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButtonCircle(
                          icon: Icons.call_end,
                          onTap: _endCall,
                          size: 64.0,
                          backgroundColor: AppColors.notificationRed,
                          iconColor: Colors.white,
                        ),
                        IconButtonCircle(
                          icon: Icons.call,
                          onTap: _acceptCall,
                          size: 64.0,
                          backgroundColor: AppColors.onlineGreen,
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Active call controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButtonCircle(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          onTap: _toggleMute,
                          size: 56.0,
                          backgroundColor: _isMuted
                              ? AppColors.notificationRed.withOpacity(0.2)
                              : null,
                          iconColor: _isMuted
                              ? AppColors.notificationRed
                              : textColor,
                        ),
                        IconButtonCircle(
                          icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          onTap: _toggleSpeaker,
                          size: 56.0,
                          backgroundColor: _isSpeakerOn
                              ? AppColors.accentPurple.withOpacity(0.2)
                              : null,
                          iconColor: _isSpeakerOn
                              ? AppColors.accentPurple
                              : textColor,
                        ),
                        IconButtonCircle(
                          icon: Icons.call_end,
                          onTap: _endCall,
                          size: 64.0,
                          backgroundColor: AppColors.notificationRed,
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
