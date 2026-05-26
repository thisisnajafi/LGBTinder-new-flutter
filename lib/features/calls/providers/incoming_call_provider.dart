import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/providers/chat_pusher_providers.dart';
import '../data/models/call_action_request.dart';
import '../data/models/incoming_call_data.dart';
import '../data/services/call_kit_service.dart';
import '../pages/outgoing_call_page.dart';
import '../utils/call_navigation.dart';
import 'call_provider.dart';

/// Bridge for non-Riverpod services (FCM push handler).
class IncomingCallBridge {
  static void Function(Map<String, dynamic> payload)? presentIncoming;
}

/// Active incoming call (in-app banner + CallKit).
final incomingCallProvider =
    NotifierProvider<IncomingCallNotifier, IncomingCallData?>(
  IncomingCallNotifier.new,
);

class IncomingCallNotifier extends Notifier<IncomingCallData?> {
  Timer? _autoDismissTimer;
  IncomingCallData? _pendingNavigation;

  @override
  IncomingCallData? build() {
    IncomingCallBridge.presentIncoming = present;
    ref.onDispose(() {
      IncomingCallBridge.presentIncoming = null;
      _autoDismissTimer?.cancel();
    });
    return null;
  }

  /// Handle Pusher or push payload.
  void present(Map<String, dynamic> payload) {
    final data = IncomingCallData.fromPayload(payload);
    if (data == null) return;

    if (state?.callId == data.callId) return;

    state = data;
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 45), () {
      if (state?.callId == data.callId) {
        unawaited(reject());
      }
    });

    if (!isAppForeground) {
      unawaited(CallKitService.instance.showIncoming(data));
    }
  }

  bool get isAppForeground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == AppLifecycleState.resumed;
  }

  /// Accept from in-app banner.
  Future<void> accept(BuildContext context) async {
    final data = state;
    if (data == null) return;

    _autoDismissTimer?.cancel();
    state = null;

    try {
      await ref.read(callProvider.notifier).acceptCall(
            CallActionRequest.accept(data.callId),
          );
      await CallKitService.instance.endCall(data.callId);

      if (context.mounted) {
        openActiveCallPage(
          context: context,
          callId: int.parse(data.callId),
          recipientId: data.callerId,
          recipientName: data.callerName,
          recipientAvatarUrl: data.callerAvatar,
          type: data.isVideo ? OutgoingCallType.video : OutgoingCallType.voice,
        );
      }
    } catch (e) {
      debugPrint('IncomingCallNotifier.accept failed: $e');
    }
  }

  /// Reject from in-app banner or auto-dismiss.
  Future<void> reject() async {
    final data = state;
    if (data == null) return;

    _autoDismissTimer?.cancel();
    state = null;

    try {
      await ref.read(callProvider.notifier).declineCall(
            CallActionRequest.reject(data.callId),
          );
    } catch (e) {
      debugPrint('IncomingCallNotifier.reject failed: $e');
    } finally {
      await CallKitService.instance.endCall(data.callId);
    }
  }

  /// Accept from native CallKit (may lack BuildContext).
  Future<void> acceptFromCallKit(String callId) async {
    final data = state;
    if (data == null || data.callId != callId) return;

    _autoDismissTimer?.cancel();
    state = null;

    try {
      await ref.read(callProvider.notifier).acceptCall(
            CallActionRequest.accept(callId),
          );
      _pendingNavigation = data;
    } catch (e) {
      debugPrint('IncomingCallNotifier.acceptFromCallKit failed: $e');
    }
  }

  /// Decline from native CallKit.
  Future<void> rejectFromCallKit(String callId) async {
    if (state?.callId == callId) {
      await reject();
    } else {
      await CallKitService.instance.endCall(callId);
    }
  }

  /// Navigate after CallKit accept when context becomes available.
  void consumePendingNavigation(BuildContext context) {
    final data = _pendingNavigation;
    if (data == null) return;
    _pendingNavigation = null;

    if (!context.mounted) return;
    openActiveCallPage(
      context: context,
      callId: int.parse(data.callId),
      recipientId: data.callerId,
      recipientName: data.callerName,
      recipientAvatarUrl: data.callerAvatar,
      type: data.isVideo ? OutgoingCallType.video : OutgoingCallType.voice,
    );
  }
}

/// Subscribes to Pusher `call.incoming` while the user is logged in.
final incomingCallListenerProvider = Provider<void>((ref) {
  final pusher = ref.watch(pusherWebSocketServiceProvider);

  final sub = pusher.callEventStream.listen((event) {
    if (event.name != 'call.incoming') return;
    ref.read(incomingCallProvider.notifier).present(event.payload);
  });

  ref.onDispose(sub.cancel);
});
