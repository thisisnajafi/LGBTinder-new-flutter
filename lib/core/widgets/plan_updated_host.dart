import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/app_logger.dart';
import '../../core/subscription/plan_updated_bridge.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/user_tier.dart';

/// Listens for Pusher `plan.updated` and shows a membership snackbar.
class PlanUpdatedHost extends ConsumerStatefulWidget {
  const PlanUpdatedHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlanUpdatedHost> createState() => _PlanUpdatedHostState();
}

class _PlanUpdatedHostState extends ConsumerState<PlanUpdatedHost> {
  StreamSubscription<AppSubscriptionStatus>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = PlanUpdatedBridge.stream.listen(_onPlanUpdated);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onPlanUpdated(AppSubscriptionStatus status) async {
    AppLogger.info(
      'plan.updated received: ${status.tier.key} active=${status.isActive}',
      tag: 'PlanUpdated',
    );

    try {
      await ref.read(appCacheManagerProvider).revalidateOwnProfile();
    } catch (e, stack) {
      AppLogger.warning(
        'plan.updated profile refresh failed',
        tag: 'PlanUpdated',
        error: e,
      );
      AppLogger.debug('plan.updated profile stack: $stack', tag: 'PlanUpdated');
    }

    try {
      await ref.read(planLimitsProvider.notifier).refresh();
    } catch (e, stack) {
      AppLogger.warning(
        'plan.updated plan-limits refresh failed',
        tag: 'PlanUpdated',
        error: e,
      );
      AppLogger.debug('plan.updated limits stack: $stack', tag: 'PlanUpdated');
    }

    try {
      await ref.read(subscriptionRefreshProvider).refresh();
    } catch (e, stack) {
      AppLogger.warning(
        'plan.updated subscription refresh failed',
        tag: 'PlanUpdated',
        error: e,
      );
      AppLogger.debug('plan.updated refresh stack: $stack', tag: 'PlanUpdated');
    }

    if (!mounted) return;
    final planLabel = status.planName?.trim();
    final message = status.isActive && planLabel != null && planLabel.isNotEmpty
        ? '🎉 Your $planLabel plan is now active!'
        : 'Your membership was updated';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
