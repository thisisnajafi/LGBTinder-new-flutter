import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Model for queued offline request
class QueuedRequest {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final DateTime createdAt;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.endpoint,
    this.data,
    this.queryParameters,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'endpoint': endpoint,
      'data': data,
      'queryParameters': queryParameters,
      'createdAt': createdAt.toIso8601String(),
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
    );
  }
}

/// Service for managing offline request queue
class OfflineQueueService {
  static const String _queueKey = 'offline_request_queue';
  static const int _maxQueueSize = 100;

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
}

