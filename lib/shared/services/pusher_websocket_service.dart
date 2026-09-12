import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/pusher_config.dart';
import '../../core/services/app_logger.dart';
import '../../core/utils/app_date_time.dart';
import '../../features/calls/utils/call_signaling_log.dart';
import '../../features/chat/data/models/message.dart';
import '../../features/chat/utils/chat_message_sent_payload.dart';
import '../../features/chat/utils/chat_pusher_log.dart';
import '../../features/chat/utils/chat_reaction_summary.dart';
import '../../core/network/subscription_meta_sync.dart';
import '../../core/subscription/plan_updated_bridge.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/user_tier.dart';
import 'chat_pusher_event_names.dart';
import 'pusher_auth_response.dart';

/// Real-time chat via Pusher Channels (replaces socket.io for production).
///
/// Subscribes to:
/// - `private-user.{userId}` — matches / global user events
/// - `private-chat.{userId}` — legacy inbox (dual-publish from backend)
/// - `private-conversation.{id}` — per-thread messages, typing, read receipts
/// - `private-call.{id}` — call signaling for an active call
/// - `private-user.status.{peerId}` — matched peers' online / last-seen updates
class PusherWebSocketService {
  PusherChannelsFlutter? _pusher;
  Dio? _authDio;
  Future<String?> Function()? _tokenProvider;

  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _readReceiptController = StreamController<ReadReceiptEvent>.broadcast();
  final _messageExpiredController = StreamController<MessageExpiredEvent>.broadcast();
  final _messageDeletedController = StreamController<MessageDeletedEvent>.broadcast();
  final _messageEditedController = StreamController<MessageEditedEvent>.broadcast();
  final _messageReactedController = StreamController<MessageReactedEvent>.broadcast();
  final _messageDeliveredController = StreamController<MessageDeliveredEvent>.broadcast();
  final _matchController = StreamController<MatchEvent>.broadcast();
  final _likeController = StreamController<LikeEvent>.broadcast();
  final _callEventController = StreamController<CallSignalingEvent>.broadcast();
  final _presenceController = StreamController<UserPresenceEvent>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final Set<String> _subscribedChannels = {};
  final Map<String, Future<void>> _pendingSubscribes = {};
  final Map<String, Future<void>> _pendingUnsubscribes = {};
  final Set<int> _statusUserIds = {};
  int? _currentUserId;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectedKey;
  bool _recoveringKey = false;

  Stream<Message> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<ReadReceiptEvent> get readReceiptStream => _readReceiptController.stream;
  Stream<MessageExpiredEvent> get messageExpiredStream => _messageExpiredController.stream;
  Stream<MessageDeletedEvent> get messageDeletedStream => _messageDeletedController.stream;
  Stream<MessageEditedEvent> get messageEditedStream => _messageEditedController.stream;
  Stream<MessageReactedEvent> get messageReactedStream =>
      _messageReactedController.stream;
  Stream<MessageDeliveredEvent> get messageDeliveredStream =>
      _messageDeliveredController.stream;
  Stream<MatchEvent> get matchStream => _matchController.stream;
  Stream<LikeEvent> get likeStream => _likeController.stream;
  Stream<CallSignalingEvent> get callEventStream => _callEventController.stream;
  Stream<UserPresenceEvent> get presenceStream => _presenceController.stream;
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  ConnectionStatus get connectionStatus => _connectionStatus;

  bool get isConnected => _isConnected;
  int? get currentUserId => _currentUserId;

  void _emitConnection(ConnectionStatus status) {
    _connectionStatus = status;
    if (!_connectionController.isClosed) {
      _connectionController.add(status);
    }
  }

  /// Initialize Pusher client (idempotent).
  Future<void> initialize({
    required Future<String?> Function() tokenProvider,
    Dio? authDio,
  }) async {
    _tokenProvider = tokenProvider;
    _authDio = authDio ??
        _authDio ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

    await _syncRemoteCredentials();

    if (!PusherConfig.isConfigured) {
      AppLogger.warning(
        'PUSHER_APP_KEY not set — real-time disabled',
        tag: 'Pusher',
      );
      return;
    }

    if ((_isConnecting || _isConnected) &&
        _connectedKey == PusherConfig.appKey) {
      return;
    }

    if (_isConnected || _pusher != null) {
      await disconnect(clearToken: false);
    }

    _isConnecting = true;
    _emitConnection(ConnectionStatus.connecting);

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
          _maybeRecoverFromAuthError(message);
        },
        onAuthorizer: _authorizeChannel,
      );
      _connectedKey = PusherConfig.appKey;
      await _pusher!.connect();
    } catch (e, stack) {
      _isConnecting = false;
      _isConnected = false;
      _connectedKey = null;
      _emitConnection(ConnectionStatus.disconnected);
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

  Future<void> subscribeCall(int callId) async {
    if (callId <= 0) return;
    await subscribe('private-call.$callId');
  }

  Future<void> unsubscribeCall(int callId) async {
    if (callId <= 0) return;
    await unsubscribe('private-call.$callId');
  }

  /// Subscribe to a matched peer's presence channel.
  Future<void> subscribeUserStatus(int userId) async {
    if (userId <= 0 || userId == _currentUserId || _statusUserIds.contains(userId)) {
      return;
    }

    AppLogger.info(
      'Subscribing to presence channel: private-user.status.$userId',
      tag: 'Pusher',
    );
    try {
      await subscribe('private-user.status.$userId');
      _statusUserIds.add(userId);
      AppLogger.info('Presence channel subscribed: $userId', tag: 'Pusher');
    } catch (e, stack) {
      AppLogger.error(
        'Presence channel subscription failed: $userId',
        tag: 'Pusher',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> unsubscribeUserStatus(int userId) async {
    if (!_statusUserIds.contains(userId)) return;

    await unsubscribe('private-user.status.$userId');
    _statusUserIds.remove(userId);
  }

  /// Align presence subscriptions with the current chat list peers.
  Future<void> syncUserStatusSubscriptions(Set<int> userIds) async {
    final valid = userIds
        .where((id) => id > 0 && id != _currentUserId)
        .toSet();
    final toAdd = valid.difference(_statusUserIds);
    final toRemove = _statusUserIds.difference(valid);

    for (final id in toRemove) {
      await unsubscribeUserStatus(id);
    }
    for (final id in toAdd) {
      await subscribeUserStatus(id);
    }
  }

  bool isSubscribed(String channelName) =>
      _subscribedChannels.contains(channelName);

  Future<void> subscribe(String channelName) async {
    if (_pusher == null) return;

    final pendingUnsub = _pendingUnsubscribes[channelName];
    if (pendingUnsub != null) {
      try {
        await pendingUnsub;
      } catch (e) {
        AppLogger.warning(
          'Pending unsubscribe wait failed for $channelName',
          tag: 'Pusher',
          error: e,
        );
      }
    }

    if (_subscribedChannels.contains(channelName)) return;

    final inFlight = _pendingSubscribes[channelName];
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _subscribeNow(channelName);
    _pendingSubscribes[channelName] = future;
    try {
      await future;
    } finally {
      _pendingSubscribes.remove(channelName);
    }
  }

  Future<void> _subscribeNow(String channelName) async {
    if (_subscribedChannels.contains(channelName)) return;
    try {
      await _pusher!.subscribe(channelName: channelName);
      _subscribedChannels.add(channelName);
    } catch (e) {
      if (_isMissingSubscriptionError(e)) {
        AppLogger.warning(
          'Subscribe skipped, channel not ready: $channelName',
          tag: 'Pusher',
          error: e,
        );
        return;
      }
      _errorController.add('Failed to subscribe $channelName: $e');
      rethrow;
    }
  }

  Future<void> unsubscribe(String channelName) async {
    if (_pusher == null) return;

    final inFlight = _pendingSubscribes[channelName];
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (e) {
        AppLogger.warning(
          'In-flight subscribe wait failed for $channelName',
          tag: 'Pusher',
          error: e,
        );
      }
    }

    if (!_subscribedChannels.contains(channelName)) return;

    Future<void> run() async {
      try {
        await _pusher!.unsubscribe(channelName: channelName);
      } catch (e, stack) {
        if (!_isMissingSubscriptionError(e)) {
          AppLogger.warning(
            'Unsubscribe failed: $channelName',
            tag: 'Pusher',
            error: e,
          );
          AppLogger.debug('Unsubscribe stack: $stack', tag: 'Pusher');
        }
      } finally {
        _subscribedChannels.remove(channelName);
      }
    }

    final future = run();
    _pendingUnsubscribes[channelName] = future;
    try {
      await future;
    } finally {
      _pendingUnsubscribes.remove(channelName);
    }
  }

  static bool _isMissingSubscriptionError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('no current subscription') ||
        text.contains('subscription in progress');
  }

  Future<void> disconnect({bool clearToken = true}) async {
    if (_pusher == null && !_isConnected && !_isConnecting) {
      if (clearToken) {
        _tokenProvider = null;
      }
      return;
    }
    for (final name in _subscribedChannels.toList()) {
      await unsubscribe(name);
    }
    await _pusher?.disconnect();
    _pusher = null;
    _isConnected = false;
    _isConnecting = false;
    _connectedKey = null;
    _currentUserId = null;
    _statusUserIds.clear();
    if (clearToken) {
      _tokenProvider = null;
    }
    _emitConnection(ConnectionStatus.disconnected);
  }

  void dispose() {
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    try {
      await disconnect();
    } catch (e) {
      AppLogger.warning(
        'Pusher disconnect on dispose failed',
        tag: 'Pusher',
        error: e,
      );
    }
    await Future.wait<void>([
      _messageController.close(),
      _typingController.close(),
      _readReceiptController.close(),
      _messageExpiredController.close(),
      _messageDeletedController.close(),
      _messageEditedController.close(),
      _messageReactedController.close(),
      _messageDeliveredController.close(),
      _matchController.close(),
      _likeController.close(),
      _callEventController.close(),
      _presenceController.close(),
      _connectionController.close(),
      _errorController.close(),
    ]);
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
    final auth = PusherAuthResponse.toNativeAuth(data);
    if (auth == null) {
      throw Exception('Empty broadcasting auth response');
    }

    final signedKey = PusherAuthResponse.appKeyFromAuth(auth);
    if (signedKey != null && signedKey != PusherConfig.appKey) {
      AppLogger.warning(
        'Pusher auth key mismatch: server=$signedKey client=${PusherConfig.appKey}',
        tag: 'Pusher',
      );
      PusherConfig.applyRemote(key: signedKey);
      unawaited(_recoverWithServerKey());
    }
    return auth;
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

    final eventName = ChatPusherEventNames.canonicalize(
      event.eventName.replaceFirst(RegExp(r'^\.'), ''),
    );

    switch (eventName) {
      case ChatPusherEventNames.messageSent:
        _handleMessageSent(payload);
        break;
      case ChatPusherEventNames.messageRead:
        _handleMessageRead(payload);
        break;
      case ChatPusherEventNames.userTyping:
        _handleUserTyping(payload, isTyping: true);
        break;
      case ChatPusherEventNames.userStoppedTyping:
        _handleUserTyping(payload, isTyping: false);
        break;
      case ChatPusherEventNames.messageDeleted:
        _handleMessageDeleted(payload);
        break;
      case ChatPusherEventNames.messageEdited:
        _handleMessageEdited(payload);
        break;
      case ChatPusherEventNames.messageReacted:
        _handleMessageReacted(payload);
        break;
      case ChatPusherEventNames.messageDelivered:
        _handleMessageDelivered(payload);
        break;
      case ChatPusherEventNames.messageExpired:
        _handleMessageExpired(payload);
        break;
      case ChatPusherEventNames.screenshotDetected:
        _handleScreenshotDetected(payload);
        break;
      case ChatPusherEventNames.callIncoming:
      case ChatPusherEventNames.callAccepted:
      case ChatPusherEventNames.callRejected:
      case ChatPusherEventNames.callEnded:
      case ChatPusherEventNames.callBusy:
        CallSignalingLog.logEvent(eventName, payload);
        _callEventController.add(CallSignalingEvent(
          name: eventName,
          payload: payload,
        ));
        break;
      case ChatPusherEventNames.userStatus:
        _handleUserPresence(payload);
        break;
      case ChatPusherEventNames.newMatch:
        _handleNewMatch(payload);
        break;
      case ChatPusherEventNames.newLike:
        _handleNewLike(payload);
        break;
      case ChatPusherEventNames.planUpdated:
        _handlePlanUpdated(payload);
        break;
      default:
        if (eventName.toLowerCase().contains('match')) {
          _handleNewMatch(payload);
        } else {
          AppLogger.debug(
            'Unhandled Pusher event: $eventName',
            tag: ChatPusherLog.tag,
          );
        }
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      final messageJson = ChatMessageSentPayload.messageJson(data);
      if (messageJson == null) return;

      final message = Message.fromJson(messageJson);
      if (message.isValid) {
        ChatPusherLog.logEvent(
          eventType: ChatPusherEventNames.messageSent,
          conversationId: message.conversationId,
          body: message.message,
        );
        _messageController.add(message);
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
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.messageRead,
        conversationId: ChatPusherLog.conversationIdOf(data),
      );
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
      ChatPusherLog.logEvent(
        eventType: isTyping
            ? ChatPusherEventNames.userTyping
            : ChatPusherEventNames.userStoppedTyping,
        conversationId: ChatPusherLog.conversationIdOf(data),
      );
    } catch (e) {
      AppLogger.warning(
        'Parse typing failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    try {
      final nested = data['data'] ?? data;
      final map = nested is Map<String, dynamic>
          ? nested
          : (nested is Map ? Map<String, dynamic>.from(nested) : data);
      final messageId = int.tryParse(map['message_id']?.toString() ?? '');
      if (messageId == null || messageId <= 0) return;
      _messageDeletedController.add(MessageDeletedEvent(
        messageId: messageId,
        conversationId: int.tryParse(map['conversation_id']?.toString() ?? ''),
        deletedBy: int.tryParse(map['deleted_by']?.toString() ?? ''),
        forEveryone: _parseForEveryone(map['for_everyone']),
        timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      ));
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.messageDeleted,
        conversationId: ChatPusherLog.conversationIdOf(map),
      );
    } catch (e) {
      AppLogger.warning(
        'Parse MessageDeleted failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleMessageEdited(Map<String, dynamic> data) {
    try {
      Map<String, dynamic>? messageJson;
      final messageData = data['message'];
      if (messageData is Map) {
        messageJson = Map<String, dynamic>.from(messageData);
      }
      final messageId = int.tryParse(
            data['message_id']?.toString() ?? messageJson?['id']?.toString() ?? '',
          ) ??
          0;
      if (messageId <= 0) return;
      final content = data['content']?.toString() ??
          messageJson?['content']?.toString() ??
          messageJson?['message']?.toString() ??
          '';
      _messageEditedController.add(MessageEditedEvent(
        messageId: messageId,
        conversationId: int.tryParse(data['conversation_id']?.toString() ?? '') ??
            int.tryParse(messageJson?['conversation_id']?.toString() ?? ''),
        content: content,
        editedAt: DateTime.tryParse(data['edited_at']?.toString() ?? '') ??
            DateTime.now(),
        message: messageJson != null ? Message.fromJson(messageJson) : null,
      ));
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.messageEdited,
        conversationId: ChatPusherLog.conversationIdOf(data),
        body: content,
      );
    } catch (e) {
      AppLogger.warning(
        'Parse MessageEdited failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleMessageReacted(Map<String, dynamic> data) {
    try {
      final messageId = int.tryParse(data['message_id']?.toString() ?? '') ?? 0;
      if (messageId <= 0) return;
      final userId = int.tryParse(data['user_id']?.toString() ?? '') ?? 0;
      final emoji = data['emoji']?.toString() ?? '';
      _messageReactedController.add(MessageReactedEvent(
        messageId: messageId,
        conversationId:
            int.tryParse(data['conversation_id']?.toString() ?? ''),
        userId: userId,
        emoji: emoji,
        reacted: data['reacted'] == true,
        counts: ChatReactionSummary.parseCounts(data['counts']),
      ));
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.messageReacted,
        conversationId: ChatPusherLog.conversationIdOf(data),
        body: emoji,
      );
    } catch (e) {
      AppLogger.warning(
        'Parse MessageReacted failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleMessageDelivered(Map<String, dynamic> data) {
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
      if (ids.isEmpty) return;

      _messageDeliveredController.add(MessageDeliveredEvent(
        conversationId: int.tryParse(data['conversation_id']?.toString() ?? ''),
        recipientId: int.tryParse(data['recipient_id']?.toString() ?? '') ?? 0,
        senderId: int.tryParse(data['sender_id']?.toString() ?? '') ?? 0,
        messageIds: ids,
        deliveredAt: DateTime.tryParse(data['delivered_at']?.toString() ?? '') ??
            DateTime.now(),
      ));
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.messageDelivered,
        conversationId: ChatPusherLog.conversationIdOf(data),
      );
    } catch (e) {
      AppLogger.warning(
        'Parse MessageDelivered failed',
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
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.messageExpired,
        conversationId: ChatPusherLog.conversationIdOf(data),
      );
    } catch (e) {
      AppLogger.warning(
        'Parse MessageExpired failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleScreenshotDetected(Map<String, dynamic> data) {
    try {
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.screenshotDetected,
        conversationId: ChatPusherLog.conversationIdOf(data),
      );
      final system = data['system_message'];
      if (system is Map) {
        _handleMessageSent({
          'message': Map<String, dynamic>.from(system),
          'conversation_id': data['conversation_id'],
        });
      }
    } catch (e) {
      AppLogger.warning(
        'Parse ScreenshotDetected failed',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  void _handleNewMatch(Map<String, dynamic> data) {
    final matchedUser = data['matched_user'];
    final matchedMap = matchedUser is Map
        ? Map<String, dynamic>.from(matchedUser)
        : <String, dynamic>{};
    final matchedUserId = int.tryParse(matchedMap['id']?.toString() ?? '');
    _matchController.add(MatchEvent(
      matchId: int.tryParse(data['match_id']?.toString() ?? '') ??
          int.tryParse(data['id']?.toString() ?? ''),
      userId: matchedUserId ??
          int.tryParse(data['user_id']?.toString() ?? ''),
      firstName: matchedMap['first_name']?.toString() ??
          matchedMap['name']?.toString(),
      lastName: matchedMap['last_name']?.toString(),
      avatarUrl: matchedMap['avatar_url']?.toString() ??
          matchedMap['primary_image_url']?.toString(),
      timestamp: DateTime.now(),
    ));
    ChatPusherLog.logEvent(
      eventType: ChatPusherEventNames.newMatch,
      conversationId: ChatPusherLog.conversationIdOf(data),
    );
  }

  void _handleNewLike(Map<String, dynamic> data) {
    _likeController.add(LikeEvent(
      userId: int.tryParse(data['user_id']?.toString() ?? '') ??
          int.tryParse(data['from_user_id']?.toString() ?? ''),
      timestamp: DateTime.now(),
    ));
    AppLogger.info('Handled new.like', tag: 'Pusher');
    ChatPusherLog.logEvent(
      eventType: ChatPusherEventNames.newLike,
      conversationId: ChatPusherLog.conversationIdOf(data),
    );
  }

  void _handlePlanUpdated(Map<String, dynamic> data) {
    try {
      SubscriptionMetaSync.instance.handle(data);
      final status = AppSubscriptionStatus.fromJson(data);
      PlanUpdatedBridge.emit(status);
      AppLogger.info(
        'Handled plan.updated tier=${status.tier.key}',
        tag: 'Pusher',
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Parse plan.updated failed',
        tag: 'Pusher',
        error: e,
      );
      AppLogger.debug('plan.updated stack: $stack', tag: 'Pusher');
    }
  }

  void _handleUserPresence(Map<String, dynamic> data) {
    try {
      final userId = int.tryParse(data['user_id']?.toString() ?? '') ?? 0;
      if (userId <= 0) return;

      final isOnline = data['is_online'] == true ||
          data['is_online'] == 1 ||
          data['is_online']?.toString() == '1' ||
          data['is_online']?.toString().toLowerCase() == 'true';
      ChatPusherLog.logEvent(
        eventType: ChatPusherEventNames.userStatus,
        conversationId: ChatPusherLog.conversationIdOf(data),
      );

      final lastSeenRaw = data['last_seen_at'] ?? data['last_seen'];
      _presenceController.add(UserPresenceEvent(
        userId: userId,
        isOnline: isOnline,
        lastSeenAt: lastSeenRaw != null
            ? AppDateTime.parseApi(lastSeenRaw.toString())
            : null,
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      ));
    } catch (e) {
      AppLogger.warning(
        'Parse user presence failed',
        tag: 'Pusher',
        error: e,
      );
    }
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
        _emitConnection(ConnectionStatus.connected);
        if (_connectedKey != PusherConfig.appKey) {
          unawaited(_recoverWithServerKey());
        }
        break;
      case 'DISCONNECTED':
        _isConnected = false;
        _isConnecting = false;
        _emitConnection(ConnectionStatus.disconnected);
        break;
      case 'CONNECTING':
        _emitConnection(ConnectionStatus.connecting);
        break;
      case 'RECONNECTING':
        _emitConnection(ConnectionStatus.reconnecting);
        break;
    }
  }

  void _onError(String message, int? code, dynamic e) {
    if (_isMissingSubscriptionError(message)) {
      AppLogger.warning(
        'Channel not subscribed yet: $message',
        tag: 'Pusher',
      );
      return;
    }
    if (_maybeRecoverFromAuthError(message)) {
      AppLogger.warning(
        'Pusher key mismatch, reconnecting with server key',
        tag: 'Pusher',
      );
      return;
    }
    AppLogger.error(
      'Connection error: $message ($code)',
      tag: 'Pusher',
      error: e,
    );
    _errorController.add(message);
  }

  Future<void> _syncRemoteCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('lgbtfinder_pusher_runtime_key');
      final cluster = prefs.getString('lgbtfinder_pusher_runtime_cluster');
      if (key != null &&
          key.trim().isNotEmpty &&
          cluster != null &&
          cluster.trim().isNotEmpty) {
        PusherConfig.applyRemote(key: key, cluster: cluster);
      }
    } catch (e) {
      AppLogger.warning(
        'Could not load persisted Pusher credentials',
        tag: 'Pusher',
        error: e,
      );
    }

    final dio = _authDio;
    if (dio == null) return;
    try {
      final response = await dio.get<Map<String, dynamic>>(
        PusherConfig.remoteConfigUrl,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final data = response.data;
      final pusher = data?['data'] is Map
          ? Map<String, dynamic>.from(data!['data'] as Map)['pusher']
          : data?['pusher'];
      if (pusher is Map) {
        final map = Map<String, dynamic>.from(pusher);
        PusherConfig.applyRemote(
          key: map['key']?.toString(),
          cluster: map['cluster']?.toString(),
        );
        await _persistRuntimeCredentials();
      }
    } catch (e) {
      AppLogger.warning(
        'Could not fetch realtime Pusher config',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  Future<void> _persistRuntimeCredentials() async {
    if (!PusherConfig.hasRemotePair) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lgbtfinder_pusher_runtime_key', PusherConfig.appKey);
      await prefs.setString(
        'lgbtfinder_pusher_runtime_cluster',
        PusherConfig.cluster,
      );
    } catch (e) {
      AppLogger.warning(
        'Could not persist Pusher credentials',
        tag: 'Pusher',
        error: e,
      );
    }
  }

  bool _maybeRecoverFromAuthError(String message) {
    final key = PusherConfig.parseKeyFromAuthError(message);
    if (key == null || key == PusherConfig.appKey) return false;
    PusherConfig.applyRemote(key: key);
    unawaited(_recoverWithServerKey());
    return true;
  }

  Future<void> _recoverWithServerKey() async {
    if (_recoveringKey) return;
    final tokenProvider = _tokenProvider;
    if (tokenProvider == null) return;
    _recoveringKey = true;
    final userId = _currentUserId;
    final channels = _subscribedChannels.toSet();
    final statusIds = _statusUserIds.toSet();
    try {
      await _persistRuntimeCredentials();
      await initialize(tokenProvider: tokenProvider);
      if (userId != null && userId > 0) {
        await connectUser(userId);
      }
      for (final channel in channels) {
        await subscribe(channel);
      }
      for (final id in statusIds) {
        await subscribeUserStatus(id);
      }
      AppLogger.info(
        'Reconnected Pusher with server app key',
        tag: 'Pusher',
      );
    } catch (e) {
      AppLogger.warning(
        'Pusher key recovery failed',
        tag: 'Pusher',
        error: e,
      );
    } finally {
      _recoveringKey = false;
    }
  }

  /// Legacy MessageDeleted payloads omitted the flag; those were always unsend.
  bool _parseForEveryone(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}

class MatchEvent {
  final int? matchId;
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final DateTime timestamp;

  MatchEvent({
    this.matchId,
    this.userId,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    required this.timestamp,
  });
}

class LikeEvent {
  final int? userId;
  final DateTime timestamp;

  LikeEvent({
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

class MessageDeletedEvent {
  final int messageId;
  final int? conversationId;
  final int? deletedBy;
  final bool forEveryone;
  final DateTime timestamp;

  MessageDeletedEvent({
    required this.messageId,
    this.conversationId,
    this.deletedBy,
    this.forEveryone = true,
    required this.timestamp,
  });
}

class MessageEditedEvent {
  final int messageId;
  final int? conversationId;
  final String content;
  final DateTime editedAt;
  final Message? message;

  MessageEditedEvent({
    required this.messageId,
    this.conversationId,
    required this.content,
    required this.editedAt,
    this.message,
  });
}

class MessageReactedEvent {
  final int messageId;
  final int? conversationId;
  final int userId;
  final String emoji;
  final bool reacted;
  final Map<String, int> counts;

  MessageReactedEvent({
    required this.messageId,
    this.conversationId,
    required this.userId,
    required this.emoji,
    required this.reacted,
    required this.counts,
  });
}

class MessageDeliveredEvent {
  final int? conversationId;
  final int recipientId;
  final int senderId;
  final List<int> messageIds;
  final DateTime deliveredAt;

  MessageDeliveredEvent({
    this.conversationId,
    required this.recipientId,
    required this.senderId,
    required this.messageIds,
    required this.deliveredAt,
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

class UserPresenceEvent {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime timestamp;

  UserPresenceEvent({
    required this.userId,
    required this.isOnline,
    this.lastSeenAt,
    required this.timestamp,
  });
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

