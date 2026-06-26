import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';
import 'api_providers.dart';

/// Stream of detailed connection states for UI banners and guards.
final connectivityProvider = StreamProvider<NetworkConnectionState>((ref) async* {
  ref.watch(connectivityServiceBindingProvider);
  yield ConnectivityService.instance.current;
  yield* ConnectivityService.instance.onStateChange;
});

/// Convenience bool — true only when internet is verified.
final isConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(connectivityProvider);
  return state.when(
    data: (connectionState) =>
        connectionState == NetworkConnectionState.connected,
    loading: () => true,
    error: (_, __) => false,
  );
});
