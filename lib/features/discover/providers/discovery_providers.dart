import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/discovery_service.dart';

/// Discovery Service Provider
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DiscoveryService(apiService);
});

