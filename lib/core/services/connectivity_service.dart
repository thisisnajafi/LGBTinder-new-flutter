import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import 'app_logger.dart';

/// Real-time connection quality states for UI and retry coordination.
enum NetworkConnectionState {
  connected,
  disconnected,
  weak,
  checking,
}

/// Monitors network interface changes and verifies actual internet access.
///
/// Uses [connectivity_plus] for fast interface detection and an HTTP ping
/// (204 probe) to confirm real internet before showing "connected".
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final Dio _pingDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  final _stateController =
      StreamController<NetworkConnectionState>.broadcast();
  Stream<NetworkConnectionState> get onStateChange =>
      _stateController.stream;

  NetworkConnectionState _current = NetworkConnectionState.checking;
  NetworkConnectionState get current => _current;
  bool get isConnected => _current == NetworkConnectionState.connected;

  /// Backward-compatible online flag used by [ApiService] and [SyncService].
  /// Treats [checking] and [weak] as online so startup/re-verify does not block API calls.
  bool get isOnline =>
      _current == NetworkConnectionState.connected ||
      _current == NetworkConnectionState.checking ||
      _current == NetworkConnectionState.weak;

  /// Backward-compatible bool stream for existing listeners.
  Stream<bool> get connectivityStream => onStateChange.map(
        (state) => state == NetworkConnectionState.connected,
      );

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _initialized = false;

  /// Invoked when transitioning to [NetworkConnectionState.connected].
  Future<void> Function()? onConnectionRestored;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      (result) => _onConnectivityChanged([result]),
    );

    unawaited(_verifyConnection());

    AppLogger.info('ConnectivityService initialized', tag: 'Connectivity');
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasInterface =
        results.any((result) => result != ConnectivityResult.none);

    if (!hasInterface) {
      _setState(NetworkConnectionState.disconnected);
      AppLogger.warning('Network interface lost', tag: 'Connectivity');
    } else {
      _setState(NetworkConnectionState.checking);
      unawaited(_verifyConnection());
    }
  }

  Future<void> verifyConnection() => _verifyConnection();

  Future<void> _verifyConnection() async {
    final interfaceResult = await _connectivity.checkConnectivity();
    final hasInterface = interfaceResult != ConnectivityResult.none;

    if (!hasInterface) {
      _setState(NetworkConnectionState.disconnected);
      AppLogger.info(
        'Connectivity verified: disconnected (no interface)',
        tag: 'Connectivity',
      );
      return;
    }

    final hasInternet = await _hasInternetAccess();
    _setState(
      hasInternet
          ? NetworkConnectionState.connected
          : NetworkConnectionState.disconnected,
    );
    AppLogger.info(
      'Connectivity verified: ${_current.name}',
      tag: 'Connectivity',
    );
  }

  Future<bool> _hasInternetAccess() async {
    const probes = [
      'https://www.google.com/generate_204',
      'https://connectivitycheck.gstatic.com/generate_204',
      ApiEndpoints.apiOrigin,
    ];

    for (final url in probes) {
      try {
        final response = await _pingDio.get(url);
        if (response.statusCode == 204 || response.statusCode == 200) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  void markWeakConnection() {
    if (_current == NetworkConnectionState.connected) {
      _setState(NetworkConnectionState.weak);
      AppLogger.warning('Connection marked as weak', tag: 'Connectivity');
      Future.delayed(const Duration(seconds: 10), _verifyConnection);
    }
  }

  Future<bool> checkConnectivity() async {
    await _verifyConnection();
    return isConnected;
  }

  Future<void> waitForConnectivity({Duration? timeout}) async {
    if (isConnected) return;

    final completer = Completer<void>();
    StreamSubscription<NetworkConnectionState>? subscription;
    Timer? timeoutTimer;

    subscription = onStateChange.listen((state) {
      if (state == NetworkConnectionState.connected) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Connectivity timeout', timeout),
          );
        }
      });
    }

    return completer.future;
  }

  void _setState(NetworkConnectionState state) {
    final wasConnected = _current == NetworkConnectionState.connected;
    if (_current == state) return;

    _current = state;
    _stateController.add(state);

    if (!wasConnected && state == NetworkConnectionState.connected) {
      final callback = onConnectionRestored;
      if (callback != null) {
        unawaited(callback());
      }
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    _initialized = false;
  }
}
