import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/calls/data/models/incoming_call_data.dart';
import '../../features/calls/providers/incoming_call_provider.dart';

export '../../features/calls/data/models/incoming_call_data.dart';

/// DEAD UI (CALL-PERF-006 / PERF-COMP-SHARED-004). Canonical incoming UI:
/// `IncomingCallBanner` via `IncomingCallHost` in `main.dart` (root overlay
/// sibling so the navigator child does not rebuild).
/// @deprecated Use [IncomingCallBridge] + [incomingCallProvider].
class IncomingCallManager {
  static void showIncomingCall(BuildContext context, IncomingCallData callData) {
    IncomingCallBridge.presentIncoming?.call({
      'call_id': callData.callId,
      'call_type': callData.callType,
      'caller_id': callData.callerId,
      'caller_name': callData.callerName,
      'caller_avatar': callData.callerAvatar,
      'channel_name': callData.channelName,
    });
  }

  static void hideIncomingCall() {
    // No-op — state cleared by accept/reject on [incomingCallProvider].
  }

  static bool hasActiveIncomingCall() => false;

  static IncomingCallData? getCurrentCallData() => null;
}

/// Legacy overlay widget — redirects to banner via provider.
@Deprecated('Use IncomingCallBanner via IncomingCallHost')
class IncomingCallOverlay extends ConsumerWidget {
  final IncomingCallData callData;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    super.key,
    required this.callData,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IncomingCallBridge.presentIncoming?.call({
        'call_id': callData.callId,
        'call_type': callData.callType,
        'caller_id': callData.callerId,
        'caller_name': callData.callerName,
        'caller_avatar': callData.callerAvatar,
        'channel_name': callData.channelName,
      });
      onDismiss();
    });
    return const SizedBox.shrink();
  }
}
