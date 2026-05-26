import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/agora_config.dart';

typedef AgoraTokenRefreshCallback = Future<String> Function();
typedef AgoraRemoteUserCallback = void Function(int uid);
typedef AgoraNetworkQualityCallback = void Function(int uid, int rxQuality);

/// Agora WebRTC service for video/voice calling.
class AgoraService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  bool _isInCall = false;
  String? _currentChannelId;
  int? _currentUserId;
  int? _remoteUid;
  bool _isVideoCall = false;

  Function(bool isConnected)? onConnectionStateChanged;
  AgoraRemoteUserCallback? onRemoteUserJoined;
  AgoraRemoteUserCallback? onRemoteUserLeft;
  Function(String message)? onError;
  AgoraNetworkQualityCallback? onNetworkQuality;
  AgoraTokenRefreshCallback? onTokenRefreshRequired;

  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  /// Initialize Agora RTC Engine.
  Future<void> initialize({bool isVideoCall = false}) async {
    if (_isInitialized) return;

    try {
      await _requestPermissions(isVideoCall: isVideoCall);

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine!.enableAudio();
      await _engine!.setAudioScenario(
        AudioScenarioType.audioScenarioChatroom,
      );

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isInCall = true;
          _currentChannelId ??= connection.channelId;
          onConnectionStateChanged?.call(true);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          _isInCall = false;
          _remoteUid = null;
          onConnectionStateChanged?.call(false);
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          _remoteUid = uid;
          onRemoteUserJoined?.call(uid);
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          if (_remoteUid == uid) {
            _remoteUid = null;
          }
          onRemoteUserLeft?.call(uid);
        },
        onError: (ErrorCodeType err, String msg) {
          onError?.call('Agora error ($err): $msg');
        },
        onNetworkQuality: (RtcConnection connection, int remoteUid, QualityType txQuality, QualityType rxQuality) {
          onNetworkQuality?.call(remoteUid, rxQuality.index);
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          unawaited(_refreshToken());
        },
        onRequestToken: (RtcConnection connection) {
          unawaited(_refreshToken());
        },
        onConnectionLost: (RtcConnection connection) {
          onError?.call('Connection lost');
        },
      ));

      _isInitialized = true;
    } catch (e) {
      onError?.call('Failed to initialize Agora: $e');
      rethrow;
    }
  }

  Future<void> _refreshToken() async {
    final refresh = onTokenRefreshRequired;
    if (refresh == null || _engine == null) return;

    try {
      final token = await refresh();
      if (token.isNotEmpty) {
        await _engine!.renewToken(token);
      }
    } catch (e) {
      onError?.call('Token refresh failed: $e');
    }
  }

  Future<void> _requestPermissions({required bool isVideoCall}) async {
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
      throw Exception('Microphone permission is required for calls');
    }

    if (isVideoCall) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        throw Exception('Camera permission is required for video calls');
      }
    }
  }

  /// Join a call channel.
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
      _isVideoCall = isVideoCall;

      await _engine!.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      if (isVideoCall) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.disableVideo();
        await _engine!.setEnableSpeakerphone(true);
      }

      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: userId,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: isVideoCall,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideoCall,
        ),
      );
    } catch (e) {
      onError?.call('Failed to join channel: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();

      _currentChannelId = null;
      _currentUserId = null;
      _remoteUid = null;
      _isInCall = false;
    } catch (e) {
      onError?.call('Failed to leave channel: $e');
      rethrow;
    }
  }

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

  Future<void> toggleAudio(bool enabled) async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.muteLocalAudioStream(!enabled);
    } catch (e) {
      onError?.call('Failed to toggle audio: $e');
    }
  }

  Future<void> switchCamera() async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.switchCamera();
    } catch (e) {
      onError?.call('Failed to switch camera: $e');
    }
  }

  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (!_isInitialized || _engine == null) return;

    try {
      await _engine!.setEnableSpeakerphone(enabled);
    } catch (e) {
      onError?.call('Failed to set speakerphone: $e');
    }
  }

  Future<Map<String, dynamic>> getCallStats() async {
    if (!_isInitialized || _engine == null) {
      return {};
    }

    return {
      'isInCall': _isInCall,
      'channelId': _currentChannelId,
      'userId': _currentUserId,
      'remoteUid': _remoteUid,
    };
  }

  Future<void> dispose() async {
    if (_engine != null) {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
    }
    _isInitialized = false;
    _isInCall = false;
  }

  bool get isInitialized => _isInitialized;
  bool get isInCall => _isInCall;
  String? get currentChannelId => _currentChannelId;
  int? get currentUserId => _currentUserId;
  int? get remoteUid => _remoteUid;
  RtcEngine? get engine => _engine;
}
