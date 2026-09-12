import 'package:uuid/uuid.dart';

/// Client-generated ids for optimistic chat rows (CHAT-RT-001).
class ChatClientIds {
  ChatClientIds._();

  static const _uuid = Uuid();

  static String next() => _uuid.v4();
}
