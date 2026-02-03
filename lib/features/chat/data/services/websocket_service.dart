import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../shared/services/token_storage_service.dart';
import '../models/message.dart';
import '../models/chat.dart';

/// WebSocket service for real-time messaging
class WebSocketService {
  IO.Socket? _socket;
  final TokenStorageService _tokenStorage;
  final String baseUrl;

  // Stream controllers for real-time updates
  final _messageController = StreamController<Message>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  WebSocketService(this._tokenStorage, {this.baseUrl = 'https://api.lgbtfinder.com'});

  /// Message stream
  Stream<Message> get messageStream => _messageController.stream;

  /// Typing status stream
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  /// Online status stream
  Stream<Map<String, dynamic>> get onlineStatusStream => _onlineStatusController.stream;

  /// Connection status stream
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Check if connected
  bool get isConnected => _socket?.connected ?? false;

  /// Connect to WebSocket server
  Future<void> connect() async {
    try {
      final token = await _tokenStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _setupEventHandlers();
    } catch (e) {
      throw Exception('Failed to connect to WebSocket: $e');
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _connectionController.add(false);
    });

    _socket!.onError((error) {
      _connectionController.add(false);
    });

    // Message events
    _socket!.on('message', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final message = Message.fromJson(data);
          _messageController.add(message);
        }
      } catch (e) {
        // Handle parsing error
      }
    });

    // Typing events
    _socket!.on('typing', (data) {
      if (data is Map<String, dynamic>) {
        _typingController.add(data);
      }
    });

    // Online status events
    _socket!.on('user_online', (data) {
      if (data is Map<String, dynamic>) {
        _onlineStatusController.add({
          'user_id': data['user_id'],
          'is_online': true,
        });
      }
    });

    _socket!.on('user_offline', (data) {
      if (data is Map<String, dynamic>) {
        _onlineStatusController.add({
          'user_id': data['user_id'],
          'is_online': false,
        });
      }
    });
  }

  /// Send a message via WebSocket
  void sendMessage(Message message) {
    if (_socket?.connected ?? false) {
      _socket!.emit('send_message', message.toJson());
    }
  }

  /// Send typing status
  void sendTypingStatus(int receiverId, bool isTyping) {
    if (_socket?.connected ?? false) {
      _socket!.emit('typing', {
        'receiver_id': receiverId,
        'is_typing': isTyping,
      });
    }
  }

  /// Join a chat room
  void joinChat(int userId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('join_chat', {'user_id': userId});
    }
  }

  /// Leave a chat room
  void leaveChat(int userId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('leave_chat', {'user_id': userId});
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _onlineStatusController.close();
    _connectionController.close();
  }
}

