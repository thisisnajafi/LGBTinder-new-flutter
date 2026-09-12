import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/app_logger.dart';
import '../../features/chat/utils/chat_link_detector.dart';

/// Opens a chat URL in the external browser (CHAT-UX-004).
class ChatLinkOpener {
  ChatLinkOpener._();

  static Future<bool> Function(Uri uri) launch = _launch;

  static Future<bool> _launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void reset() => launch = _launch;

  static Future<void> open(String raw) async {
    final uri = ChatLinkDetector.toLaunchUri(raw);
    if (uri == null) return;
    try {
      await launch(uri);
    } catch (e) {
      AppLogger.warning(
        'open chat link failed',
        tag: 'ChatLink',
        error: e,
      );
    }
  }
}

/// Text with tappable, underlined http(s) / www URLs.
class ChatLinkedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color linkColor;

  const ChatLinkedText({
    super.key,
    required this.text,
    required this.style,
    required this.linkColor,
  });

  @override
  State<ChatLinkedText> createState() => _ChatLinkedTextState();
}

class _ChatLinkedTextState extends State<ChatLinkedText> {
  final List<TapGestureRecognizer> _recognizers = [];
  String? _cachedText;
  Color? _cachedLinkColor;
  TextStyle? _cachedStyle;
  List<InlineSpan> _spans = const [];

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _syncSpans() {
    if (_cachedText == widget.text &&
        _cachedLinkColor == widget.linkColor &&
        _cachedStyle == widget.style) {
      return;
    }
    _cachedText = widget.text;
    _cachedLinkColor = widget.linkColor;
    _cachedStyle = widget.style;
    _clearRecognizers();

    final parts = ChatLinkDetector.parse(widget.text);
    if (parts.isEmpty) {
      _spans = const [];
      return;
    }
    _spans = [
      for (final part in parts)
        if (part.url == null)
          TextSpan(text: part.text)
        else
          TextSpan(
            text: part.text,
            style: widget.style.copyWith(
              color: widget.linkColor,
              decoration: TextDecoration.underline,
              decorationColor: widget.linkColor,
            ),
            recognizer: () {
              final url = part.url!;
              final tap = TapGestureRecognizer()
                ..onTap = () => unawaited(ChatLinkOpener.open(url));
              _recognizers.add(tap);
              return tap;
            }(),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _syncSpans();
    if (_spans.isEmpty) {
      return Text(widget.text, style: widget.style);
    }
    return Text.rich(
      TextSpan(style: widget.style, children: _spans),
    );
  }
}
