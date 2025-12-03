// Widget: ErrorBoundary
// Error boundary widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import 'error_display_widget.dart';

/// Error boundary widget
/// Catches errors and displays error UI instead of crashing
class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = details.exceptionAsString();
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ??
          ErrorDisplayWidget(
            errorMessage: _errorMessage ?? 'An error occurred',
            onRetry: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
            },
          );
    }

    return widget.child;
  }
}
