import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'google_play_billing_service.dart';

/// User-visible outcome of a Restore Purchases attempt.
enum RestorePurchasesStatus {
  /// At least one purchase was confirmed by the backend.
  success,

  /// Play returned purchases but the backend refused them (e.g. HTTP 422).
  rejected,

  /// Play reported nothing to restore.
  empty,

  /// Play returned purchases but backend confirmation never arrived in time.
  timeout,

  /// Google Play itself failed to start restore.
  playError,
}

class RestorePurchasesOutcome {
  const RestorePurchasesOutcome({
    required this.status,
    required this.userMessage,
  });

  final RestorePurchasesStatus status;
  final String userMessage;

  bool get isSuccess => status == RestorePurchasesStatus.success;

  factory RestorePurchasesOutcome.success() => const RestorePurchasesOutcome(
    status: RestorePurchasesStatus.success,
    userMessage: GooglePlayBillingService.restoreSuccessMessage,
  );

  factory RestorePurchasesOutcome.rejected() => const RestorePurchasesOutcome(
    status: RestorePurchasesStatus.rejected,
    userMessage: GooglePlayBillingService.restoreBackendFailedMessage,
  );

  factory RestorePurchasesOutcome.empty() => const RestorePurchasesOutcome(
    status: RestorePurchasesStatus.empty,
    userMessage: GooglePlayBillingService.restoreNothingFoundMessage,
  );

  factory RestorePurchasesOutcome.timeout() => const RestorePurchasesOutcome(
    status: RestorePurchasesStatus.timeout,
    userMessage: GooglePlayBillingService.restoreTimeoutMessage,
  );

  factory RestorePurchasesOutcome.playError([String? detail]) =>
      RestorePurchasesOutcome(
        status: RestorePurchasesStatus.playError,
        userMessage: detail == null || detail.trim().isEmpty
            ? GooglePlayBillingService.restorePlayFailedMessage
            : detail,
      );
}

/// Waits for backend grant confirmation after kicking off Play restore.
///
/// Does not change which HTTP endpoints the billing service calls.
class RestorePurchasesConfirmer {
  const RestorePurchasesConfirmer();

  Future<RestorePurchasesOutcome> run({
    required Stream<BillingGrantResult> grantResults,
    required Stream<List<PurchaseDetails>> purchaseUpdates,
    required Future<void> Function() restore,
    Duration timeout = const Duration(seconds: 30),
    Duration emptySettle = const Duration(seconds: 3),
  }) async {
    final completer = Completer<RestorePurchasesOutcome>();
    final grants = <BillingGrantResult>[];
    var sawRestoredPurchase = false;

    late final StreamSubscription<BillingGrantResult> grantSub;
    late final StreamSubscription<List<PurchaseDetails>> purchaseSub;
    Timer? emptyTimer;
    Timer? timeoutTimer;

    void finish(RestorePurchasesOutcome outcome) {
      if (completer.isCompleted) return;
      emptyTimer?.cancel();
      timeoutTimer?.cancel();
      grantSub.cancel();
      purchaseSub.cancel();
      completer.complete(outcome);
    }

    void evaluateGrants() {
      if (grants.any((g) => g.granted)) {
        finish(RestorePurchasesOutcome.success());
        return;
      }
      if (grants.any((g) => !g.granted && !g.canceled)) {
        finish(RestorePurchasesOutcome.rejected());
      }
    }

    grantSub = grantResults.listen((grant) {
      grants.add(grant);
      emptyTimer?.cancel();
      evaluateGrants();
    });

    purchaseSub = purchaseUpdates.listen((list) {
      if (list.any((p) => p.status == PurchaseStatus.restored)) {
        sawRestoredPurchase = true;
        emptyTimer?.cancel();
      }
    });

    timeoutTimer = Timer(timeout, () {
      if (grants.any((g) => g.granted)) {
        finish(RestorePurchasesOutcome.success());
      } else if (grants.any((g) => !g.granted && !g.canceled)) {
        finish(RestorePurchasesOutcome.rejected());
      } else if (sawRestoredPurchase || grants.isNotEmpty) {
        finish(RestorePurchasesOutcome.timeout());
      } else {
        finish(RestorePurchasesOutcome.empty());
      }
    });

    emptyTimer = Timer(emptySettle, () {
      if (!sawRestoredPurchase && grants.isEmpty) {
        finish(RestorePurchasesOutcome.empty());
      }
    });

    try {
      await restore();
    } catch (e) {
      finish(RestorePurchasesOutcome.playError());
      return completer.future;
    }

    return completer.future;
  }
}
