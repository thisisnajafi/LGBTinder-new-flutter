import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/providers/chat_typing_providers.dart';
import 'package:lgbtindernew/features/chat/utils/chat_typing_outbound.dart';
import 'package:lgbtindernew/features/chat/utils/typing_indicator_controller.dart';
import 'package:lgbtindernew/shared/services/pusher_websocket_service.dart';

void main() {
  test('start debounce is 500ms so the peer can see dots within ~1s', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final outbound = ChatTypingOutbound(send: (value) async {
        sent.add(value);
      });

      outbound.onTextChanged('hello');
      async.elapse(const Duration(milliseconds: 499));
      expect(sent, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(sent, [true]);
    });
  });

  test('idle stop sends typing false after 3s', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final outbound = ChatTypingOutbound(send: (value) async {
        sent.add(value);
      });

      outbound.onTextChanged('hello');
      async.elapse(ChatTypingOutbound.startDebounce);
      async.elapse(ChatTypingOutbound.idleStop);
      expect(sent, [true, false]);
    });
  });

  test('focus lost cancels pending start and sends typing false', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final outbound = ChatTypingOutbound(send: (value) async {
        sent.add(value);
      });

      outbound.onTextChanged('hello');
      outbound.onFocusLost();
      async.elapse(ChatTypingOutbound.startDebounce);
      expect(sent, [false]);
    });
  });

  test('empty composer sends typing false immediately', () {
    fakeAsync((async) {
      final sent = <bool>[];
      final outbound = ChatTypingOutbound(send: (value) async {
        sent.add(value);
      });

      outbound.onTextChanged('   ');
      async.flushMicrotasks();
      expect(sent, [false]);
    });
  });

  test('received typing hides after 6s without a heartbeat', () {
    fakeAsync((async) {
      var visible = false;
      final controller = TypingIndicatorController(
        hideAfter: kTypingIndicatorHideDuration,
        onVisibilityChanged: (value) => visible = value,
      );

      controller.onTypingEvent(
        TypingEvent(
          userId: 12,
          conversationId: 3,
          isTyping: true,
          timestamp: DateTime(2026, 9, 11),
        ),
        peerUserId: 12,
        conversationId: 3,
      );
      expect(visible, isTrue);

      async.elapse(const Duration(seconds: 5));
      expect(visible, isTrue);

      async.elapse(const Duration(seconds: 1));
      expect(visible, isFalse);
      controller.dispose();
    });
  });
}
