/// Copy and type helpers for self-destruct screenshot notices (CHAT-SD-005).
class ChatScreenshotUi {
  ChatScreenshotUi._();

  static const String systemType = 'system';
  static const String screenshotBody = 'screenshot';
  static const String listPreview = 'Screenshot taken';
  static const String theyTook = 'They took a screenshot';
  static const String youTook = 'You took a screenshot';

  static bool isSystemRow(Map<String, dynamic> message) {
    final type = message['type']?.toString() ?? message['message_type']?.toString();
    return type == systemType;
  }

  static bool isScreenshotNotice(Map<String, dynamic> message) {
    if (!isSystemRow(message)) return false;
    final body =
        message['text']?.toString() ?? message['message']?.toString() ?? '';
    return body == screenshotBody || body.isEmpty;
  }

  static String threadCaption({required bool isSent}) =>
      isSent ? youTook : theyTook;
}
