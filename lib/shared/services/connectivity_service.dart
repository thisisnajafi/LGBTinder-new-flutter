import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus([result]);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectivityStatus([result]);
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => 
      result != ConnectivityResult.none
    );

    if (wasOnline != _isOnline) {
      if (kDebugMode) {
        debugPrint('📡 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      }
      _connectivityController.add(_isOnline);
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus([result]);
    return _isOnline;
  }

  /// Wait for connectivity to be restored
  Future<void> waitForConnectivity({Duration? timeout}) async {
    if (_isOnline) return;

    final completer = Completer<void>();
    StreamSubscription? subscription;
    Timer? timeoutTimer;

    subscription = connectivityStream.listen((isOnline) {
      if (isOnline) {
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
          completer.completeError(TimeoutException('Connectivity timeout', timeout));
        }
      });
    }

    return completer.future;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}

