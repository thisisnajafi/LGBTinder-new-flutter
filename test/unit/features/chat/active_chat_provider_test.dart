import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lgbtindernew/features/chat/providers/active_chat_peer_bridge.dart';
import 'package:lgbtindernew/features/chat/providers/active_chat_provider.dart';
import 'package:lgbtindernew/features/chat/providers/chat_pusher_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveChatPeerBridge.getActivePeerUserId = null;
    ActiveChatPeerBridge.getActiveConversationId = null;
    ActiveChatPeerBridge.clearPendingPeer();
  });

  group('ActiveChatPeerBridge', () {
    test('conversation close debounce is 900ms', () {
      expect(
        ChatPusherLifecycleNotifier.conversationCloseDebounce,
        const Duration(milliseconds: 900),
      );
    });
    test('isActivePeer follows the live callback', () {
      ActiveChatPeerBridge.getActivePeerUserId = () => 42;
      expect(ActiveChatPeerBridge.isActivePeer(42), isTrue);
      expect(ActiveChatPeerBridge.isActivePeer(7), isFalse);
      expect(ActiveChatPeerBridge.isActivePeer(0), isFalse);
    });

    test('primeActivePeer suppresses FCM before Riverpod updates', () {
      ActiveChatPeerBridge.primeActivePeer(42);
      expect(ActiveChatPeerBridge.isActivePeer(42), isTrue);
      expect(ActiveChatPeerBridge.isActivePeer(7), isFalse);
    });

    test('isActiveConversation follows the live callback', () {
      ActiveChatPeerBridge.getActiveConversationId = () => 99;
      expect(ActiveChatPeerBridge.isActiveConversation(99), isTrue);
      expect(ActiveChatPeerBridge.isActiveConversation(1), isFalse);
    });

    test('persists peer and conversation for background isolates', () async {
      await ActiveChatPeerBridge.setActiveSession(
        peerUserId: 42,
        conversationId: 99,
      );
      expect(await ActiveChatPeerBridge.readActivePeerFromPrefs(), 42);
      expect(await ActiveChatPeerBridge.readActiveConversationFromPrefs(), 99);

      await ActiveChatPeerBridge.clearActiveSession();
      expect(await ActiveChatPeerBridge.readActivePeerFromPrefs(), isNull);
      expect(await ActiveChatPeerBridge.readActiveConversationFromPrefs(), isNull);
    });
  });

  group('activeChatSessionProvider', () {
    test('conversation id is non-null while the thread is marked active', () {
      final container = ProviderContainer(
        overrides: [
          chatPusherLifecycleProvider.overrideWith(_TrackingLifecycle.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatPusherLifecycleProvider.notifier);
      notifier.markActiveChat(peerUserId: 42, conversationId: 99);

      expect(ActiveChatPeerBridge.isActivePeer(42), isTrue);
      expect(container.read(activeChatPeerUserIdProvider), 42);
      expect(container.read(activeChatConversationIdProvider), 99);
      expect(container.read(activeChatSessionProvider).isSubscribed, isTrue);
    });

    testWidgets('peer stays active until the 900ms close debounce fires',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          chatPusherLifecycleProvider.overrideWith(_TrackingLifecycle.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatPusherLifecycleProvider.notifier);
      notifier.markActiveChat(peerUserId: 42, conversationId: 99);
      notifier.scheduleCloseConversation(conversationId: 99);

      await tester.pump(ChatPusherLifecycleNotifier.conversationCloseDebounce -
          const Duration(milliseconds: 1));
      expect(ActiveChatPeerBridge.isActivePeer(42), isTrue);
      expect(container.read(activeChatConversationIdProvider), 99);

      await tester.pump(const Duration(milliseconds: 2));
      expect(ActiveChatPeerBridge.isActivePeer(42), isFalse);
      expect(container.read(activeChatConversationIdProvider), isNull);
    });
  });

  group('CHAT-NOTIF-006 reconnect', () {
    test('setConnectedUser keeps the open peer and conversation', () {
      final container = ProviderContainer(
        overrides: [
          chatPusherLifecycleProvider.overrideWith(_TrackingLifecycle.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatPusherLifecycleProvider.notifier);
      notifier.markActiveChat(peerUserId: 42, conversationId: 99);
      notifier.setConnectedUser(1);

      expect(ActiveChatPeerBridge.isActivePeer(42), isTrue);
      expect(container.read(activeChatConversationIdProvider), 99);
      expect(container.read(chatPusherLifecycleProvider).isReady, isTrue);
      expect(container.read(chatPusherLifecycleProvider).userId, 1);
      expect(container.read(chatPusherLifecycleProvider).activePeerUserId, 42);
    });

    test('switching peers without a conversation id drops the stale thread', () {
      final container = ProviderContainer(
        overrides: [
          chatPusherLifecycleProvider.overrideWith(_TrackingLifecycle.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatPusherLifecycleProvider.notifier);
      notifier.markActiveChat(peerUserId: 42, conversationId: 99);
      notifier.markActiveChat(peerUserId: 7);

      expect(ActiveChatPeerBridge.isActivePeer(7), isTrue);
      expect(ActiveChatPeerBridge.isActivePeer(42), isFalse);
      expect(container.read(activeChatConversationIdProvider), isNull);
    });

    testWidgets('peer-only open still clears after the 900ms leave debounce',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          chatPusherLifecycleProvider.overrideWith(_TrackingLifecycle.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatPusherLifecycleProvider.notifier);
      notifier.markActiveChat(peerUserId: 42);
      notifier.scheduleCloseConversation();

      await tester.pump(ChatPusherLifecycleNotifier.conversationCloseDebounce -
          const Duration(milliseconds: 1));
      expect(ActiveChatPeerBridge.isActivePeer(42), isTrue);

      await tester.pump(const Duration(milliseconds: 2));
      expect(ActiveChatPeerBridge.isActivePeer(42), isFalse);
    });

    test('presencePeerIdsForReconnect includes list peers and the open chat', () {
      ChatListPresencePeersBridge.getPeerIds = () => {7, 8};
      addTearDown(() => ChatListPresencePeersBridge.getPeerIds = null);

      final container = ProviderContainer(
        overrides: [
          chatPusherLifecycleProvider.overrideWith(_TrackingLifecycle.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatPusherLifecycleProvider.notifier);
      notifier.markActiveChat(peerUserId: 42, conversationId: 99);

      expect(
        notifier.presencePeerIdsForReconnect(),
        {7, 8, 42},
      );
    });
  });
}

/// Skips Pusher user-connect so unit tests can drive [markActiveChat] only.
class _TrackingLifecycle extends ChatPusherLifecycleNotifier {
  @override
  ChatPusherLifecycleState build() {
    ActiveChatPeerBridge.getActivePeerUserId = () => state.activePeerUserId;
    ActiveChatPeerBridge.getActiveConversationId =
        () => state.activeConversationId;
    ref.onDispose(() {
      ActiveChatPeerBridge.getActivePeerUserId = null;
      ActiveChatPeerBridge.getActiveConversationId = null;
    });
    return const ChatPusherLifecycleState();
  }
}
