import 'package:flutter/foundation.dart';

/// Serializes achievement dialogs so only one is visible (PERF-COMP-MKT-002).
class BadgePopupQueue {
  BadgePopupQueue._();

  static Future<void> _chain = Future.value();

  static Future<void> enqueue(Future<void> Function() showNext) {
    final previous = _chain;
    late final Future<void> current;
    current = previous.then((_) => showNext());
    _chain = current.catchError((_) {});
    return current;
  }

  @visibleForTesting
  static void debugReset() {
    _chain = Future.value();
  }
}
