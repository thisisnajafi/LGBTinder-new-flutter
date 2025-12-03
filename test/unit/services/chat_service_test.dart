/// Unit tests for ChatService
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_service.dart';
import 'package:lgbtindernew/shared/services/api_service.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/data/models/send_message_request.dart';
import 'package:lgbtindernew/shared/models/api_response.dart';

import 'chat_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late ChatService chatService;
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
    chatService = ChatService(mockApiService);
  });

  group('ChatService', () {
    group('sendMessage', () {
      test('should return Message on successful send', () async {
        // Arrange
        final request = SendMessageRequest(
          receiverId: 123,
          message: 'Hello!',
          messageType: 'text',
        );

        final responseData = {
          'id': 1,
          'sender_id': 456,
          'receiver_id': 123,
          'message': 'Hello!',
          'message_type': 'text',
          'created_at': '2024-01-01T00:00:00Z',
          'is_read': false,
        };

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: true,
          data: responseData,
          message: 'Message sent',
        ));

        // Act
        final result = await chatService.sendMessage(request);

        // Assert
        expect(result, isNotNull);
        expect(result.message, equals('Hello!'));
        expect(result.receiverId, equals(123));
        verify(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).called(1);
      });

      test('should throw exception on failed send', () async {
        // Arrange
        final request = SendMessageRequest(
          receiverId: 123,
          message: 'Hello!',
          messageType: 'text',
        );

        when(mockApiService.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          fromJson: anyNamed('fromJson'),
        )).thenAnswer((_) async => ApiResponse<Map<String, dynamic>>(
          status: false,
          data: null,
          message: 'Send failed',
        ));

        // Act & Assert
        expect(
          () => chatService.sendMessage(request),
          throwsException,
        );
      });
    });

    group('getChatHistory', () {
      test('should return list of messages on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'sender_id': 456,
              'receiver_id': 123,
              'message': 'Hello!',
              'message_type': 'text',
              'created_at': '2024-01-01T00:00:00Z',
              'is_read': false,
            },
            {
              'id': 2,
              'sender_id': 123,
              'receiver_id': 456,
              'message': 'Hi there!',
              'message_type': 'text',
              'created_at': '2024-01-01T00:01:00Z',
              'is_read': true,
            },
          ],
        };

        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: responseData,
          message: 'Chat history retrieved',
        ));

        // Act
        final result = await chatService.getChatHistory(
          receiverId: 123,
          page: 1,
          limit: 50,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(2));
        expect(result[0].message, equals('Hello!'));
        expect(result[1].message, equals('Hi there!'));
      });

      test('should return empty list when no messages', () async {
        // Arrange
        when(mockApiService.get<dynamic>(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => ApiResponse<dynamic>(
          status: true,
          data: {'data': []},
          message: 'No messages',
        ));

        // Act
        final result = await chatService.getChatHistory(receiverId: 123);

        // Assert
        expect(result, isNotNull);
        expect(result.isEmpty, isTrue);
      });
    });

    group('getChatUsers', () {
      test('should return list of chats on successful call', () async {
        // Arrange
        final responseData = {
          'data': [
            {
              'id': 1,
              'user': {
                'id': 123,
                'first_name': 'John',
                'last_name': 'Doe',
              },
              'last_message': {
                'id': 1,
                'message': 'Hello!',
                'created_at': '2024-01-01T00:00:00Z',
              },
              'unread_count': 2,
            },
          ],
        };

        when(mockApiService.get<dynamic>(any)).thenAnswer((_) async =>
            ApiResponse<dynamic>(
              status: true,
              data: responseData,
              message: 'Chat users retrieved',
            ));

        // Act
        final result = await chatService.getChatUsers();

        // Assert
        expect(result, isNotNull);
        expect(result.length, equals(1));
        expect(result[0].id, equals(1));
      });
    });
  });
}

