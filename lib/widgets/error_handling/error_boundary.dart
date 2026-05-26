// Widget: ErrorBoundary
// Optional manual error fallback wrapper (does not hook FlutterError.onError).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_display_widget.dart';

/// Displays [fallback] or [ErrorDisplayWidget] when [hasError] is set manually.
///
/// Framework errors are handled by [main.dart] (`FlutterError.onError` +
/// `ErrorWidget.builder`). Do not register another global handler here — that
/// causes `setState() during build` cascades when nested with ErrorWidget.
class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  void showError(String message) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  void clearError() {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ??
          ErrorDisplayWidget(
            errorMessage: _errorMessage ?? 'An error occurred',
            onRetry: clearError,
          );
    }

    return widget.child;
  }
}
