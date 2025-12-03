import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';

/// Agora WebRTC service for video/voice calling
class AgoraService {
  // Agora App ID from Agora Console
  // https://console.agora.io/
  static const String appId = '66ec2577665249188fd54334b11f3cd4';
  RtcEngine? _engine;
  bool _isInitialized = false;

  // Call state
  bool _isInCall = false;
  String? _currentChannelId;
  int? _currentUserId;

  // Callbacks
  Function(bool isConnected)? onConnectionStateChanged;
  Function(int uid, int elapsed)? onUserJoined;
  Function(int uid, dynamic reason)? onUserOffline;
  Function(String message)? onError;

  /// Initialize Agora RTC Engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set event handlers with basic callbacks
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isInCall = true;
          onConnectionStateChanged?.call(true);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _isInCall = false;
          onConnectionStateChanged?.call(false);
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          onUserJoined?.call(uid, elapsed);
        },
        onUserOffline: (RtcConnection connection, int uid, dynamic reason) {
          onUserOffline?.call(uid, reason);
        },
        onError: (err, msg) {
          onError?.call('Agora Error: $err - $msg');
        },
      ));

      _isInitialized = true;
    } catch (e) {
      onError?.call('Failed to initialize Agora: $e');
      rethrow;
    }
  }

  /// Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || microphoneStatus.isDenied) {
      throw Exception('Camera and microphone permissions are required for calls');
    }
  }

  /// Join a call channel
  Future<void> joinChannel({
    required String channelId,
    required String token,
    required int userId,
    bool isVideoCall = true,
  }) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('Agora engine not initialized');
    }

    try {
      _currentChannelId = channelId;
      _currentUserId = userId;

      // Set channel profile
      await _engine!.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );

      // Set client role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable video or audio
      if (isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
      }

      // Join channel
      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      );

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: userId,
        options: options,
      );

    } catch (e) {
      onError?.call('Failed to join channel: $e');
      rethrow;
    }
  }

  /// Leave the current call
  Future<void> leaveChannel() async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();

      _currentChannelId = null;
      _currentUserId = null;
      _isInCall = false;
    } catch (e) {
      onError?.call('Failed to leave channel: $e');
      rethrow;
    }
  }

  /// Toggle local video (on/off)
  Future<void> toggleVideo(bool enabled) async {
    if (!_isInitialized || _engine == null) return;

    try {
      if (enabled) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
        await _engine!.stopPreview();
      }
    } catch (e) {
      onError?.call('Failed to toggle video: $e');
    }
  }

  /// Toggle local audio (mute/unmute)
  Future<void> toggleAudio(bool enabled) async {
    if (!_isInitialized || _engine == null) return;

    try {
      if (enabled) {
        await _engine!.enableAudio();
      } else {
        await _engine!.disableAudio();
      }
    } catch (e) {
      onError?.call('Failed to toggle audio: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.switchCamera();
    } catch (e) {
      onError?.call('Failed to switch camera: $e');
    }
  }

  /// Set speakerphone on/off
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.setEnableSpeakerphone(enabled);
    } catch (e) {
      onError?.call('Failed to set speakerphone: $e');
    }
  }

  /// Get current call statistics
  Future<Map<String, dynamic>> getCallStats() async {
    if (!_isInitialized || _engine == null) {
      return {};
    }

    try {
      // Return basic call statistics
      return {
        'isInCall': _isInCall,
        'channelId': _currentChannelId,
        'userId': _currentUserId,
        'bitrate': 0, // Would need to implement actual stats
        'packetLoss': 0,
        'fps': 0,
        'audioLevel': 0,
        'networkQuality': 'unknown',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_engine != null) {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
    }
    _isInitialized = false;
    _isInCall = false;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInCall => _isInCall;
  String? get currentChannelId => _currentChannelId;
  int? get currentUserId => _currentUserId;
  RtcEngine? get engine => _engine;

  // Singleton pattern
  static final AgoraService _instance = AgoraService._internal();

  factory AgoraService() {
    return _instance;
  }

  AgoraService._internal();
}

