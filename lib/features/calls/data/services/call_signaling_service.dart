import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../chat/providers/chat_pusher_providers.dart';
import '../../../../shared/services/pusher_websocket_service.dart';

/// Agora token payload from backend.
class AgoraTokenData {
  final String token;
  final String channelName;
  final int uid;
  final DateTime expiresAt;

  AgoraTokenData({
    required this.token,
    required this.channelName,
    required this.uid,
    required this.expiresAt,
  });

  factory AgoraTokenData.fromJson(Map<String, dynamic> json) {
    return AgoraTokenData(
      token: json['token']?.toString() ?? '',
      channelName: json['channel_name']?.toString() ?? '',
      uid: int.tryParse(json['uid']?.toString() ?? '') ?? 0,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

typedef CallEventHandler = void Function(Map<String, dynamic> payload);

/// Listens to Pusher call events and fetches Agora tokens.
class CallSignalingService {
  CallSignalingService(this._pusher, this._api);

  final PusherWebSocketService _pusher;
  final dynamic _api;

  StreamSubscription<CallSignalingEvent>? _subscription;
  int? _listeningCallId;

  void listen({
    required int callId,
    CallEventHandler? onAccepted,
    CallEventHandler? onRejected,
    CallEventHandler? onEnded,
    CallEventHandler? onBusy,
    CallEventHandler? onIncoming,
  }) {
    _listeningCallId = callId;
    _subscription?.cancel();
    _subscription = _pusher.callEventStream.listen((event) {
      final payload = event.payload;
      if (payload['call_id']?.toString() != callId.toString()) return;

      switch (event.name) {
        case 'call.accepted':
          onAccepted?.call(payload);
        case 'call.rejected':
          onRejected?.call(payload);
        case 'call.ended':
          onEnded?.call(payload);
        case 'call.busy':
          onBusy?.call(payload);
        case 'call.incoming':
          onIncoming?.call(payload);
      }
    });
  }

  Future<AgoraTokenData> fetchAgoraToken(int callId) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.callsAgoraToken(callId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }
    return AgoraTokenData.fromJson(response.data!);
  }

  void disposeCall(int callId) {
    if (_listeningCallId == callId) {
      _subscription?.cancel();
      _subscription = null;
      _listeningCallId = null;
    }
  }
}

final callSignalingServiceProvider = Provider<CallSignalingService>((ref) {
  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final api = ref.watch(apiServiceProvider);
  return CallSignalingService(pusher, api);
});
