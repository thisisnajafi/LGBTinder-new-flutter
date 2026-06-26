import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/api_endpoints.dart';
import 'app_logger.dart';

/// Queued user action persisted while offline.
class QueuedAction {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> body;
  final DateTime queuedAt;

  const QueuedAction({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.body,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpoint': endpoint,
        'method': method,
        'body': body,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory QueuedAction.fromJson(Map<String, dynamic> json) => QueuedAction(
        id: json['id'] as String,
        endpoint: json['endpoint'] as String,
        method: json['method'] as String,
        body: Map<String, dynamic>.from(json['body'] as Map),
        queuedAt: DateTime.parse(json['queuedAt'] as String),
      );
}

/// Persists like/dislike/message actions while offline and flushes on reconnect.
class ActionQueueService {
  ActionQueueService._();

  static final ActionQueueService instance = ActionQueueService._();
  static const _queueKey = 'offline:action:queue';
  static const _uuid = Uuid();

  static const Set<String> queueableEndpoints = {
    ApiEndpoints.likesLike,
    ApiEndpoints.likesDislike,
    ApiEndpoints.chatSend,
  };

  bool isQueueableEndpoint(String endpoint) =>
      queueableEndpoints.contains(endpoint);

  Future<void> enqueue(QueuedAction action) async {
    final queue = await _loadQueue();
    queue.add(action);
    await _saveQueue(queue);
    AppLogger.info(
      'Action queued: ${action.method} ${action.endpoint}',
      tag: 'ActionQueue',
    );
  }

  Future<void> enqueuePost({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    await enqueue(
      QueuedAction(
        id: _uuid.v4(),
        endpoint: endpoint,
        method: 'POST',
        body: body,
        queuedAt: DateTime.now(),
      ),
    );
  }

  Future<void> flush(Dio dio) async {
    final queue = await _loadQueue();
    if (queue.isEmpty) return;

    AppLogger.info(
      'Flushing ${queue.length} queued actions',
      tag: 'ActionQueue',
    );

    final succeeded = <String>[];

    for (final action in queue) {
      try {
        await dio.request(
          action.endpoint,
          data: action.body,
          options: Options(method: action.method),
        );
        succeeded.add(action.id);
        AppLogger.info(
          'Queued action sent: ${action.method} ${action.endpoint}',
          tag: 'ActionQueue',
        );
      } catch (e, stack) {
        AppLogger.error(
          'Queued action failed: ${action.method} ${action.endpoint}',
          tag: 'ActionQueue',
          error: e,
          stackTrace: stack,
        );
        break;
      }
    }

    queue.removeWhere((action) => succeeded.contains(action.id));
    await _saveQueue(queue);
  }

  Future<List<QueuedAction>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(_queueKey) ?? [];
    return json
        .map(
          (entry) =>
              QueuedAction.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _saveQueue(List<QueuedAction> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queueKey,
      queue.map((action) => jsonEncode(action.toJson())).toList(),
    );
  }
}
