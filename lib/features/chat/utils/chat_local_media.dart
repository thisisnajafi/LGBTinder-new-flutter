/// Local-vs-remote helpers for optimistic chat images (CHAT-IMG-001).
class ChatLocalMedia {
  ChatLocalMedia._();

  static bool isLocalPath(String? url) {
    if (url == null) return false;
    final value = url.trim();
    if (value.isEmpty) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }
    if (value.startsWith('file:')) return true;
    if (value.startsWith('/')) return true;
    return RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value);
  }

  static String toFilePath(String url) {
    final value = url.trim();
    if (value.startsWith('file:')) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }
}
