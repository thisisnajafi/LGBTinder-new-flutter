import 'chat_attachment_kind.dart';

/// Client-side chat media rules matching
/// `lgbtinder-backend` `Chat*UploadService` + `config/chat_broadcasting.php`.
///
/// - Video: mp4 / mov / webm / 3gp, max 52_428_800 bytes (50 MiB)
/// - Voice: m4a / aac / mp3, max 5_242_880 bytes (5 MiB)
/// - Image: any `image/*`, max 5_242_880 bytes (5 MiB)
/// - Documents: not a chat message type on the backend (unsupported)
abstract final class ChatUploadValidation {
  /// [ChatVideoUploadService::maxBytes] / `chat_broadcasting.video_max_bytes`
  static const int maxVideoBytes = 52428800;

  /// [ChatVoiceUploadService::maxBytes] / `chat_broadcasting.voice_max_bytes`
  static const int maxVoiceBytes = 5242880;

  /// [ChatImageUploadService::maxBytes] / `chat_broadcasting.image_max_bytes`
  static const int maxImageBytes = 5242880;

  static const Set<String> videoExtensions = {'.mp4', '.mov', '.webm', '.3gp'};

  static const Set<String> voiceExtensions = {'.m4a', '.aac', '.mp3'};

  static const Set<String> imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
    '.heif',
  };

  static String extensionOf(String fileName) {
    final name = fileName.trim().toLowerCase().replaceAll(r'\', '/');
    final slash = name.lastIndexOf('/');
    final base = slash >= 0 ? name.substring(slash + 1) : name;
    final dot = base.lastIndexOf('.');
    if (dot < 0) return '';
    return base.substring(dot);
  }

  static bool isAllowedVideoName(String fileName) =>
      videoExtensions.contains(extensionOf(fileName));

  static bool isAllowedVoiceName(String fileName) =>
      voiceExtensions.contains(extensionOf(fileName));

  static bool isAllowedImageName(String fileName) =>
      imageExtensions.contains(extensionOf(fileName));

  /// Returns a friendly error, or `null` when the file is allowed.
  static String? validateVideo({
    required String fileName,
    required int fileSizeBytes,
  }) {
    if (!isAllowedVideoName(fileName)) {
      return 'Videos must be MP4, MOV, WebM, or 3GP.';
    }
    if (fileSizeBytes > maxVideoBytes) {
      return 'Video is too large. Maximum size is 50 MB.';
    }
    return null;
  }

  /// Returns a friendly error, or `null` when the file is allowed.
  static String? validateVoice({
    required String fileName,
    required int fileSizeBytes,
  }) {
    if (!isAllowedVoiceName(fileName)) {
      return 'Voice notes must be M4A, AAC, or MP3.';
    }
    if (fileSizeBytes > maxVoiceBytes) {
      return 'Voice note is too large. Maximum size is 5 MB.';
    }
    return null;
  }

  /// Returns a friendly error, or `null` when the file is allowed.
  static String? validateImage({
    required String fileName,
    required int fileSizeBytes,
  }) {
    if (fileName.isNotEmpty && !isAllowedImageName(fileName)) {
      return 'Only image files are allowed.';
    }
    if (fileSizeBytes > maxImageBytes) {
      return 'Image is too large. Maximum size is 5 MB.';
    }
    return null;
  }

  /// Validate by resolved chat message type.
  static String? validateForMessageType({
    required String messageType,
    required String fileName,
    required int fileSizeBytes,
  }) {
    return switch (messageType) {
      'video' || 'disappearing_video' => validateVideo(
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
      ),
      'voice' => validateVoice(
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
      ),
      'image' || 'disappearing_image' => validateImage(
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
      ),
      _ => null,
    };
  }

  /// Message types that must never carry a file attachment (backend 422).
  static bool allowsAttachment(String messageType) {
    final type = messageType.toLowerCase();
    return type != 'text' && type != 'sticker';
  }

  /// Maps a picked name through [ChatAttachmentKindResolver], then re-checks
  /// upload allowlists so legacy suffixes (avi, wav, …) stay unsupported.
  static String? messageTypeForUpload(String fileName) {
    final kind = ChatAttachmentKindResolver.fromName(fileName);
    final type = ChatAttachmentKindResolver.messageType(kind);
    if (type == 'video' && !isAllowedVideoName(fileName)) return null;
    if (type == 'voice' && !isAllowedVoiceName(fileName)) return null;
    if (type == 'image' && !isAllowedImageName(fileName)) return null;
    return type;
  }
}
