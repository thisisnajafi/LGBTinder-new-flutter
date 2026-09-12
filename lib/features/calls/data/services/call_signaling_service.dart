import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../chat/providers/chat_pusher_providers.dart';
import '../../../../shared/services/chat_pusher_event_names.dart';
import '../../../../shared/services/pusher_websocket_service.dart';
import '../../utils/call_signaling_log.dart';

/// Agora token payload from backend.
class AgoraTokenData {
  final String token;
  final String channelName;
  final int uid;
  final DateTime expiresAt;
  final String? appId;

  AgoraTokenData({
    required this.token,
    required this.channelName,
    required this.uid,
    required this.expiresAt,
    this.appId,
  });

  factory AgoraTokenData.fromJson(Map<String, dynamic> json) {
    return AgoraTokenData(
      token: json['token']?.toString() ?? '',
      channelName: json['channel_name']?.toString() ?? '',
      uid: int.tryParse(json['uid']?.toString() ?? '') ?? 0,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(seconds: 3600)),
      appId: _nonEmptyAppId(json['app_id']?.toString()),
    );
  }
}

String? _nonEmptyAppId(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
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
    unawaited(_pusher.subscribeCall(callId));
    _subscription?.cancel();
    _subscription = _pusher.callEventStream.listen((event) {
      final payload = event.payload;
      final eventCallId = payload['call_id'] ??
          payload['callId'] ??
          (payload['data'] is Map ? (payload['data'] as Map)['call_id'] : null);
      if (eventCallId?.toString() != callId.toString()) return;

      CallSignalingLog.logDispatch(event.name, eventCallId);
      switch (event.name) {
        case ChatPusherEventNames.callAccepted:
          onAccepted?.call(payload);
        case ChatPusherEventNames.callRejected:
          onRejected?.call(payload);
        case ChatPusherEventNames.callEnded:
          onEnded?.call(payload);
        case ChatPusherEventNames.callBusy:
          onBusy?.call(payload);
        case ChatPusherEventNames.callIncoming:
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
      unawaited(_pusher.unsubscribeCall(callId));
    }
  }
}

final callSignalingServiceProvider = Provider<CallSignalingService>((ref) {
  final pusher = ref.watch(pusherWebSocketServiceProvider);
  final api = ref.watch(apiServiceProvider);
  return CallSignalingService(pusher, api);
});
