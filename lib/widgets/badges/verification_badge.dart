// Widget: VerificationBadge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../verification/verification_components.dart';

/// Compact verified badge for profile cards and headers.
class VerificationBadge extends ConsumerWidget {
  final bool isVerified;
  final String? badgeLabel;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.badgeLabel,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = badgeLabel ?? (isVerified ? 'Verified' : 'Unverified');

    if (label == 'Unverified' && !isVerified) {
      return const SizedBox.shrink();
    }

    return VerificationBadgeChip(badge: label, compact: size < 24);
  }
}
