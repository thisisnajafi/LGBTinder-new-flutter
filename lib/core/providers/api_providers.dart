import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/token_storage_service.dart';
import '../../core/network/dio_client.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/connectivity_service.dart';
import '../../shared/services/cache_service.dart';
import '../../shared/services/offline_queue_service.dart';
import '../../shared/services/sync_service.dart';
import '../../shared/services/error_handler_service.dart';
import '../../shared/services/landing_service.dart';
import '../../shared/services/locale_api_service.dart';
import '../../shared/services/token_api_service.dart';
import '../../shared/services/ticket_api_service.dart';
import '../../shared/services/safety_api_service.dart';
import '../../shared/services/referral_api_service.dart';
import '../../shared/services/session_api_service.dart';
import '../../shared/services/account_api_service.dart';
import '../../shared/services/call_management_api_service.dart';
import '../../shared/services/onesignal_api_service.dart';

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

/// Landing Service Provider (public landing API)
final landingServiceProvider = Provider<LandingService>((ref) {
  return LandingService(ref.watch(apiServiceProvider));
});

/// Locale API Service Provider (GET/PUT locales, translations)
final localeApiServiceProvider = Provider<LocaleApiService>((ref) {
  return LocaleApiService(ref.watch(apiServiceProvider));
});

/// Token API Service Provider (GET/DELETE tokens — list, current, validate, revoke)
final tokenApiServiceProvider = Provider<TokenApiService>((ref) {
  return TokenApiService(ref.watch(apiServiceProvider));
});

/// Ticket API Service Provider (GET/POST tickets — list, get by id, create)
final ticketApiServiceProvider = Provider<TicketApiService>((ref) {
  return TicketApiService(ref.watch(apiServiceProvider));
});

/// Safety API Service Provider (GET safety/guidelines)
final safetyApiServiceProvider = Provider<SafetyApiService>((ref) {
  return SafetyApiService(ref.watch(apiServiceProvider));
});

/// Referral API Service Provider (referrals stats, code, history, tiers, validate, etc.)
final referralApiServiceProvider = Provider<ReferralApiService>((ref) {
  return ReferralApiService(ref.watch(apiServiceProvider));
});

/// Session API Service Provider (sessions/store, activity, revoke)
final sessionApiServiceProvider = Provider<SessionApiService>((ref) {
  return SessionApiService(ref.watch(apiServiceProvider));
});

/// Account API Service Provider (account/change-email, change-password, reactivate)
final accountApiServiceProvider = Provider<AccountApiService>((ref) {
  return AccountApiService(ref.watch(apiServiceProvider));
});

/// Call Management API Service Provider (initiate, accept, reject, end, history, statistics)
final callManagementApiServiceProvider = Provider<CallManagementApiService>((ref) {
  return CallManagementApiService(ref.watch(apiServiceProvider));
});

/// OneSignal API Service Provider (update/remove player-id, notification-info, preferences, delivery-status)
final oneSignalApiServiceProvider = Provider<OneSignalApiService>((ref) {
  return OneSignalApiService(ref.watch(apiServiceProvider));
});

/// Error Handler Service Provider (static methods, no instance needed)
/// Usage: ErrorHandlerService.handleError(context, error, onRetry: () {})

