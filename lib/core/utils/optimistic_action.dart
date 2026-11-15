/// Runs one user action optimistically.
///
/// The UI change is applied at once, the request runs in the background and
/// the change is undone if the request fails. While a request is running,
/// further taps are ignored, so a double tap cannot send the action twice.
///
/// Usage:
/// ```dart
/// final gate = OptimisticGate();
///
/// final response = await gate.run(
///   apply: () => setState(() => liked = true),
///   commit: () => likesService.likeUser(userId),
///   rollback: () => setState(() => liked = false),
/// );
/// ```
class OptimisticGate {
  bool _busy = false;

  /// True while a request started by [run] has not finished.
  bool get isBusy => _busy;

  /// Applies the change, then commits it.
  ///
  /// Returns the result of [commit], or null when a request is already
  /// running and this call was ignored. When [commit] throws, [rollback] is
  /// called and the error is rethrown so the caller can show it.
  Future<T?> run<T extends Object>({
    required void Function() apply,
    required Future<T> Function() commit,
    required void Function() rollback,
  }) async {
    if (_busy) return null;
    _busy = true;
    try {
      apply();
      return await commit();
    } catch (_) {
      rollback();
      rethrow;
    } finally {
      _busy = false;
    }
  }
}
