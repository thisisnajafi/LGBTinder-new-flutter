import '../../../shared/services/pusher_websocket_service.dart';

enum ChatConnectionBannerKind {
  hidden,
  waitingForNetwork,
  connecting,
  tapToReconnect,
  sendingQueued,
}

/// Maps Pusher + network into Telegram-style banner copy (CHAT-RT-007).
class ChatConnectionUi {
  ChatConnectionUi._();

  /// Show delay so a 200ms blip does not flash; still well under 1s.
  static const Duration showDelay = Duration(milliseconds: 400);

  /// Reconnecting / tap-to-reconnect stays hidden until this many failures.
  static const int reconnectFailuresBeforeBanner = 3;

  static ChatConnectionBannerKind resolve({
    required ConnectionStatus pusher,
    required bool networkOnline,
    bool flushingQueue = false,
    int consecutiveReconnectFailures = 0,
  }) {
    if (!networkOnline) {
      return ChatConnectionBannerKind.waitingForNetwork;
    }
    if (flushingQueue) {
      return ChatConnectionBannerKind.sendingQueued;
    }
    final quietReconnect = consecutiveReconnectFailures <
        reconnectFailuresBeforeBanner;
    switch (pusher) {
      case ConnectionStatus.connected:
        return ChatConnectionBannerKind.hidden;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        if (quietReconnect) return ChatConnectionBannerKind.hidden;
        return ChatConnectionBannerKind.connecting;
      case ConnectionStatus.disconnected:
        if (quietReconnect) return ChatConnectionBannerKind.hidden;
        return ChatConnectionBannerKind.tapToReconnect;
    }
  }

  static String label(ChatConnectionBannerKind kind) {
    switch (kind) {
      case ChatConnectionBannerKind.hidden:
        return '';
      case ChatConnectionBannerKind.waitingForNetwork:
        return 'Waiting for network';
      case ChatConnectionBannerKind.connecting:
        return 'Reconnecting…';
      case ChatConnectionBannerKind.tapToReconnect:
        return 'Tap to reconnect';
      case ChatConnectionBannerKind.sendingQueued:
        return 'Sending queued…';
    }
  }
}

/// Exponential backoff for [ChatPusherLifecycleNotifier.reconnect].
class ChatConnectionBackoff {
  ChatConnectionBackoff._();

  static const Duration maxDelay = Duration(seconds: 30);

  static Duration delayFor(int attempt) {
    final safe = attempt < 1 ? 1 : attempt;
    final ms = 500 * (1 << (safe - 1).clamp(0, 6));
    return Duration(milliseconds: ms.clamp(500, maxDelay.inMilliseconds));
  }
}
