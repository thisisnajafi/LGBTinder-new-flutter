import 'dart:async';

import '../../shared/models/subscription_status.dart';

/// One-shot bridge from Pusher `plan.updated` to UI (snackbar + refresh).
class PlanUpdatedBridge {
  PlanUpdatedBridge._();

  static final StreamController<AppSubscriptionStatus> _controller =
      StreamController<AppSubscriptionStatus>.broadcast();

  static Stream<AppSubscriptionStatus> get stream => _controller.stream;

  static void emit(AppSubscriptionStatus status) {
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }
}
