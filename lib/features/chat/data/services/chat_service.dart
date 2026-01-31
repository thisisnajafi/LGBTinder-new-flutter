import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/message_attachment.dart';

/// Chat service for messaging functionality
class ChatService {
  final ApiService _apiService;

  ChatService(this._apiService);


  /// Get chat history with a specific user
  /// FIXED: Changed 'receiver_id' to 'user_id' to match backend ChatController@getChatHistory
  Future<List<Message>> getChatHistory({
    int? receiverId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (receiverId != null) queryParams['user_id'] = receiverId; // Backend expects 'user_id'
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.chatHistory,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => Message.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of users with conversations
  Future<List<Chat>> getChatUsers() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.chatUsers,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => Chat.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
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

  /// Set typing status
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
  /// 
  /// [receiverId] - The ID of the user to send the message to
  /// [message] - Text content of the message (required for text type, optional for media)
  /// [messageType] - One of: 'text', 'image', 'video', 'voice', 'disappearing_image', 'disappearing_video'
  /// [mediaFile] - File to upload (required for media types)
  /// [mediaDuration] - Duration in seconds (required for voice/video)
  /// [expiresInSeconds] - 1-60 seconds (required for disappearing media)
  Future<Message> sendMessage(int receiverId, String message, {
    String messageType = 'text',
    File? mediaFile,
    int? mediaDuration,
    int? expiresInSeconds,
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
        'message': message,
        'message_type': messageType,
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
}

