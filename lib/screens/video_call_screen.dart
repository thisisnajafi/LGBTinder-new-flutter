// Screen: VideoCallScreen
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
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/services/agora_service.dart';
import '../shared/services/call_quality_monitor.dart';
import '../widgets/common/incoming_call_overlay.dart';

/// Video call screen - Video call interface
class VideoCallScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final bool isIncoming;

  const VideoCallScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  bool _isCallActive = false;
  bool _isCameraSwitched = false;
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
      debugPrint('Call quality update: $metrics');
    };

    _qualityMonitor.onCallEnded = (finalMetrics) {
      // Handle final metrics (could send to analytics)
      debugPrint('Call ended with metrics: ${finalMetrics.toJson()}');
      _handleCallCompletion(finalMetrics.callSuccessful, finalMetrics.failureReason);
    };

    if (widget.isIncoming) {
      // For incoming calls, we need to get call information
      // This would typically come from push notification or call invitation
      // Schedule setup for after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupIncomingCall();
      });
    } else {
      _startCall();
    }
  }

  Future<void> _setupIncomingCall() async {
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
        callType: 'video',
      );

      // Initialize Agora and join channel immediately for incoming calls
      if (_channelName != null && _token != null) {
        await _initializeAgoraAndJoinChannel();
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

      // Join the channel
      await _agoraService.joinChannel(
        channelId: _channelName!,
        token: _token!,
        userId: widget.userId,
        isVideoCall: true,
      );

      // Start quality monitoring
      _qualityMonitor.startMonitoring(
        callId: _currentCallId.toString(),
        callerId: widget.userId,
        receiverId: 0, // Would need to get from call data
        callType: 'video',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video call: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
        Navigator.of(context).pop();
      }
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
        callType: 'video',
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

      // Initialize Agora and join channel
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

  Future<void> _toggleVideo() async {
    final newState = !_isVideoOff;
    setState(() {
      _isVideoOff = newState;
    });

    try {
      await _agoraService.toggleVideo(!newState); // Pass enabled state
    } catch (e) {
      // Revert on error
      setState(() {
        _isVideoOff = !newState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle video: $e'),
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

  Future<void> _switchCamera() async {
    setState(() {
      _isCameraSwitched = !_isCameraSwitched;
    });

    try {
      await _agoraService.switchCamera();
    } catch (e) {
      // Revert on error
      setState(() {
        _isCameraSwitched = !_isCameraSwitched;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
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
        _isCallActive = true;
        _isLoading = false;
      });

      // TODO: Initialize WebRTC connection for accepted call - requires WebRTC integration

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

  void _handleCallCompletion(bool successful, String? failureReason) {
    // Here you could send analytics data to your backend
    // or store locally for debugging
    debugPrint('Call completed - Successful: $successful, Reason: $failureReason');

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
    final textColor = Colors.white; // Always white for video call overlay

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: widget.userAvatarUrl != null
                ? Image.network(
                    widget.userAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: AvatarWithStatus(
                          imageUrl: widget.userAvatarUrl,
                          name: widget.userName,
                          isOnline: false,
                          size: 200.0,
                        ),
                      );
                    },
                  )
                : Center(
                    child: AvatarWithStatus(
                      imageUrl: widget.userAvatarUrl,
                      name: widget.userName,
                      isOnline: false,
                      size: 200.0,
                    ),
                  ),
          ),
          // Local video (picture-in-picture)
          if (_isCallActive && !_isVideoOff)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  child: Container(
                    color: AppColors.surfaceDark,
                    child: Center(
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Overlay gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: AppTypography.h2.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isCallActive)
                        Text(
                          _formatDuration(_callDuration),
                          style: AppTypography.body.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                        )
                      else
                        Text(
                          widget.isIncoming ? 'Incoming call...' : 'Calling...',
                          style: AppTypography.body.copyWith(
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.minimize, color: textColor),
                    onPressed: () {
                      // Minimize call - implementation needed
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimize call functionality will be implemented'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.spacingXXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            icon: Icons.videocam,
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
                                ? AppColors.notificationRed.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            iconColor: textColor,
                          ),
                          IconButtonCircle(
                            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                            onTap: _toggleVideo,
                            size: 56.0,
                            backgroundColor: _isVideoOff
                                ? AppColors.notificationRed.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            iconColor: textColor,
                          ),
                          IconButtonCircle(
                            icon: Icons.flip_camera_ios,
                            onTap: _switchCamera,
                            size: 56.0,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            iconColor: textColor,
                          ),
                          IconButtonCircle(
                            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                            onTap: _toggleSpeaker,
                            size: 56.0,
                            backgroundColor: _isSpeakerOn
                                ? AppColors.accentPurple.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            iconColor: textColor,
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
            ),
          ),
        ],
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
