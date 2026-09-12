/// URL spans inside chat text (CHAT-UX-004).
class ChatLinkSpan {
  final String text;
  final String? url;

  const ChatLinkSpan({required this.text, this.url});

  bool get isLink => url != null;
}

class ChatLinkDetector {
  ChatLinkDetector._();

  static final RegExp _pattern = RegExp(
    r'(https?:\/\/[^\s<]+|www\.[^\s<]+)',
    caseSensitive: false,
  );

  static const String _trailing = '.,;:!?)]}\'"';

  static List<ChatLinkSpan> parse(String text) {
    if (text.isEmpty) return const [];
    final spans = <ChatLinkSpan>[];
    var cursor = 0;
    for (final match in _pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(ChatLinkSpan(text: text.substring(cursor, match.start)));
      }
      final raw = match.group(0)!;
      final trimmed = trimTrailingPunctuation(raw);
      final trailing = raw.substring(trimmed.length);
      final uri = toLaunchUri(trimmed);
      if (uri == null) {
        spans.add(ChatLinkSpan(text: raw));
      } else {
        spans.add(ChatLinkSpan(text: trimmed, url: trimmed));
        if (trailing.isNotEmpty) {
          spans.add(ChatLinkSpan(text: trailing));
        }
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(ChatLinkSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  static String? firstUrl(String text) {
    for (final span in parse(text)) {
      if (span.url != null) return span.url;
    }
    return null;
  }

  static String trimTrailingPunctuation(String value) {
    var end = value.length;
    while (end > 0 && _trailing.contains(value[end - 1])) {
      final ch = value[end - 1];
      if (ch == ')' || ch == ']') {
        final open = ch == ')' ? '(' : '[';
        final head = value.substring(0, end);
        if (_count(head, open) >= _count(head, ch)) break;
      }
      end--;
    }
    return end == value.length ? value : value.substring(0, end);
  }

  static Uri? toLaunchUri(String raw) {
    var value = trimTrailingPunctuation(raw.trim());
    if (value.isEmpty) return null;
    if (value.toLowerCase().startsWith('www.')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return uri;
  }

  static int _count(String input, String ch) {
    var n = 0;
    for (final unit in input.codeUnits) {
      if (unit == ch.codeUnitAt(0)) n++;
    }
    return n;
  }
}

/// OG preview cards (CHAT-BE-003 / CHAT-UX-004).
class ChatLinkPreview {
  ChatLinkPreview._();

  static const bool enabled = true;
}

/// Server OG payload for a chat URL.
class ChatOgPreview {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;

  const ChatOgPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.faviconUrl,
  });

  bool get hasContent {
    final heading = title?.trim() ?? '';
    final image = imageUrl?.trim() ?? '';
    return heading.isNotEmpty || image.isNotEmpty;
  }

  factory ChatOgPreview.fromJson(Map<String, dynamic> json) {
    return ChatOgPreview(
      url: json['url']?.toString() ?? '',
      title: _nonEmpty(json['title']),
      description: _nonEmpty(json['description']),
      imageUrl: _nonEmpty(json['image_url']),
      faviconUrl: _nonEmpty(json['favicon_url']),
    );
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
