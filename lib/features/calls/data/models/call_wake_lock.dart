import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/services/app_logger.dart';

/// Keeps the screen awake for the lifetime of a call route.
///
/// Enable is idempotent. Disable in dispose with [force] so the lock is
/// always released even if enable never completed.
class CallWakeLock {
  static const _tag = 'CallWakeLock';

  CallWakeLock({
    Future<void> Function()? enableFn,
    Future<void> Function()? disableFn,
  })  : _enableFn = enableFn,
        _disableFn = disableFn;

  final Future<void> Function()? _enableFn;
  final Future<void> Function()? _disableFn;
  bool _held = false;

  bool get isHeld => _held;

  Future<void> enable() async {
    if (_held) return;
    try {
      await (_enableFn ?? WakelockPlus.enable)();
      _held = true;
      AppLogger.info('Wake lock enabled', tag: _tag);
    } catch (e) {
      AppLogger.warning(
        'Wake lock enable failed',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<void> disable({bool force = false}) async {
    if (!_held && !force) return;
    final wasHeld = _held;
    try {
      await (_disableFn ?? WakelockPlus.disable)();
      _held = false;
      if (wasHeld) {
        AppLogger.info('Wake lock disabled', tag: _tag);
      }
    } catch (e) {
      _held = false;
      AppLogger.warning(
        'Wake lock disable failed',
        tag: _tag,
        error: e,
      );
    }
  }
}
