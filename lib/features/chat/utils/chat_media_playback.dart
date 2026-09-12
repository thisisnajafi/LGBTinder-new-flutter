import 'package:flutter/foundation.dart';

/// Stops in-thread voice when another media player starts (CHAT-IMG-007).
class ChatMediaPlayback {
  ChatMediaPlayback._();

  static final ValueNotifier<int> interruptToken = ValueNotifier<int>(0);

  static void interrupt() {
    interruptToken.value++;
  }
}
