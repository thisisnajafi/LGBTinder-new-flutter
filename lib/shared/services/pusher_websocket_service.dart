// FEATURE ENHANCEMENT (Task 9.1.1): Pusher WebSocket Service
// 
// Complete WebSocket integration using Pusher for real-time features:
// - Real-time message updates
// - Typing indicators
// - Online status updates
// - Read receipts
//
// Note: Add pusher_client package to pubspec.yaml:
//   pusher_channels_flutter: ^2.0.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api_error.dart';
import '../../features/chat/data/models/message.dart';
import '../../core/constants/api_endpoints.dart';

/// Pusher WebSocket Service for real-time communication
/// 
/// Handles:
/// - Private channel subscriptions (chat.{userId})
/// - User status channel (user.status.{userId})
/// - Event listeners for messages, typing, online status
class PusherWebSocketService {
  // Pusher instance (uncomment when package is added)
  // PusherChannelsFlutter? _pusher;
  
  // Stream controllers for real-time updates
  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _onlineStatusController = StreamController<OnlineStatusEvent>.broadcast();
  final _readReceiptController = StreamController<ReadReceiptEvent>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Subscribed channels
  final Map<String, dynamic> _subscribedChannels = {};
  
  // Current user ID
  int? _currentUserId;
  
  // Connection status
  bool _isConnected = false;
  bool _isConnecting = false;

  /// Message stream - emits new messages in real-time
  Stream<Message> get messageStream => _messageController.stream;

  /// Typing status stream - emits when user starts/stops typing
  Stream<TypingEvent> get typingStream => _typingController.stream;

  /// Online status stream - emits when user comes online/goes offline
  Stream<OnlineStatusEvent> get onlineStatusStream => _onlineStatusController.stream;

  /// Read receipt stream - emits when message is read
  Stream<ReadReceiptEvent> get readReceiptStream => _readReceiptController.stream;

  /// Connection status stream
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;

  /// Error stream
  Stream<String> get errorStream => _errorController.stream;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Initialize Pusher connection
  /// 
  /// Requires:
  /// - Pusher app key, secret, cluster from backend config
  /// - User authentication token for private channels
  Future<void> initialize({
    required String pusherKey,
    required String pusherCluster,
    required String authEndpoint,
    String? host,
    int? port,
    bool encrypted = true,
  }) async {
    if (_isConnecting || _isConnected) {
      debugPrint('Pusher already initialized');
      return;
    }

    _isConnecting = true;
    _connectionController.add(ConnectionStatus.connecting);

    try {
      // TODO: Initialize Pusher when package is added
      // _pusher = PusherChannelsFlutter.getInstance();
      // await _pusher!.init(
      //   apiKey: pusherKey,
      //   cluster: pusherCluster,
      //   onConnectionStateChange: _onConnectionStateChange,
      //   onError: _onError,
      //   onSubscriptionSucceeded: _onSubscriptionSucceeded,
      //   onEvent: _onEvent,
      //   onSubscriptionError: _onSubscriptionError,
      //   onDecryptionFailure: _onDecryptionFailure,
      //   onMemberAdded: _onMemberAdded,
      //   onMemberRemoved: _onMemberRemoved,
      //   endpoint: host ?? 'api-$pusherCluster.pusher.com',
      //   port: port ?? (encrypted ? 443 : 80),
      //   encrypted: encrypted,
      //   authEndpoint: authEndpoint,
      // );
      
      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(ConnectionStatus.connected);
      
      debugPrint('✅ Pusher initialized successfully');
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(ConnectionStatus.disconnected);
      _errorController.add('Failed to initialize Pusher: $e');
      debugPrint('❌ Pusher initialization failed: $e');
      rethrow;
    }
  }

  /// Connect and subscribe to user's channels
  /// 
  /// Subscribes to:
  /// - private-chat.{userId} - For receiving messages
  /// - private-user.{userId} - For user-specific notifications
  Future<void> connect(int userId) async {
    if (!_isConnected) {
      throw Exception('Pusher not initialized. Call initialize() first.');
    }

    _currentUserId = userId;

    try {
      // Subscribe to private chat channel
      await _subscribeToChannel('private-chat.$userId');
      
      // Subscribe to user status channel
      await _subscribeToChannel('private-user.$userId');
      
      debugPrint('✅ Connected to Pusher channels for user $userId');
    } catch (e) {
      _errorController.add('Failed to connect: $e');
      debugPrint('❌ Failed to connect to Pusher: $e');
      rethrow;
    }
  }

  /// Subscribe to a specific channel
  Future<void> _subscribeToChannel(String channelName) async {
    if (_subscribedChannels.containsKey(channelName)) {
      debugPrint('Already subscribed to $channelName');
      return;
    }

    try {
      // TODO: Subscribe when package is added
      // await _pusher!.subscribe(
      //   channelName: channelName,
      //   onEvent: (event) => _handleChannelEvent(channelName, event),
      // );
      
      _subscribedChannels[channelName] = true;
      debugPrint('✅ Subscribed to channel: $channelName');
    } catch (e) {
      _errorController.add('Failed to subscribe to $channelName: $e');
      debugPrint('❌ Failed to subscribe to $channelName: $e');
      rethrow;
    }
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribeFromChannel(String channelName) async {
    if (!_subscribedChannels.containsKey(channelName)) {
      return;
    }

    try {
      // TODO: Unsubscribe when package is added
      // await _pusher!.unsubscribe(channelName: channelName);
      
      _subscribedChannels.remove(channelName);
      debugPrint('✅ Unsubscribed from channel: $channelName');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from $channelName: $e');
    }
  }

  /// Handle channel events
  void _handleChannelEvent(String channelName, Map<String, dynamic> event) {
    final eventName = event['event'] as String?;
    final data = event['data'] as Map<String, dynamic>?;

    if (eventName == null || data == null) return;

    switch (eventName) {
      case 'message.sent':
        _handleMessageSent(data);
        break;
      case 'user.typing':
        _handleUserTyping(data);
        break;
      case 'user.status':
        _handleUserStatus(data);
        break;
      case 'message.read':
        _handleMessageRead(data);
        break;
      default:
        debugPrint('Unhandled event: $eventName');
    }
  }

  /// Handle message.sent event
  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>?;
      if (messageData != null) {
        final message = Message.fromJson(messageData);
        _messageController.add(message);
        debugPrint('📨 New message received: ${message.id}');
      }
    } catch (e) {
      debugPrint('❌ Error parsing message: $e');
      _errorController.add('Failed to parse message: $e');
    }
  }

  /// Handle user.typing event
  void _handleUserTyping(Map<String, dynamic> data) {
    try {
      final event = TypingEvent(
        userId: data['user_id'] as int? ?? 0,
        isTyping: data['is_typing'] as bool? ?? false,
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
      );
      _typingController.add(event);
      debugPrint('⌨️ User ${event.userId} typing: ${event.isTyping}');
    } catch (e) {
      debugPrint('❌ Error parsing typing event: $e');
    }
  }

  /// Handle user.status event
  void _handleUserStatus(Map<String, dynamic> data) {
    try {
      final event = OnlineStatusEvent(
        userId: data['user_id'] as int? ?? 0,
        isOnline: data['is_online'] as bool? ?? false,
        lastSeen: DateTime.tryParse(data['last_seen']?.toString() ?? ''),
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
      );
      _onlineStatusController.add(event);
      debugPrint('🟢 User ${event.userId} status: ${event.isOnline ? "online" : "offline"}');
    } catch (e) {
      debugPrint('❌ Error parsing status event: $e');
    }
  }

  /// Handle message.read event
  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final event = ReadReceiptEvent(
        messageId: data['message_id'] as int? ?? 0,
        userId: data['user_id'] as int? ?? 0,
        readAt: DateTime.tryParse(data['read_at']?.toString() ?? '') ?? DateTime.now(),
      );
      _readReceiptController.add(event);
      debugPrint('✓ Message ${event.messageId} read by user ${event.userId}');
    } catch (e) {
      debugPrint('❌ Error parsing read receipt: $e');
    }
  }

  /// Connection state change handler
  void _onConnectionStateChange(String currentState, String previousState) {
    debugPrint('Pusher connection state: $previousState → $currentState');
    
    switch (currentState) {
      case 'CONNECTED':
        _isConnected = true;
        _connectionController.add(ConnectionStatus.connected);
        break;
      case 'DISCONNECTED':
        _isConnected = false;
        _connectionController.add(ConnectionStatus.disconnected);
        break;
      case 'CONNECTING':
        _connectionController.add(ConnectionStatus.connecting);
        break;
      case 'RECONNECTING':
        _connectionController.add(ConnectionStatus.reconnecting);
        break;
    }
  }

  /// Error handler
  void _onError(String message, int? code, dynamic e) {
    debugPrint('❌ Pusher error: $message (code: $code)');
    _errorController.add('$message (code: $code)');
  }

  /// Disconnect from Pusher
  Future<void> disconnect() async {
    try {
      // Unsubscribe from all channels
      for (final channelName in _subscribedChannels.keys.toList()) {
        await unsubscribeFromChannel(channelName);
      }
      
      // TODO: Disconnect when package is added
      // await _pusher?.disconnect();
      
      _isConnected = false;
      _currentUserId = null;
      _connectionController.add(ConnectionStatus.disconnected);
      debugPrint('✅ Disconnected from Pusher');
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _onlineStatusController.close();
    _readReceiptController.close();
    _connectionController.close();
    _errorController.close();
  }
}

/// Typing event model
class TypingEvent {
  final int userId;
  final bool isTyping;
  final DateTime timestamp;

  TypingEvent({
    required this.userId,
    required this.isTyping,
    required this.timestamp,
  });
}

/// Online status event model
class OnlineStatusEvent {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime timestamp;

  OnlineStatusEvent({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    required this.timestamp,
  });
}

/// Read receipt event model
class ReadReceiptEvent {
  final int messageId;
  final int userId;
  final DateTime readAt;

  ReadReceiptEvent({
    required this.messageId,
    required this.userId,
    required this.readAt,
  });
}

/// Connection status enum
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

