import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/providers/chat_providers.dart';
import 'package:lgbtindernew/features/user/providers/user_providers.dart';
import 'package:lgbtindernew/pages/chat_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/feature_locked_screen.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';
import 'package:lgbtindernew/shared/utils/plan_guard.dart';
import 'package:lgbtindernew/widgets/chat/message_bubble.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';
import 'chat_test_helpers.dart';

/// Chat interactions (TEST-054 – TEST-062).
void main() {
  setUpAll(() {
    registerChatFallbacks();
    registerFallbackValue(File('test/e2e/.tmp_wizard_photo.jpg'));
  });

  group('Chat list', () {
    // TEST-054
    testWidgets('TEST-054: list filters unread and online conversations', (tester) async {
      final chat = MockChatService();
      await pumpChatListPage(
        tester,
        chat: chat,
        chats: [
          sampleChat(userId: 1, firstName: 'Plain', unreadCount: 0, isOnline: false),
          sampleChat(userId: 2, firstName: 'Unread', unreadCount: 2, isOnline: false),
          sampleChat(userId: 3, firstName: 'Online', unreadCount: 0, isOnline: true),
        ],
      );

      expect(find.text('Plain'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);

      await tester.tap(chatFilterButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unread only'));
      await tester.pumpAndSettle();

      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Plain'), findsNothing);
      expect(find.text('Online'), findsNothing);

      await tester.tap(chatFilterButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Online only'));
      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Unread'), findsNothing);
      expect(find.text('Plain'), findsNothing);
    });

    // TEST-055
    testWidgets('TEST-055: tapping a conversation opens the chat thread', (tester) async {
      final chat = MockChatService();
      stubChatList(
        chat,
        chats: [sampleChat(userId: 42, firstName: 'Alex')],
      );
      stubChatThread(chat, peerUserId: 42);

      final user = MockUserService();
      stubCurrentUser(user);
      final ws = stubWebSocket();

      final router = chatTestRouter(chat: chat);
      await pumpChatRouter(
        tester,
        router: router,
        overrides: [
          ...chatListOverrides(chat: chat),
          userServiceProvider.overrideWithValue(user),
          webSocketServiceProvider.overrideWithValue(ws),
        ],
      );

      expect(find.text('Alex'), findsOneWidget);
      await tester.tap(find.text('Alex'));
      await e2ePumpFrames(tester, frames: 8);

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Alex'), findsWidgets);
    });
  });

  group('Chat thread messaging', () {
    // TEST-056
    testWidgets('TEST-056: send message succeeds and shows in thread', (tester) async {
      final chat = MockChatService();
      when(
        () => chat.sendMessage(
          2,
          'Hello there',
          messageType: any(named: 'messageType'),
          mediaFile: any(named: 'mediaFile'),
          mediaDuration: any(named: 'mediaDuration'),
          expiresInSeconds: any(named: 'expiresInSeconds'),
          attachment: any(named: 'attachment'),
        ),
      ).thenAnswer(
        (_) async => sampleMessage(id: 501, senderId: 1, receiverId: 2, text: 'Hello there'),
      );

      await pumpChatPage(tester, chat: chat);
      await sendChatMessage(tester, 'Hello there');

      expect(find.text('Hello there'), findsOneWidget);
      verify(
        () => chat.sendMessage(
          2,
          'Hello there',
          messageType: 'text',
        ),
      ).called(1);
    });

    // TEST-057
    testWidgets('TEST-057: failed send removes optimistic message', (tester) async {
      final chat = MockChatService();
      when(
        () => chat.sendMessage(
          2,
          'Will fail',
          messageType: any(named: 'messageType'),
          mediaFile: any(named: 'mediaFile'),
          mediaDuration: any(named: 'mediaDuration'),
          expiresInSeconds: any(named: 'expiresInSeconds'),
          attachment: any(named: 'attachment'),
        ),
      ).thenThrow(ApiError(message: 'Send failed', code: 500));

      await pumpChatPage(tester, chat: chat);
      await sendChatMessage(tester, 'Will fail');
      await e2ePumpFrames(tester, frames: 4);

      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text('Will fail'),
        ),
        findsNothing,
      );
    });

    // TEST-058
    testWidgets('TEST-058: websocket message appears in open thread', (tester) async {
      final chat = MockChatService();
      final messageController = StreamController<Message>.broadcast();
      final ws = stubWebSocket(messageStream: messageController.stream);

      await pumpChatPage(tester, chat: chat, webSocket: ws, userId: 2);

      messageController.add(
        sampleMessage(id: 777, senderId: 2, receiverId: 1, text: 'Realtime ping'),
      );
      await e2ePumpFrames(tester, frames: 4);

      expect(find.text('Realtime ping'), findsOneWidget);
      await messageController.close();
    });
  });

  group('Chat thread media and pins', () {
    // TEST-059
    testWidgets('TEST-059: send photo opens picker and posts image message', (tester) async {
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      final fixturePath = e2eChatMediaFixturePath();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pickImage') {
          return fixturePath;
        }
        return null;
      });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final chat = MockChatService();
      when(
        () => chat.sendMessage(
          2,
          '',
          messageType: 'image',
          mediaFile: any(named: 'mediaFile'),
          mediaDuration: any(named: 'mediaDuration'),
          expiresInSeconds: any(named: 'expiresInSeconds'),
          attachment: any(named: 'attachment'),
        ),
      ).thenAnswer(
        (_) async => Message(
          id: 902,
          senderId: 1,
          receiverId: 2,
          message: '',
          messageType: 'image',
          createdAt: DateTime(2024, 6, 1),
          attachmentUrl: fixturePath,
        ),
      );

      await pumpChatPage(tester, chat: chat);
      await tester.tap(find.byIcon(Icons.attach_file));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photo'));
      await e2ePumpFrames(tester, frames: 10);

      verify(
        () => chat.sendMessage(
          2,
          '',
          messageType: 'image',
          mediaFile: any(named: 'mediaFile'),
        ),
      ).called(1);
    });

    // TEST-060
    testWidgets('TEST-060: pinned banner opens pinned messages sheet', (tester) async {
      final chat = MockChatService();
      final pinned = [
        sampleMessage(id: 11, text: 'Pinned one'),
        sampleMessage(id: 12, text: 'Pinned two'),
      ];

      await pumpChatPage(
        tester,
        chat: chat,
        pinnedCount: 2,
        pinned: pinned,
      );

      expect(find.text('2 pinned messages'), findsOneWidget);
      await tester.tap(find.text('2 pinned messages'));
      await tester.pumpAndSettle();

      expect(find.text('Pinned messages'), findsOneWidget);
      expect(find.text('Pinned one'), findsOneWidget);
      expect(find.text('Pinned two'), findsOneWidget);
    });
  });

  group('Video calls', () {
    FlutterExceptionHandler? _previousFlutterErrorHandler;

    setUp(() {
      _previousFlutterErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed') || message.contains('RenderFlex')) {
          return;
        }
        _previousFlutterErrorHandler?.call(details);
      };
    });

    tearDown(() {
      FlutterError.onError = _previousFlutterErrorHandler;
    });

    // TEST-061
    testWidgets('TEST-061: basid tier video call shows feature locked screen', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));
      final chat = MockChatService();
      stubChatThread(chat);
      final planLimits = MockPlanLimitsService();
      stubPlanLimitsService(planLimits, tier: 'basid');

      final router = chatTestRouter(
        chat: chat,
        initialLocation: '${AppRoutes.chat}?userId=2&userName=Alex',
        planLimits: planLimits,
        tier: 'basid',
      );

      await pumpChatRouter(
        tester,
        router: router,
        overrides: [
          ...chatThreadOverrides(chat: chat, planLimits: planLimits, tier: 'basid'),
        ],
      );
      await waitForChatThreadLoaded(tester);

      await tester.tap(chatVideoCallButton());
      await e2ePumpFrames(tester, frames: 8);

      expect(find.byType(FeatureLockedScreen), findsOneWidget);
      expect(find.text('Video calls'), findsOneWidget);
    });

    // TEST-062
    testWidgets('TEST-062: premium tier allows video calls and shows video action', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      final chat = MockChatService();
      final planLimits = MockPlanLimitsService();
      stubPlanLimitsService(planLimits, tier: 'silder');

      final access = await PlanGuard(planLimits).canMakeVideoCall();
      expect(access.isAllowed, isTrue);

      await pumpChatPage(
        tester,
        chat: chat,
        planLimits: planLimits,
        tier: 'silder',
      );

      expect(chatVideoCallButton(), findsOneWidget);
      expect(find.byType(FeatureLockedScreen), findsNothing);
    });
  });
}
