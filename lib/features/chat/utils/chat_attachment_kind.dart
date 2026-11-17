/// Maps a picked file name to a chat message type (CHAT-INPUT-002).
///
/// Upload allowlists match Laravel PR #5 (see [ChatUploadValidation]).
enum ChatAttachmentKind { image, video, audio, unsupported }

abstract final class ChatAttachmentKindResolver {
  static const List<String> imageSuffixes = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
  ];

  /// Backend accepts mp4, mov, webm, 3gp for video uploads.
  static const List<String> videoSuffixes = ['.mp4', '.mov', '.webm', '.3gp'];

  /// Backend accepts m4a, aac, mp3 for voice uploads.
  static const List<String> audioSuffixes = ['.m4a', '.aac', '.mp3'];

  static ChatAttachmentKind fromName(String name) {
    final lower = name.trim().toLowerCase();
    if (_endsWith(lower, imageSuffixes)) return ChatAttachmentKind.image;
    if (_endsWith(lower, videoSuffixes)) return ChatAttachmentKind.video;
    if (_endsWith(lower, audioSuffixes)) return ChatAttachmentKind.audio;
    return ChatAttachmentKind.unsupported;
  }

  static String? messageType(ChatAttachmentKind kind) {
    switch (kind) {
      case ChatAttachmentKind.image:
        return 'image';
      case ChatAttachmentKind.video:
        return 'video';
      case ChatAttachmentKind.audio:
        return 'voice';
      case ChatAttachmentKind.unsupported:
        return null;
    }
  }

  static bool _endsWith(String name, List<String> suffixes) {
    for (final suffix in suffixes) {
      if (name.endsWith(suffix)) return true;
    }
    return false;
  }
}
