import 'chat_screenshot_ui.dart';

/// Preview text for chat list rows based on message type.
String chatMessagePreviewText({
  String? message,
  String? messageType,
  int? mediaDuration,
  bool isExpired = false,
  bool isDeleted = false,
}) {
  if (isDeleted) {
    return 'This message was deleted';
  }
  if (isExpired || messageType == 'expired') {
    return 'Expired';
  }
  switch (messageType) {
    case 'sticker':
      return 'Sticker';
    case 'image':
    case 'disappearing_image':
    case 'self_destruct':
      return 'Photo';
    case 'voice':
      if (mediaDuration != null && mediaDuration > 0) {
        final m = mediaDuration ~/ 60;
        final s = mediaDuration % 60;
        return 'Voice message $m:${s.toString().padLeft(2, '0')}';
      }
      return 'Voice message';
    case 'profile_link':
      return 'Shared a profile';
    case 'system':
      if (message == ChatScreenshotUi.screenshotBody ||
          (message?.trim().isEmpty ?? true)) {
        return ChatScreenshotUi.listPreview;
      }
      return message!.trim();
    case 'video':
    case 'disappearing_video':
      return 'Video';
    default:
      final text = message?.trim() ?? '';
      return text.isNotEmpty ? text : 'Message';
  }
}

bool isVoiceMessagePreview(String? messageType) => messageType == 'voice';
