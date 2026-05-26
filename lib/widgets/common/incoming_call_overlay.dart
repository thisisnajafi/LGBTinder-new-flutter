import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/incoming_call_data.dart';
import '../../providers/incoming_call_provider.dart';

export '../../data/models/incoming_call_data.dart';

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
