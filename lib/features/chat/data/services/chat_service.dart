import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/message_attachment.dart';

/// Cursor for loading older messages (newest-first API).
class ChatHistoryCursor {
  final int beforeId;
  final DateTime? beforeCreatedAt;

  const ChatHistoryCursor({
    required this.beforeId,
    this.beforeCreatedAt,
  });

  factory ChatHistoryCursor.fromJson(Map<String, dynamic> json) {
    return ChatHistoryCursor(
      beforeId: json['before_id'] is int
          ? json['before_id'] as int
          : int.tryParse(json['before_id']?.toString() ?? '') ?? 0,
      beforeCreatedAt: json['before_created_at'] != null
          ? DateTime.tryParse(json['before_created_at'].toString())
          : null,
    );
  }
}

/// Result of [ChatService.getChatHistory] including conversation metadata.
class ChatHistoryResult {
  final List<Message> messages;
  final int? conversationId;
  final int? otherUserId;
  final bool hasMore;
  final ChatHistoryCursor? nextCursor;

  const ChatHistoryResult({
    required this.messages,
    this.conversationId,
    this.otherUserId,
    this.hasMore = false,
    this.nextCursor,
  });
}

/// Chat service for messaging functionality
class ChatService {
  final ApiService _apiService;

  ChatService(this._apiService);


  /// Get chat history with a specific user (includes `conversation_id` when available).
  Future<ChatHistoryResult> getChatHistory({
    int? receiverId,
    int? page,
    int? limit,
    int? beforeId,
    DateTime? beforeCreatedAt,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (receiverId != null) queryParams['user_id'] = receiverId;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['per_page'] = limit;
      if (beforeId != null) queryParams['before_id'] = beforeId;
      if (beforeCreatedAt != null) {
        queryParams['before_created_at'] = beforeCreatedAt.toIso8601String();
      }

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.chatHistory,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _parseChatHistoryResponse(response.data, meta: response.meta);
    } catch (e) {
      rethrow;
    }
  }

  ChatHistoryResult _parseChatHistoryResponse(
    dynamic raw, {
    Map<String, dynamic>? meta,
  }) {
    List<dynamic>? messageList;
    int? conversationId;
    int? otherUserId;
    Map<String, dynamic>? metaMap = meta;

    if (raw is Map<String, dynamic>) {
      metaMap ??= raw['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(raw['meta'] as Map)
          : null;
      final envelope = raw['data'];
      if (envelope is Map<String, dynamic>) {
        conversationId = _parseInt(envelope['conversation_id']);
        otherUserId = _parseInt(envelope['other_user_id']);
        final messages = envelope['messages'];
        if (messages is List) {
          messageList = messages;
        }
      } else if (envelope is List) {
        messageList = envelope;
      } else if (raw['messages'] is List) {
        messageList = raw['messages'] as List;
        conversationId = _parseInt(raw['conversation_id']);
        otherUserId = _parseInt(raw['other_user_id']);
      }
    } else if (raw is List) {
      messageList = raw;
    }

    if (messageList == null) {
      return const ChatHistoryResult(messages: []);
    }

    final messages = messageList
        .map((item) => Message.fromJson(item as Map<String, dynamic>))
        .toList();

    final hasMore = metaMap?['has_more'] == true || metaMap?['has_more'] == 1;
    ChatHistoryCursor? nextCursor;
    final cursorRaw = metaMap?['next_cursor'];
    if (cursorRaw is Map<String, dynamic>) {
      nextCursor = ChatHistoryCursor.fromJson(cursorRaw);
    }

    return ChatHistoryResult(
      messages: messages,
      conversationId: conversationId,
      otherUserId: otherUserId,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// GET chat/access-users — users with chat access (users, total_count, matches_count, superlikes_count).
  Future<Map<String, dynamic>> getAccessUsers() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.chatAccessUsers,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    final data = response.data;
    if (data != null && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return data ?? {};
  }

  /// Get list of users with conversations (matches + superlikes).
  Future<List<Chat>> getChatUsers({bool forceRefresh = false}) async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.chatUsers,
        forceRefresh: forceRefresh,
      );

      if (!response.status) {
        throw Exception(response.message);
      }

      final dataList = _extractChatUsersList(response.data);
      return dataList
          .map((item) => Chat.fromJson(item as Map<String, dynamic>))
          .where((chat) => chat.userId > 0)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Parses unified API `data` (list) or legacy/nested shapes.
  List<dynamic> _extractChatUsersList(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final users = data['users'];
      if (users is List) return users;
      final nested = data['data'];
      if (nested is List) return nested;
      if (nested is Map<String, dynamic>) {
        final nestedUsers = nested['users'];
        if (nestedUsers is List) return nestedUsers;
      }
    }
    return [];
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.chatMessage,
        data: {'message_id': messageId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Set typing status (legacy: receiver_id body).
  Future<void> setTypingStatus(int receiverId, bool isTyping) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatTyping,
        data: {
          'receiver_id': receiverId,
          'is_typing': isTyping,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Set typing status for a conversation (preferred when [conversationId] is known).
  Future<void> setConversationTyping(int conversationId, bool isTyping) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatConversationTyping(conversationId),
        data: {'is_typing': isTyping},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark messages as read
  /// FIXED: Changed 'receiver_id' to 'sender_id' to match backend ChatController@markAsRead
  Future<void> markAsRead(int senderId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatRead,
        data: {'sender_id': senderId}, // Backend expects 'sender_id' - the user whose messages to mark as read
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all chats for current user
  Future<List<Chat>> getChats() async {
    return await getChatUsers(); // Alias for consistency
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.chatUnreadCount,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['unread_count'] as int? ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0; // Return 0 on error to avoid breaking UI
    }
  }

  /// Upload attachment for message
  Future<MessageAttachment> uploadAttachment(String filePath, String filename) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filename,
        ),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatAttachmentUpload,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return MessageAttachment.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Set online status
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatOnlineStatus,
        data: {'is_online': isOnline},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Enhanced send message with attachment support
  /// 
  /// FIXED: Task 2.3.1 & 2.3.2 - Updated to properly handle media uploads
  /// Backend expects multipart/form-data when sending media (image, video, voice)
  /// Send a sticker message.
  Future<Message> sendSticker(int receiverId, int stickerId) async {
    return sendMessage(
      receiverId,
      stickerId.toString(),
      messageType: 'sticker',
      stickerId: stickerId,
    );
  }

  /// Share a profile card in chat.
  Future<Message> sendProfileLink(int receiverId, int profileUserId) async {
    return sendMessage(
      receiverId,
      '',
      messageType: 'profile_link',
      profileUserId: profileUserId,
    );
  }

  /// POST /api/chat/{conversationId}/upload-image
  Future<Map<String, dynamic>> uploadChatImage(int conversationId, File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _apiService.postFormData<Map<String, dynamic>>(
      ApiEndpoints.chatUploadImage(conversationId),
      data: formData,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }

    final payload = response.data!['data'] ?? response.data!;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw Exception('Invalid upload response');
  }

  /// POST /api/chat/messages/{messageId}/view — record self-destruct view and get secure URL.
  Future<Map<String, dynamic>> viewSelfDestructMessage(int messageId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.chatMessageView(messageId),
      data: const {},
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }

    final payload = response.data!['data'] ?? response.data!;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw Exception('Invalid view response');
  }

  /// POST /api/chat/{conversationId}/upload-voice
  Future<Map<String, dynamic>> uploadChatVoice(
    int conversationId,
    File file,
    int durationSeconds,
  ) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path, filename: fileName),
      'media_duration': durationSeconds,
    });

    final response = await _apiService.postFormData<Map<String, dynamic>>(
      ApiEndpoints.chatUploadVoice(conversationId),
      data: formData,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.message);
    }

    final payload = response.data!['data'] ?? response.data!;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw Exception('Invalid voice upload response');
  }

  /// 
  /// [receiverId] - The ID of the user to send the message to
  /// [message] - Text content of the message (required for text type, optional for media)
  /// [messageType] - One of: 'text', 'image', 'video', 'voice', 'disappearing_image', 'disappearing_video', 'sticker'
  /// [mediaFile] - File to upload (required for media types)
  /// [mediaDuration] - Duration in seconds (required for voice/video)
  /// [expiresInSeconds] - 1-60 seconds (required for disappearing media)
  /// [stickerId] - Required when messageType is 'sticker'
  Future<Message> sendMessage(int receiverId, String message, {
    String messageType = 'text',
    File? mediaFile,
    int? mediaDuration,
    int? expiresInSeconds,
    int? stickerId,
    int? profileUserId,
    String? mediaPath,
    String? mediaThumbnailPath,
    int? mediaWidth,
    int? mediaHeight,
    MessageAttachment? attachment, // Keep for backward compatibility
  }) async {
    try {
      // Use FormData for media uploads, regular JSON for text messages
      if (mediaFile != null && messageType != 'text') {
        return await _sendMessageWithMedia(
          receiverId: receiverId,
          message: message,
          messageType: messageType,
          mediaFile: mediaFile,
          mediaDuration: mediaDuration,
          expiresInSeconds: expiresInSeconds,
        );
      }
      
      // Text-only message
      final data = <String, dynamic>{
        'receiver_id': receiverId,
        'message': (messageType == 'sticker' || messageType == 'profile_link') ? null : message,
        'message_type': messageType,
        if (stickerId != null) 'sticker_id': stickerId,
        if (profileUserId != null) 'profile_user_id': profileUserId,
        if (mediaPath != null) 'media_path': mediaPath,
        if (mediaThumbnailPath != null) 'media_thumbnail_path': mediaThumbnailPath,
        if (mediaWidth != null) 'media_width': mediaWidth,
        if (mediaHeight != null) 'media_height': mediaHeight,
        if (expiresInSeconds != null) 'expires_in_seconds': expiresInSeconds,
        if (mediaDuration != null) 'media_duration': mediaDuration,
      };

      // Legacy attachment support (if attachment ID already exists)
      if (attachment != null) {
        data['attachment_id'] = attachment.id;
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Handle nested data structure
        final messageData = response.data!['data'] ?? response.data!;
        if (messageData is Map<String, dynamic>) {
          return Message.fromJson(messageData);
        }
        return Message.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Send message with media file using multipart/form-data
  /// 
  /// Backend validation (ChatController@sendMessage):
  /// - 'receiver_id' => required, must exist in users table
  /// - 'message' => required if message_type is text, nullable otherwise
  /// - 'message_type' => required, one of: text, image, video, voice, disappearing_image, disappearing_video
  /// - 'media' => required if message_type is image/video/voice/disappearing_*, must be a file
  /// - 'media_duration' => required for voice/video types
  /// - 'expires_in_seconds' => required for disappearing_* types, 1-60 seconds
  Future<Message> _sendMessageWithMedia({
    required int receiverId,
    required String message,
    required String messageType,
    required File mediaFile,
    int? mediaDuration,
    int? expiresInSeconds,
  }) async {
    try {
      final fileName = mediaFile.path.split('/').last;
      
      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'message': message.isNotEmpty ? message : null,
        'message_type': messageType,
        'media': await MultipartFile.fromFile(
          mediaFile.path,
          filename: fileName,
        ),
        if (mediaDuration != null) 'media_duration': mediaDuration,
        if (expiresInSeconds != null) 'expires_in_seconds': expiresInSeconds,
      });

      final response = await _apiService.postFormData<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: formData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final messageData = response.data!['data'] ?? response.data!;
        if (messageData is Map<String, dynamic>) {
          return Message.fromJson(messageData);
        }
        return Message.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get pinned messages count for a conversation (Task 9)
  Future<int> getPinnedMessagesCount(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.chatPinnedCount,
        queryParameters: {'user_id': userId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        return data?['pinned_count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Pin a message (Task 9 — POST /chat/pin-message)
  Future<void> pinMessage(int messageId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.chatPinMessage,
      data: {'message_id': messageId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Unpin a message (Task 9 — POST /chat/unpin-message)
  Future<void> unpinMessage(int messageId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.chatUnpinMessage,
      data: {'message_id': messageId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Get pinned messages for a conversation (Task 9 — GET /chat/pinned-messages)
  Future<List<Message>> getPinnedMessages(int userId) async {
    final response = await _apiService.get<dynamic>(
      ApiEndpoints.chatPinnedMessages,
      queryParameters: {'user_id': userId},
    );
    List<dynamic>? list;
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['data'] != null && data['data'] is List) {
        list = data['data'] as List;
      }
    } else if (response.data is List) {
      list = response.data as List;
    }
    if (list == null) return [];
    return list
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Search messages (Task 9 — GET /chat/search)
  Future<List<Message>> searchMessages({
    required String query,
    int? userId,
    int? chatId,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'query': query,
      'limit': limit,
      'offset': offset,
    };
    if (userId != null) params['user_id'] = userId;
    if (chatId != null) params['chat_id'] = chatId;
    final response = await _apiService.get<dynamic>(
      ApiEndpoints.chatSearch,
      queryParameters: params,
    );
    List<dynamic>? list;
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['data'] != null && data['data'] is List) {
        list = data['data'] as List;
      }
    } else if (response.data is List) {
      list = response.data as List;
    }
    if (list == null) return [];
    return list
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mute chat notifications from a matched user.
  Future<bool> muteConversation(int userId) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.chatConversationMute(userId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data?['is_muted'] == true;
  }

  /// Unmute chat notifications from a matched user.
  Future<bool> unmuteConversation(int userId) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.chatConversationMute(userId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data?['is_muted'] == true;
  }

  /// Get conversation mute status for a peer.
  Future<bool> isConversationMuted(int userId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.chatConversationMute(userId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) return false;
    return response.data?['is_muted'] == true;
  }
}

