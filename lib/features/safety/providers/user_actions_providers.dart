import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/user_actions_service.dart';

/// User Actions Service Provider
final userActionsServiceProvider = Provider<UserActionsService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserActionsService(apiService);
});

