import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../core/config/pusher_config.dart';
import '../../core/services/app_logger.dart';
import '../../features/chat/data/models/message.dart';

/// Real-time chat via Pusher Channels (replaces socket.io for production).
///
/// Subscribes to:
/// - `private-user.{userId}` — matches / global user events
/// - `private-chat.{userId}` — legacy inbox (dual-publish from backend)
/// - `private-conversation.{id}` — per-thread messages, typing, read receipts
class PusherWebSocketService {
  PusherChannelsFlutter? _pusher;
  Dio? _authDio;
  Future<String?> Function()? _tokenProvider;

  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _readReceiptController = StreamController<ReadReceiptEvent>.broadcast();
  final _messageExpiredController = StreamController<MessageExpiredEvent>.broadcast();
  final _matchController = StreamController<MatchEvent>.broadcast();
  final _callEventController = StreamController<CallSignalingEvent>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final Set<String> _subscribedChannels = {};
  int? _currentUserId;
  bool _isConnected = false;
  bool _isConnecting = false;

  Stream<Message> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<ReadReceiptEvent> get readReceiptStream => _readReceiptController.stream;
  Stream<MessageExpiredEvent> get messageExpiredStream => _messageExpiredController.stream;
  Stream<MatchEvent> get matchStream => _matchController.stream;
  Stream<CallSignalingEvent> get callEventStream => _callEventController.stream;
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  int? get currentUserId => _currentUserId;

  /// Initialize Pusher client (idempotent).
  Future<void> initialize({
    required Future<String?> Function() tokenProvider,
    Dio? authDio,
  }) async {
    if (!PusherConfig.isConfigured) {
      AppLogger.warning(
        'PUSHER_APP_KEY not set — real-time disabled',
        tag: 'Pusher',
      );
      return;
    }

    if (_isConnecting || _isConnected) return;

    _tokenProvider = tokenProvider;
    _authDio = authDio ?? Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _isConnecting = true;
    _connectionController.add(ConnectionStatus.connecting);

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: PusherConfig.appKey,
        cluster: PusherConfig.cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onEvent: _onPusherEvent,
        onSubscriptionSucceeded: (channelName, data) {
          AppLogger.info('Subscribed: $channelName', tag: 'Pusher');
        },
        onSubscriptionError: (message, error) {
          AppLogger.error(
            'Subscription error: $message',
            tag: 'Pusher',
            error: error,
          );
          _errorController.add('Subscription error: $message');
        },
        onAuthorizer: _authorizeChannel,
      );
      await _pusher!.connect();
    } catch (e, stack) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(ConnectionStatus.disconnected);
      AppLogger.error(
        'Failed to initialize Pusher',
        tag: 'Pusher',
        error: e,
        stackTrace: stack,
      );
      _errorController.add('Failed to initialize Pusher: $e');
      rethrow;
    }
  }

  /// Subscribe to user-global channels after login.
  Future<void> connectUser(int userId) async {
    if (_pusher == null) {
      throw StateError('Pusher not initialized');
    }

    _currentUserId = userId;
    await subscribe('private-user.$userId');
    await subscribe('private-chat.$userId');
    AppLogger.info('User channels ready for $userId', tag: 'Pusher');
  }

  /// Subscribe to a 1:1 conversation channel (canonical).
  Future<void> subscribeConversation(int conversationId) async {
    await subscribe('private-conversation.$conversationId');
  }

  Future<void> unsubscribeConversation(int conversationId) async {
    await unsubscribe('private-conversation.$conversationId');
  }

  Future<void> subscribe(String channelName) async {
    if (_pusher == null || _subscribedChannels.contains(channelName)) return;

    try {
      await _pusher!.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);
    } catch (e) {
      _errorController.add('Failed to subscribe $channelName: $e');
      rethrow;
    }
  }

  Future<void> unsubscribe(String channelName) async {
    if (_pusher == null || !_subscribedChannels.contains(channelName)) return;

    try {
      await _pusher!.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
    } catch (e, stack) {
      AppLogger.warning(
        'Unsubscribe failed: $channelName',
        tag: 'Pusher',
        error: e,
      );
      AppLogger.debug('Unsubscribe stack: $stack', tag: 'Pusher');
    }
  }

  Future<void> disconnect() async {
    for (final name in _subscribedChannels.toList()) {
      await unsubscribe(name);
    }
    await _pusher?.disconnect();
    _isConnected = false;
    _isConnecting = false;
    _currentUserId = null;
    _connectionController.add(ConnectionStatus.disconnected);
  }

  void dispose() {
    unawaited(disconnect());
    _messageController.close();
    _typingController.close();
    _readReceiptController.close();
    _messageExpiredController.close();
    _matchController.close();
    _callEventController.close();
    _connectionController.close();
    _errorController.close();
  }

  Future<dynamic> _authorizeChannel(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final token = await _tokenProvider?.call();
    if (token == null || token.isEmpty) {
      throw Exception('No auth token for Pusher');
    }

    final dio = _authDio!;
    final response = await dio.post<Map<String, dynamic>>(
      PusherConfig.authEndpoint,
      data: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty broadcasting auth response');
    }
    return data;
  }

  void _onPusherEvent(PusherEvent event) {
    if (event.data == null || event.data!.isEmpty) return;

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(event.data!);
      payload = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      AppLogger.warning(
        'Invalid JSON for ${event.eventName}',
        tag: 'Pusher',
        error: e,
      );
      return;
    }

    switch (event.eventName) {
      case 'MessageSent':
      case 'message.sent':
        _handleMessageSent(payload);
        break;
      case 'MessageRead':
      case 'message.read':
        _handleMessageRead(payload);
        break;
      case 'UserTyping':
      case 'user.typing':
        _handleUserTyping(payload, isTyping: true);
        break;
      case 'UserStoppedTyping':
      case 'user.stopped_typing':
        _handleUserTyping(payload, isTyping: false);
        break;
      case 'MessageDeleted':
      case 'message.deleted':
        break;
      case 'MessageExpired':
      case 'message.expired':
        _handleMessageExpired(payload);
        break;
      case 'call.incoming':
      case 'call.accepted':
      case 'call.rejected':
      case 'call.ended':
      case 'call.busy':
        _callEventController.add(CallSignalingEvent(
          name: event.eventName,
          payload: payload,
        ));
        break;
      default:
        if (event.eventName.contains('Match') ||
            event.eventName == 'match.created' ||
            event.eventName == 'new_match') {
          _handleNewMatch(payload);
        }
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      final messageData = data['message'];
      if (messageData is Map) {
        final message = Message.fromJson(
          Map<String, dynamic>.from(messageData),
        );
        if (message.isValid) {
          _messageController.add(message);
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Parse MessageSent failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final ids = <int>[];
      final rawIds = data['message_ids'];
      if (rawIds is List) {
        for (final id in rawIds) {
          final parsed = int.tryParse(id.toString());
          if (parsed != null) ids.add(parsed);
        }
      }
      final singleId = int.tryParse(data['message_id']?.toString() ?? '');
      if (singleId != null && !ids.contains(singleId)) {
        ids.add(singleId);
      }

      _readReceiptController.add(ReadReceiptEvent(
        conversationId: int.tryParse(data['conversation_id']?.toString() ?? ''),
        readerId: int.tryParse(data['reader_id']?.toString() ?? '') ?? 0,
        messageIds: ids,
        readAt: DateTime.tryParse(data['read_at']?.toString() ?? '') ??
            DateTime.now(),
      ));
    } catch (e) {
      AppLogger.warning(
        'Parse MessageRead failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleUserTyping(Map<String, dynamic> data, {required bool isTyping}) {
    try {
      _typingController.add(TypingEvent(
        userId: int.tryParse(data['user_id']?.toString() ?? '') ?? 0,
        conversationId:
            int.tryParse(data['conversation_id']?.toString() ?? ''),
        isTyping: data['is_typing'] == false ? false : isTyping,
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      ));
    } catch (e) {
      AppLogger.warning(
        'Parse typing failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleMessageExpired(Map<String, dynamic> data) {
    try {
      final messageId = int.tryParse(data['message_id']?.toString() ?? '');
      if (messageId == null) return;

      _messageExpiredController.add(MessageExpiredEvent(
        messageId: messageId,
        conversationId: int.tryParse(data['conversation_id']?.toString() ?? ''),
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      ));
    } catch (e) {
      AppLogger.warning(
        'Parse MessageExpired failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleNewMatch(Map<String, dynamic> data) {
    _matchController.add(MatchEvent(
      matchId: int.tryParse(data['match_id']?.toString() ?? '') ??
          int.tryParse(data['id']?.toString() ?? ''),
      userId: int.tryParse(data['user_id']?.toString() ?? ''),
      timestamp: DateTime.now(),
    ));
  }

  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    final state = currentState?.toString() ?? '';
    AppLogger.info(
      '$previousState → $state',
      tag: 'Pusher',
    );

    switch (state) {
      case 'CONNECTED':
        _isConnected = true;
        _isConnecting = false;
        _connectionController.add(ConnectionStatus.connected);
        break;
      case 'DISCONNECTED':
        _isConnected = false;
        _isConnecting = false;
        _connectionController.add(ConnectionStatus.disconnected);
        break;
      case 'CONNECTING':
      case 'RECONNECTING':
        _connectionController.add(ConnectionStatus.reconnecting);
        break;
    }
  }

  void _onError(String message, int? code, dynamic e) {
    AppLogger.error(
      'Connection error: $message ($code)',
      tag: 'Pusher',
      error: e,
    );
    _errorController.add(message);
  }
}

class MatchEvent {
  final int? matchId;
  final int? userId;
  final DateTime timestamp;

  MatchEvent({
    this.matchId,
    this.userId,
    required this.timestamp,
  });
}

class TypingEvent {
  final int userId;
  final int? conversationId;
  final bool isTyping;
  final DateTime timestamp;

  TypingEvent({
    required this.userId,
    this.conversationId,
    required this.isTyping,
    required this.timestamp,
  });
}

class ReadReceiptEvent {
  final int? conversationId;
  final int readerId;
  final List<int> messageIds;
  final DateTime readAt;

  ReadReceiptEvent({
    this.conversationId,
    required this.readerId,
    required this.messageIds,
    required this.readAt,
  });
}

class MessageExpiredEvent {
  final int messageId;
  final int? conversationId;
  final DateTime timestamp;

  MessageExpiredEvent({
    required this.messageId,
    this.conversationId,
    required this.timestamp,
  });
}

class CallSignalingEvent {
  final String name;
  final Map<String, dynamic> payload;

  CallSignalingEvent({required this.name, required this.payload});
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

