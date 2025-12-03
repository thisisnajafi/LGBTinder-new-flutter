import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/token_storage_service.dart';
import '../../core/network/dio_client.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/connectivity_service.dart';
import '../../shared/services/cache_service.dart';
import '../../shared/services/offline_queue_service.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/error_handler_service.dart';

/// Token Storage Service Provider
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Connectivity Service Provider (singleton)
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  // Initialize on first access
  service.initialize();
  // Dispose when provider is disposed
  ref.onDispose(() => service.dispose());
  return service;
});

/// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Offline Queue Service Provider
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

/// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final queueService = ref.watch(offlineQueueServiceProvider);
  final dioClient = ref.watch(dioClientProvider);
  
  final syncService = SyncService(queueService, connectivityService, dioClient);
  // Initialize sync service to listen for connectivity changes
  syncService.initialize();
  
  return syncService;
});

/// Dio Client Provider
final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return DioClient(tokenStorage);
});

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final queueService = ref.watch(offlineQueueServiceProvider);
  
  return ApiService(dioClient, connectivityService, cacheService, queueService);
});

/// Error Handler Service Provider (static methods, no instance needed)
/// Usage: ErrorHandlerService.handleError(context, error, onRetry: () {})

