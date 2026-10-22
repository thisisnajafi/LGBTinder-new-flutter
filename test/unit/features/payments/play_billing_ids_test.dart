import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/data/play_billing_ids.dart';

void main() {
  test('product ids use underscores and base plans use hyphens', () {
    expect(PlayBillingIds.canonicalProductId('gold-monthly'), 'gold_monthly');
    expect(PlayBillingIds.canonicalBasePlanId('gold_monthly'), 'gold-monthly');
    expect(PlayBillingIds.canonicalProducts, contains('gold_monthly'));
    expect(PlayBillingIds.canonicalBasePlans, contains('gold-monthly'));
  });

  test('legacy mixed ids resolve to the monthly product and base plan', () {
    expect(PlayBillingIds.canonicalProductId('bronze-base'), 'bronze_monthly');
    expect(PlayBillingIds.canonicalProductId('bronze_base'), 'bronze_monthly');
    expect(PlayBillingIds.canonicalProductId('silver_base'), 'silver_monthly');
    expect(PlayBillingIds.canonicalProductId('gold_base'), 'gold_monthly');

    expect(PlayBillingIds.canonicalBasePlanId('bronze-base'), 'bronze-monthly');
    expect(PlayBillingIds.canonicalBasePlanId('silver_base'), 'silver-monthly');
    expect(PlayBillingIds.canonicalBasePlanId('gold-base'), 'gold-monthly');
    expect(
      PlayBillingIds.sameBasePlan('silver_base', 'silver-monthly'),
      isTrue,
    );
    expect(
      PlayBillingIds.productQueryIds('bronze-base'),
      {'bronze-base', 'bronze_monthly'},
    );
  });
}
