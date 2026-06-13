import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Synchronous flag for GoRouter redirects (splash owns bootstrap navigation).
bool _hasLeftStartupFlow = false;

bool get hasLeftStartupFlow => _hasLeftStartupFlow;

/// Reactive flag for Riverpod — blocks session services until splash finishes.
final startupFlowCompleteProvider = StateProvider<bool>((ref) => false);

void markStartupFlowLeft(WidgetRef ref) {
  if (_hasLeftStartupFlow) {
    ref.read(startupFlowCompleteProvider.notifier).state = true;
    return;
  }
  _hasLeftStartupFlow = true;
  ref.read(startupFlowCompleteProvider.notifier).state = true;
}
