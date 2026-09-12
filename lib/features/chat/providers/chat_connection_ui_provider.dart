import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../shared/services/pusher_websocket_service.dart';
import '../utils/chat_connection_ui.dart';
import 'chat_outbox_ui_provider.dart';
import 'chat_pusher_providers.dart';

final pusherConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) async* {
  final pusher = ref.watch(pusherWebSocketServiceProvider);
  yield pusher.connectionStatus;
  yield* pusher.connectionStream;
});

final chatConnectionBannerProvider = Provider<ChatConnectionBannerKind>((ref) {
  final pusher = ref.watch(pusherConnectionStatusProvider).maybeWhen(
        data: (status) => status,
        orElse: () =>
            ref.read(pusherWebSocketServiceProvider).connectionStatus,
      );
  final networkOnline = ref.watch(connectivityProvider).maybeWhen(
        data: (state) => state != NetworkConnectionState.disconnected,
        orElse: () => true,
      );
  final flushingQueue = ref.watch(
    chatOutboxUiProvider.select((state) => state.flushing),
  );
  return ChatConnectionUi.resolve(
    pusher: pusher,
    networkOnline: networkOnline,
    flushingQueue: flushingQueue,
  );
});
