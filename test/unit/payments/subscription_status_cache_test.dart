import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/providers/payment_providers.dart';
import 'package:lgbtindernew/shared/models/subscription_status.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

void main() {
  test('cached subscription snapshot maps onto payments status', () {
    final cached = AppSubscriptionStatus(
      tier: UserTier.silder,
      isActive: true,
      isPremium: true,
      planName: 'Premium',
      expiresAt: DateTime(2026, 10, 1),
      superlikesRemaining: 3,
      features: SubscriptionFeatures.free(),
      refreshedAt: DateTime(2026, 9, 12),
    );

    final mapped = subscriptionStatusFromAppCache(cached);
    expect(mapped, isNotNull);
    expect(mapped!.isActive, isTrue);
    expect(mapped.planName, 'Premium');
    expect(mapped.tier, UserTier.silder.key);
    expect(mapped.endDate, DateTime(2026, 10, 1));
  });

  test('null cache maps to null status', () {
    expect(subscriptionStatusFromAppCache(null), isNull);
  });
}
