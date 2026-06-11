/// Preview text for chat list rows based on message type.
String chatMessagePreviewText({
  String? message,
  String? messageType,
  int? mediaDuration,
}) {
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
        return 'Voice message ${m}:${s.toString().padLeft(2, '0')}';
      }
      return 'Voice message';
    case 'profile_link':
      return 'Shared a profile';
    case 'video':
    case 'disappearing_video':
      return 'Video';
    default:
      final text = message?.trim() ?? '';
      return text.isNotEmpty ? text : 'Message';
  }
}

bool isVoiceMessagePreview(String? messageType) => messageType == 'voice';
