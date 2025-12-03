import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';
import '../../core/network/dio_client.dart';

/// Service for syncing queued requests when back online
class SyncService {
  final OfflineQueueService _queueService;
  final ConnectivityService _connectivityService;
  final DioClient _dioClient;
  bool _isSyncing = false;

  SyncService(
    this._queueService,
    this._connectivityService,
    this._dioClient,
  );

  /// Start syncing queued requests
  Future<void> syncQueuedRequests() async {
    if (_isSyncing) {
      if (kDebugMode) {
        debugPrint('⏳ Sync already in progress');
      }
      return;
    }

    if (!_connectivityService.isOnline) {
      if (kDebugMode) {
        debugPrint('📡 Device is offline, cannot sync');
      }
      return;
    }

    _isSyncing = true;

    try {
      final queue = await _queueService.getQueuedRequests();
      
      if (queue.isEmpty) {
        if (kDebugMode) {
          debugPrint('✅ No queued requests to sync');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Syncing ${queue.length} queued requests...');
      }

      final successful = <String>[];
      final failed = <QueuedRequest>[];

      for (final request in queue) {
        try {
          // Check connectivity before each request
          if (!_connectivityService.isOnline) {
            if (kDebugMode) {
              debugPrint('📡 Lost connectivity during sync');
            }
            break;
          }

          // Execute the request
          Response response;
          switch (request.method.toUpperCase()) {
            case 'GET':
              response = await _dioClient.dio.get(
                request.endpoint,
                queryParameters: request.queryParameters,
              );
              break;
            case 'POST':
              response = await _dioClient.dio.post(
                request.endpoint,
                data: request.data,
                queryParameters: request.queryParameters,
              );
              break;
            case 'PUT':
              response = await _dioClient.dio.put(
                request.endpoint,
                data: request.data,
                queryParameters: request.queryParameters,
              );
              break;
            case 'DELETE':
              response = await _dioClient.dio.delete(
                request.endpoint,
                data: request.data,
                queryParameters: request.queryParameters,
              );
              break;
            default:
              if (kDebugMode) {
                debugPrint('⚠️ Unsupported method: ${request.method}');
              }
              continue;
          }

          // Check if request was successful
          if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
            successful.add(request.id);
            if (kDebugMode) {
              debugPrint('✅ Synced request: ${request.method} ${request.endpoint}');
            }
          } else {
            failed.add(request);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Failed to sync request ${request.id}: $e');
          }
          failed.add(request);
        }
      }

      // Remove successful requests from queue
      for (final id in successful) {
        await _queueService.removeRequest(id);
      }

      if (kDebugMode) {
        debugPrint('✅ Sync completed: ${successful.length} successful, ${failed.length} failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sync error: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Initialize sync service - listen for connectivity changes
  void initialize() {
    _connectivityService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        // Device came back online, sync queued requests
        syncQueuedRequests();
      }
    });
  }
}

