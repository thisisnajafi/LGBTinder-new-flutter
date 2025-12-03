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
  Future<List<Message>> getChatHistory({
    int? receiverId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (receiverId != null) queryParams['receiver_id'] = receiverId;
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
  Future<void> markAsRead(int receiverId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatRead,
        data: {'receiver_id': receiverId},
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
  Future<Message> sendMessage(int receiverId, String message, {
    String messageType = 'text',
    MessageAttachment? attachment,
  }) async {
    try {
      final data = <String, dynamic>{
        'receiver_id': receiverId,
        'message': message,
        'message_type': messageType,
      };

      if (attachment != null) {
        data['attachment_id'] = attachment.id;
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Message.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}

