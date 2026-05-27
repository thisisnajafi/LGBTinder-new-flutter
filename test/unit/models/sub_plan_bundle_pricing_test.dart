import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/data/models/sub_plan_bundle_pricing.dart';
import 'package:lgbtindernew/features/payments/data/models/subscription_plan.dart';

void main() {
  group('SubPlanBundlePricing', () {
    final monthly = SubPlan(
      id: 1,
      planId: 10,
      name: '1 Month',
      price: 9.99,
      durationDays: 30,
    );

    final threeMonth = SubPlan(
      id: 2,
      planId: 10,
      name: '3 Months',
      price: 24.90,
      durationDays: 90,
    );

    final yearly = SubPlan(
      id: 3,
      planId: 10,
      name: '1 Year',
      price: 79.99,
      durationDays: 365,
    );

    test('monthly option has no bundle discount', () {
      final pricing = SubPlanBundlePricing.forOption(
        monthly,
        [monthly, threeMonth, yearly],
      );

      expect(pricing.hasBundleDiscount, isFalse);
      expect(pricing.discountPercent, isNull);
      expect(pricing.sellingPrice, 9.99);
    });

    test('3-month option calculates 17% off vs monthly x3', () {
      final pricing = SubPlanBundlePricing.forOption(
        threeMonth,
        [monthly, threeMonth, yearly],
      );

      expect(pricing.originalPrice, closeTo(29.97, 0.01));
      expect(pricing.sellingPrice, 24.90);
      expect(pricing.savingsAmount, closeTo(5.07, 0.01));
      expect(pricing.discountPercent, 17);
      expect(pricing.hasBundleDiscount, isTrue);
    });

    test('yearly option uses monthly baseline dynamically', () {
      final pricing = SubPlanBundlePricing.forOption(
        yearly,
        [monthly, threeMonth, yearly],
      );

      expect(pricing.originalPrice, closeTo(119.88, 0.01));
      expect(pricing.sellingPrice, 79.99);
      expect(pricing.hasBundleDiscount, isTrue);
      expect(pricing.discountPercent, greaterThan(0));
    });
  });
}
