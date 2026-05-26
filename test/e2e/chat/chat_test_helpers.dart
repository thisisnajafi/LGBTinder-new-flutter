import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/data/models/chat.dart';
import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/data/services/chat_service.dart';
import 'package:lgbtindernew/features/chat/data/services/websocket_service.dart';
import 'package:lgbtindernew/features/chat/providers/chat_providers.dart';
import 'package:lgbtindernew/features/notifications/providers/notification_providers.dart';
import 'package:lgbtindernew/features/payments/data/services/plan_limits_service.dart';
import 'package:lgbtindernew/features/user/data/models/user_info.dart';
import 'package:lgbtindernew/features/user/data/services/user_service.dart';
import 'package:lgbtindernew/features/user/providers/user_providers.dart';
import 'package:lgbtindernew/pages/chat_list_page.dart';
import 'package:lgbtindernew/pages/chat_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/screens/feature_locked_screen.dart';
import 'package:lgbtindernew/screens/video_call_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/mock_services.dart';

class MockChatService extends Mock implements ChatService {}

class MockUserService extends Mock implements UserService {}

class MockWebSocketService extends Mock implements WebSocketService {}

Chat sampleChat({
  int id = 10,
  int userId = 2,
  String firstName = 'Alex',
  String? lastName,
  int unreadCount = 0,
  bool isOnline = false,
  String lastMessageText = 'Hey',
}) {
  return Chat(
    id: id,
    userId: userId,
    firstName: firstName,
    lastName: lastName,
    unreadCount: unreadCount,
    isOnline: isOnline,
    lastMessage: Message(
      id: 1,
      senderId: userId,
      receiverId: 1,
      message: lastMessageText,
      createdAt: DateTime(2024, 6, 1, 12, 0),
    ),
  );
}

Message sampleMessage({
  int id = 100,
  int senderId = 2,
  int receiverId = 1,
  String text = 'Hello',
}) {
  return Message(
    id: id,
    senderId: senderId,
    receiverId: receiverId,
    message: text,
    createdAt: DateTime(2024, 6, 1, 12, 0),
  );
}

UserInfo sampleCurrentUser({int id = 1}) {
  return UserInfo(
    id: id,
    firstName: 'Tester',
    lastName: 'User',
    email: 'tester@test.com',
  );
}

void stubChatList(MockChatService chat, {List<Chat> chats = const []}) {
  when(() => chat.getChatUsers()).thenAnswer((_) async => chats);
  when(() => chat.getChats()).thenAnswer((_) async => chats);
}

void stubChatThread(
  MockChatService chat, {
  int peerUserId = 2,
  List<Message> history = const [],
  int pinnedCount = 0,
  List<Message> pinned = const [],
}) {
  when(
    () => chat.getChatHistory(
      receiverId: peerUserId,
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => history);
  when(() => chat.markAsRead(peerUserId)).thenAnswer((_) async {});
  when(() => chat.getPinnedMessagesCount(peerUserId)).thenAnswer((_) async => pinnedCount);
  when(() => chat.getPinnedMessages(peerUserId)).thenAnswer((_) async => pinned);
}

void stubCurrentUser(MockUserService user, {int id = 1}) {
  when(() => user.getUserInfo()).thenAnswer((_) async => sampleCurrentUser(id: id));
}

MockWebSocketService stubWebSocket({Stream<Message>? messageStream}) {
  final ws = MockWebSocketService();
  final controller = StreamController<Message>.broadcast();

  when(() => ws.isConnected).thenReturn(true);
  when(() => ws.messageStream).thenAnswer((_) => messageStream ?? controller.stream);
  when(() => ws.typingStream).thenAnswer((_) => const Stream<Map<String, dynamic>>.empty());
  when(() => ws.onlineStatusStream)
      .thenAnswer((_) => const Stream<Map<String, dynamic>>.empty());
  when(() => ws.connectionStream).thenAnswer((_) => const Stream<bool>.empty());
  when(() => ws.connect()).thenAnswer((_) async {});
  when(() => ws.joinChat(any())).thenReturn(null);
  when(() => ws.leaveChat(any())).thenReturn(null);
  when(() => ws.sendTypingStatus(any(), any())).thenReturn(null);
  when(() => ws.disconnect()).thenReturn(null);

  return ws;
}

List<Override> chatListOverrides({
  required MockChatService chat,
  MockPlanLimitsService? planLimits,
}) {
  final plan = planLimits ?? MockPlanLimitsService();
  stubPlanLimitsService(plan, tier: 'basid');

  return [
    chatServiceProvider.overrideWithValue(chat),
    planLimitsServiceProvider.overrideWithValue(plan),
    unreadNotificationCountProvider.overrideWith((_) async => 0),
  ];
}

List<Override> chatThreadOverrides({
  required MockChatService chat,
  MockUserService? user,
  MockWebSocketService? webSocket,
  MockPlanLimitsService? planLimits,
  String tier = 'basid',
}) {
  final userService = user ?? MockUserService();
  final plan = planLimits ?? MockPlanLimitsService();
  stubCurrentUser(userService);
  stubPlanLimitsService(plan, tier: tier);

  return [
    chatServiceProvider.overrideWithValue(chat),
    userServiceProvider.overrideWithValue(userService),
    if (webSocket != null) webSocketServiceProvider.overrideWithValue(webSocket),
    planLimitsServiceProvider.overrideWithValue(plan),
  ];
}

Future<void> pumpChatListPage(
  WidgetTester tester, {
  required MockChatService chat,
  List<Chat> chats = const [],
  List<Override> extraOverrides = const [],
}) async {
  stubChatList(chat, chats: chats);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...chatListOverrides(chat: chat),
        ...extraOverrides,
      ],
      child: const MaterialApp(home: ChatListPage()),
    ),
  );
  await waitForChatListLoaded(tester);
}

Future<void> waitForChatListLoaded(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(ChatListPage).evaluate().isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      // ChatListPage schedules an 800ms stagger animation timer after load.
      await tester.pump(const Duration(milliseconds: 900));
      return;
    }
  }
}

void registerChatFallbacks() {
  registerFallbackValue(sampleMessage());
}

Future<void> pumpChatPage(
  WidgetTester tester, {
  required MockChatService chat,
  int userId = 2,
  String userName = 'Alex',
  List<Message> history = const [],
  int pinnedCount = 0,
  List<Message> pinned = const [],
  MockWebSocketService? webSocket,
  MockPlanLimitsService? planLimits,
  String tier = 'basid',
  List<Override> extraOverrides = const [],
}) async {
  stubChatThread(
    chat,
    peerUserId: userId,
    history: history,
    pinnedCount: pinnedCount,
    pinned: pinned,
  );

  final ws = webSocket ?? stubWebSocket();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...chatThreadOverrides(
          chat: chat,
          webSocket: ws,
          planLimits: planLimits,
          tier: tier,
        ),
        ...extraOverrides,
      ],
      child: MaterialApp(
        home: ChatPage(userId: userId, userName: userName),
      ),
    ),
  );
  await waitForChatThreadLoaded(tester);
}

Future<void> waitForChatThreadLoaded(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(ChatPage).evaluate().isNotEmpty &&
        find.text('No messages yet').evaluate().isNotEmpty) {
      return;
    }
    if (find.byIcon(Icons.send).evaluate().isNotEmpty) {
      return;
    }
  }
}

GoRouter chatTestRouter({
  required MockChatService chat,
  String initialLocation = AppRoutes.chat,
  MockPlanLimitsService? planLimits,
  String tier = 'basid',
}) {
  final plan = planLimits ?? MockPlanLimitsService();
  stubPlanLimitsService(plan, tier: tier);

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          if (userId == null) {
            return const ChatListPage();
          }
          return ChatPage(
            userId: int.parse(userId),
            userName: state.uri.queryParameters['userName'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.featureLocked,
        builder: (context, state) =>
            FeatureLockedScreen.fromQueryParams(state.uri.queryParameters),
      ),
    ],
  );
}

Future<void> pumpChatRouter(
  WidgetTester tester, {
  required GoRouter router,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await e2ePumpFrames(tester, frames: 5);
}

Finder chatFilterButton() => find.byIcon(Icons.filter_list);

Finder chatVideoCallButton() => find.byWidgetPredicate(
      (widget) => widget is AppSvgIcon && widget.assetPath == AppIcons.videoCall,
    );

Future<void> sendChatMessage(WidgetTester tester, String text) async {
  final field = find.byType(TextField);
  await tester.tap(field);
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await e2ePumpFrames(tester, frames: 6);
}

/// Absolute path to a small JPEG used for media-send tests.
String e2eChatMediaFixturePath() {
  return File('test/e2e/.tmp_wizard_photo.jpg').absolute.path;
}
