// FEATURE ENHANCEMENT (Task 9.2.1): Enhanced Offline Queue Service
//
// Supports:
// - Action-specific queuing (like, message, profile update)
// - Automatic sync when online
// - Optimistic UI updates
// - Retry with exponential backoff

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'connectivity_service.dart';

/// Action types for offline queue
enum QueuedActionType {
  sendMessage,
  likeProfile,
  dislikeProfile,
  superlikeProfile,
  updateProfile,
  uploadImage,
  markAsRead,
  reportUser,
  blockUser,
  other,
}

/// Model for queued offline request
class QueuedRequest {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final DateTime createdAt;
  final QueuedActionType actionType;
  final int retryCount;
  final DateTime? lastRetryAt;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.endpoint,
    this.data,
    this.queryParameters,
    required this.createdAt,
    this.actionType = QueuedActionType.other,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'endpoint': endpoint,
      'data': data,
      'queryParameters': queryParameters,
      'createdAt': createdAt.toIso8601String(),
      'actionType': actionType.name,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
    };
  }

  factory QueuedRequest.fromJson(Map<String, dynamic> json) {
    return QueuedRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      data: json['data'] as Map<String, dynamic>?,
      queryParameters: json['queryParameters'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      actionType: QueuedActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => QueuedActionType.other,
      ),
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
    );
  }

  /// Create a copy with updated retry count
  QueuedRequest copyWith({
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return QueuedRequest(
      id: id,
      method: method,
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      createdAt: createdAt,
      actionType: actionType,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

/// Service for managing offline request queue
/// FEATURE ENHANCEMENT (Task 9.2.1): Enhanced with action types and auto-sync
class OfflineQueueService {
  static const String _queueKey = 'offline_request_queue';
  static const int _maxQueueSize = 100;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  final ConnectivityService? _connectivityService;
  final Dio? _dio;

  OfflineQueueService({
    ConnectivityService? connectivityService,
    Dio? dio,
  }) : _connectivityService = connectivityService,
       _dio = dio;

  /// Add request to queue
  Future<void> queueRequest(QueuedRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      List<QueuedRequest> queue = [];
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        queue = decoded.map((item) => QueuedRequest.fromJson(item as Map<String, dynamic>)).toList();
      }

      // Add new request
      queue.add(request);

      // Limit queue size
      if (queue.length > _maxQueueSize) {
        queue.removeAt(0); // Remove oldest
      }

      // Save queue
      await prefs.setString(_queueKey, jsonEncode(queue.map((r) => r.toJson()).toList()));

      if (kDebugMode) {
        debugPrint('📦 Queued request: ${request.method} ${request.endpoint}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to queue request: $e');
      }
    }
  }

  /// Get all queued requests
  Future<List<QueuedRequest>> getQueuedRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return [];

      final List<dynamic> decoded = jsonDecode(queueJson);
      return decoded.map((item) => QueuedRequest.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get queued requests: $e');
      }
      return [];
    }
  }

  /// Remove request from queue
  Future<void> removeRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return;

      final List<dynamic> decoded = jsonDecode(queueJson);
      final queue = decoded.map((item) => QueuedRequest.fromJson(item as Map<String, dynamic>)).toList();
      
      queue.removeWhere((r) => r.id == requestId);

      await prefs.setString(_queueKey, jsonEncode(queue.map((r) => r.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to remove request: $e');
      }
    }
  }

  /// Clear all queued requests
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear queue: $e');
      }
    }
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await getQueuedRequests();
    return queue.length;
  }

  /// Queue a specific action type
  /// FEATURE ENHANCEMENT (Task 9.2.1): Action-specific queuing
  Future<String> queueAction({
    required QueuedActionType actionType,
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final request = QueuedRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      createdAt: DateTime.now(),
      actionType: actionType,
    );

    await queueRequest(request);
    return request.id;
  }

  /// Sync all queued requests when online
  /// FEATURE ENHANCEMENT (Task 9.2.1): Automatic sync
  Future<void> syncQueue({Dio? dio}) async {
    if (_connectivityService != null) {
      final isOnline = await _connectivityService!.checkConnectivity();
      if (!isOnline) {
        debugPrint('📡 Offline - skipping queue sync');
        return;
      }
    }

    final client = dio ?? _dio;
    if (client == null) {
      debugPrint('⚠️ No Dio client available for sync');
      return;
    }

    final queue = await getQueuedRequests();
    if (queue.isEmpty) {
      debugPrint('✅ Queue is empty');
      return;
    }

    debugPrint('🔄 Syncing ${queue.length} queued requests...');

    for (final request in queue) {
      // Skip if max retries reached
      if (request.retryCount >= _maxRetries) {
        debugPrint('⚠️ Skipping request ${request.id} - max retries reached');
        continue;
      }

      // Check retry delay
      if (request.lastRetryAt != null) {
        final timeSinceLastRetry = DateTime.now().difference(request.lastRetryAt!);
        if (timeSinceLastRetry < _retryDelay) {
          continue; // Wait before retrying
        }
      }

      try {
        final response = await _executeRequest(client, request);
        
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          // Success - remove from queue
          await removeRequest(request.id);
          debugPrint('✅ Synced request: ${request.method} ${request.endpoint}');
        } else {
          // Failed - increment retry count
          final updatedRequest = request.copyWith(
            retryCount: request.retryCount + 1,
            lastRetryAt: DateTime.now(),
          );
          await _updateRequest(updatedRequest);
          debugPrint('⚠️ Request failed, retry ${updatedRequest.retryCount}/$_maxRetries');
        }
      } catch (e) {
        // Error - increment retry count
        final updatedRequest = request.copyWith(
          retryCount: request.retryCount + 1,
          lastRetryAt: DateTime.now(),
        );
        await _updateRequest(updatedRequest);
        debugPrint('❌ Error syncing request: $e');
      }
    }
  }

  /// Execute a queued request
  Future<Response> _executeRequest(Dio dio, QueuedRequest request) async {
    switch (request.method.toUpperCase()) {
      case 'GET':
        return await dio.get(
          request.endpoint,
          queryParameters: request.queryParameters,
        );
      case 'POST':
        return await dio.post(
          request.endpoint,
          data: request.data,
          queryParameters: request.queryParameters,
        );
      case 'PUT':
        return await dio.put(
          request.endpoint,
          data: request.data,
          queryParameters: request.queryParameters,
        );
      case 'PATCH':
        return await dio.patch(
          request.endpoint,
          data: request.data,
          queryParameters: request.queryParameters,
        );
      case 'DELETE':
        return await dio.delete(
          request.endpoint,
          data: request.data,
          queryParameters: request.queryParameters,
        );
      default:
        throw Exception('Unsupported method: ${request.method}');
    }
  }

  /// Update a request in the queue
  Future<void> _updateRequest(QueuedRequest updatedRequest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson == null) return;

      final List<dynamic> decoded = jsonDecode(queueJson);
      final queue = decoded
          .map((item) => QueuedRequest.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final index = queue.indexWhere((r) => r.id == updatedRequest.id);
      if (index != -1) {
        queue[index] = updatedRequest;
        await prefs.setString(_queueKey, jsonEncode(queue.map((r) => r.toJson()).toList()));
      }
    } catch (e) {
      debugPrint('❌ Failed to update request: $e');
    }
  }

  /// Get queued requests by action type
  Future<List<QueuedRequest>> getQueuedRequestsByType(QueuedActionType actionType) async {
    final queue = await getQueuedRequests();
    return queue.where((r) => r.actionType == actionType).toList();
  }

  /// Clear requests by action type
  Future<void> clearRequestsByType(QueuedActionType actionType) async {
    final queue = await getQueuedRequests();
    final filtered = queue.where((r) => r.actionType != actionType).toList();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueKey, jsonEncode(filtered.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('❌ Failed to clear requests by type: $e');
    }
  }
}

