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

