import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/message.dart';
import '../models/chat.dart';
import '../models/chat_participant.dart';

/// Chat service for messaging functionality
class ChatService {
  final ApiService _apiService;

  ChatService(this._apiService);

  /// Send a message
  Future<Message> sendMessage(SendMessageRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: request.toJson(),
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
}

