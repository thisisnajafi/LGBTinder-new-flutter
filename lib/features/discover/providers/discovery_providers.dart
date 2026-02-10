import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../payments/data/services/plan_limits_service.dart';
import '../data/services/discovery_service.dart';

/// Discovery Service Provider
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final planLimitsService = ref.watch(planLimitsServiceProvider);
  return DiscoveryService(apiService, cacheService, planLimitsService);
});

/// User IDs the current user has already liked/disliked/superliked this session.
/// Used to filter them out from suggestions after refresh so they don't reappear.
final discoveryActedOnUserIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

