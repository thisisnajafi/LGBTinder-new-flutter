import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lgbtindernew/features/payments/data/services/google_play_billing_service.dart';
import 'package:lgbtindernew/features/payments/data/services/restore_purchases_confirmer.dart';

PurchaseDetails _restoredPurchase(String productId) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'token',
      source: 'google_play',
    ),
    transactionDate: '0',
    status: PurchaseStatus.restored,
    purchaseID: 'p1',
  );
}

void main() {
  late RestorePurchasesConfirmer confirmer;

  setUp(() {
    confirmer = const RestorePurchasesConfirmer();
  });

  test('backend rejection shows rejected outcome, not success', () async {
    final grants = StreamController<BillingGrantResult>.broadcast();
    final purchases = StreamController<List<PurchaseDetails>>.broadcast();

    final future = confirmer.run(
      grantResults: grants.stream,
      purchaseUpdates: purchases.stream,
      restore: () async {
        purchases.add([_restoredPurchase('gold_monthly')]);
        grants.add(
          const BillingGrantResult(
            productId: 'gold_monthly',
            granted: false,
            message: 'INTERNAL leak that must not reach UI',
          ),
        );
      },
      timeout: const Duration(seconds: 5),
      emptySettle: const Duration(seconds: 2),
    );

    final outcome = await future;
    expect(outcome.status, RestorePurchasesStatus.rejected);
    expect(outcome.isSuccess, isFalse);
    expect(
      outcome.userMessage,
      GooglePlayBillingService.restoreBackendFailedMessage,
    );
    expect(outcome.userMessage.contains('INTERNAL'), isFalse);

    await grants.close();
    await purchases.close();
  });

  test('delayed confirmation shows success only after grant arrives', () async {
    final grants = StreamController<BillingGrantResult>.broadcast();
    final purchases = StreamController<List<PurchaseDetails>>.broadcast();

    final future = confirmer.run(
      grantResults: grants.stream,
      purchaseUpdates: purchases.stream,
      restore: () async {
        purchases.add([_restoredPurchase('silver_monthly')]);
      },
      timeout: const Duration(seconds: 5),
      emptySettle: const Duration(seconds: 2),
    );

    // Confirm nothing resolved as success before the grant.
    var completedEarly = false;
    future.then((_) => completedEarly = true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(completedEarly, isFalse);

    grants.add(
      const BillingGrantResult(productId: 'silver_monthly', granted: true),
    );

    final outcome = await future;
    expect(outcome.status, RestorePurchasesStatus.success);
    expect(outcome.isSuccess, isTrue);
    expect(outcome.userMessage, GooglePlayBillingService.restoreSuccessMessage);

    await grants.close();
    await purchases.close();
  });

  test('timeout when restored purchase never gets backend grant', () async {
    final grants = StreamController<BillingGrantResult>.broadcast();
    final purchases = StreamController<List<PurchaseDetails>>.broadcast();

    final future = confirmer.run(
      grantResults: grants.stream,
      purchaseUpdates: purchases.stream,
      restore: () async {
        purchases.add([_restoredPurchase('bronze_monthly')]);
      },
      timeout: const Duration(milliseconds: 150),
      emptySettle: const Duration(seconds: 5),
    );

    final outcome = await future;
    expect(outcome.status, RestorePurchasesStatus.timeout);
    expect(outcome.isSuccess, isFalse);
    expect(outcome.userMessage, GooglePlayBillingService.restoreTimeoutMessage);

    await grants.close();
    await purchases.close();
  });

  test('nothing to restore when Play returns no purchases', () async {
    final grants = StreamController<BillingGrantResult>.broadcast();
    final purchases = StreamController<List<PurchaseDetails>>.broadcast();

    final outcome = await confirmer.run(
      grantResults: grants.stream,
      purchaseUpdates: purchases.stream,
      restore: () async {},
      timeout: const Duration(seconds: 5),
      emptySettle: const Duration(milliseconds: 50),
    );

    expect(outcome.status, RestorePurchasesStatus.empty);
    expect(
      outcome.userMessage,
      GooglePlayBillingService.restoreNothingFoundMessage,
    );

    await grants.close();
    await purchases.close();
  });

  test('Play error when restore throws', () async {
    final grants = StreamController<BillingGrantResult>.broadcast();
    final purchases = StreamController<List<PurchaseDetails>>.broadcast();

    final outcome = await confirmer.run(
      grantResults: grants.stream,
      purchaseUpdates: purchases.stream,
      restore: () async => throw Exception('billing unavailable'),
      timeout: const Duration(seconds: 2),
      emptySettle: const Duration(seconds: 2),
    );

    expect(outcome.status, RestorePurchasesStatus.playError);
    expect(
      outcome.userMessage,
      GooglePlayBillingService.restorePlayFailedMessage,
    );

    await grants.close();
    await purchases.close();
  });
}
