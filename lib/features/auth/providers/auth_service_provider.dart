import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  final dioClient = ref.watch(dioClientProvider);
  return AuthService(apiService, tokenStorage, dioClient);
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService);
});

