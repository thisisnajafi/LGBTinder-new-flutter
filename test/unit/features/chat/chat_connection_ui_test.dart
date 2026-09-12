import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_connection_ui.dart';
import 'package:lgbtindernew/shared/services/pusher_websocket_service.dart';

void main() {
  group('ChatConnectionUi.resolve', () {
    test('network offline wins over Pusher connected', () {
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.connected,
          networkOnline: false,
        ),
        ChatConnectionBannerKind.waitingForNetwork,
      );
    });

    test('hides when Pusher is connected and network is up', () {
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.connected,
          networkOnline: true,
        ),
        ChatConnectionBannerKind.hidden,
      );
    });

    test('connecting and reconnecting show Connecting…', () {
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.connecting,
          networkOnline: true,
        ),
        ChatConnectionBannerKind.connecting,
      );
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.reconnecting,
          networkOnline: true,
        ),
        ChatConnectionBannerKind.connecting,
      );
      expect(
        ChatConnectionUi.label(ChatConnectionBannerKind.connecting),
        'Connecting…',
      );
    });

    test('disconnected with network up is tap to reconnect', () {
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.disconnected,
          networkOnline: true,
        ),
        ChatConnectionBannerKind.tapToReconnect,
      );
      expect(
        ChatConnectionUi.label(ChatConnectionBannerKind.tapToReconnect),
        'Tap to reconnect',
      );
    });

    test('flushing outbox shows Sending queued…', () {
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.connected,
          networkOnline: true,
          flushingQueue: true,
        ),
        ChatConnectionBannerKind.sendingQueued,
      );
      expect(
        ChatConnectionUi.label(ChatConnectionBannerKind.sendingQueued),
        'Sending queued…',
      );
    });

    test('network offline wins over flushing outbox', () {
      expect(
        ChatConnectionUi.resolve(
          pusher: ConnectionStatus.connected,
          networkOnline: false,
          flushingQueue: true,
        ),
        ChatConnectionBannerKind.waitingForNetwork,
      );
    });
  });

  group('ChatConnectionBackoff', () {
    test('doubles from 500ms and caps at 30s', () {
      expect(ChatConnectionBackoff.delayFor(1), const Duration(milliseconds: 500));
      expect(ChatConnectionBackoff.delayFor(2), const Duration(seconds: 1));
      expect(ChatConnectionBackoff.delayFor(3), const Duration(seconds: 2));
      expect(ChatConnectionBackoff.delayFor(4), const Duration(seconds: 4));
      expect(ChatConnectionBackoff.delayFor(5), const Duration(seconds: 8));
      expect(ChatConnectionBackoff.delayFor(6), const Duration(seconds: 16));
      expect(ChatConnectionBackoff.delayFor(7), const Duration(seconds: 30));
      expect(ChatConnectionBackoff.delayFor(12), ChatConnectionBackoff.maxDelay);
    });
  });
}
