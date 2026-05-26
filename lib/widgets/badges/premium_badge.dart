// Widget: PremiumBadge — delegates to TierBadge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/widgets/tier_badge.dart';
import '../../shared/models/user_tier.dart';

class PremiumBadge extends ConsumerWidget {
  final bool isPremium;
  final UserTier? tier;
  final double? fontSize;

  const PremiumBadge({
    super.key,
    required this.isPremium,
    this.tier,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isPremium && tier == null) return const SizedBox.shrink();
    return TierBadge(
      tier: tier ?? (isPremium ? UserTier.silder : UserTier.basid),
    );
  }
}
