import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/animation_constants.dart';

/// Coalesces search keystrokes so list/API work runs once per pause.
///
/// Empty (trimmed) values emit immediately so clearing the field never waits.
class AppSearchDebounce {
  AppSearchDebounce({
    this.delay = AppAnimations.searchDebounce,
    this.immediateWhenEmpty = true,
  });

  final Duration delay;
  final bool immediateWhenEmpty;

  Timer? _timer;
  String? _pending;

  void onText(String value, ValueChanged<String> emit) {
    _pending = value;
    _timer?.cancel();
    if (immediateWhenEmpty && value.trim().isEmpty) {
      _pending = null;
      emit(value);
      return;
    }
    _timer = Timer(delay, () {
      _pending = null;
      emit(value);
    });
  }

  /// Emit the latest pending value now (search submit / flush).
  void flush(ValueChanged<String> emit) {
    _timer?.cancel();
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      emit(pending);
    }
  }

  void cancel() {
    _timer?.cancel();
    _pending = null;
  }

  void dispose() => cancel();
}
