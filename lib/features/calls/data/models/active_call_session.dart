import '../../../../routes/app_router.dart';

/// Live Agora session that can outlive the call route (CALL-NATIVE-004).
class ActiveCallSession {
  final int callId;
  final int peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final bool isVideo;
  final String? channelName;
  final bool agoraJoined;
  final bool minimized;
  final bool isCallee;

  const ActiveCallSession({
    required this.callId,
    required this.peerId,
    required this.peerName,
    this.peerAvatarUrl,
    required this.isVideo,
    this.channelName,
    this.agoraJoined = false,
    this.minimized = false,
    this.isCallee = false,
  });

  String get routeLocation => Uri(
        path: AppRoutes.outgoingCall,
        queryParameters: {
          'callId': callId.toString(),
          'recipientId': peerId.toString(),
          'recipientName': peerName,
          if (peerAvatarUrl != null && peerAvatarUrl!.isNotEmpty)
            'avatarUrl': peerAvatarUrl!,
          'type': isVideo ? 'video' : 'voice',
          'callee': '1',
        },
      ).toString();

  ActiveCallSession copyWith({
    int? callId,
    int? peerId,
    String? peerName,
    String? peerAvatarUrl,
    bool? isVideo,
    String? channelName,
    bool? agoraJoined,
    bool? minimized,
    bool? isCallee,
  }) {
    return ActiveCallSession(
      callId: callId ?? this.callId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      isVideo: isVideo ?? this.isVideo,
      channelName: channelName ?? this.channelName,
      agoraJoined: agoraJoined ?? this.agoraJoined,
      minimized: minimized ?? this.minimized,
      isCallee: isCallee ?? this.isCallee,
    );
  }
}

/// When to keep Agora up after the call route unmounts.
class ActiveCallLifecycle {
  ActiveCallLifecycle._();

  static bool keepEngine({
    required bool callEnded,
    required bool minimized,
  }) =>
      !callEnded && minimized;

  /// Resume must not call [RtcEngine.joinChannel] again.
  static bool shouldSkipJoin({
    required bool agoraInCall,
    required String? engineChannelId,
    required String? sessionChannelId,
    required bool sessionJoined,
  }) {
    if (!agoraInCall && !sessionJoined) return false;
    if (engineChannelId == null || engineChannelId.isEmpty) {
      return agoraInCall && sessionJoined;
    }
    if (sessionChannelId == null || sessionChannelId.isEmpty) {
      return agoraInCall;
    }
    return agoraInCall && engineChannelId == sessionChannelId;
  }

  static bool shouldResume({
    required int pageCallId,
    required ActiveCallSession? session,
    required bool agoraInCall,
  }) {
    if (session == null || session.callId <= 0) return false;
    if (pageCallId > 0 && session.callId != pageCallId) return false;
    return agoraInCall || session.agoraJoined || session.minimized;
  }

  static bool isCurrentCallRoute({
    required String path,
    required String? callIdQuery,
    required int sessionCallId,
  }) {
    return path == AppRoutes.outgoingCall &&
        callIdQuery == sessionCallId.toString();
  }
}
