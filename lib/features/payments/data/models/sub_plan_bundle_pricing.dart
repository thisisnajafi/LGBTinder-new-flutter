import 'subscription_plan.dart';

/// Display-only bundle savings for a sub-plan vs paying the monthly rate.
///
/// Does not modify checkout prices — [sellingPrice] is always the API [SubPlan.price].
class SubPlanBundlePricing {
  final SubPlan option;
  final double monthlyUnitPrice;

  const SubPlanBundlePricing._({
    required this.option,
    required this.monthlyUnitPrice,
  });

  factory SubPlanBundlePricing.forOption(
    SubPlan option,
    List<SubPlan> siblings,
  ) {
    final monthly = _monthlyBaseline(siblings);
    return SubPlanBundlePricing._(
      option: option,
      monthlyUnitPrice: monthly?.price ?? option.price,
    );
  }

  static SubPlan? _monthlyBaseline(List<SubPlan> siblings) {
    if (siblings.isEmpty) return null;

    SubPlan? monthly;
    for (final sibling in siblings) {
      if (sibling.monthsCount == 1) return sibling;
      if (monthly == null || sibling.monthsCount < monthly.monthsCount) {
        monthly = sibling;
      }
    }
    return monthly;
  }

  /// Actual price charged at checkout (from API).
  double get sellingPrice => option.price;

  int get months => option.monthsCount;

  /// Monthly rate × months. Null for 1-month options.
  double? get originalPrice {
    if (months <= 1) return null;
    return monthlyUnitPrice * months;
  }

  bool get hasBundleDiscount {
    final original = originalPrice;
    if (original == null || original <= 0) return false;
    return sellingPrice < original - 0.001;
  }

  double get savingsAmount {
    if (!hasBundleDiscount) return 0;
    return originalPrice! - sellingPrice;
  }

  int? get discountPercent {
    if (!hasBundleDiscount) return null;
    final original = originalPrice!;
    return (((original - sellingPrice) / original) * 100).round();
  }
}
