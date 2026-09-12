import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_link_detector.dart';

void main() {
  test('splits plain text around http(s) and www URLs', () {
    final spans = ChatLinkDetector.parse(
      'see https://example.com/a and www.test.dev/x please',
    );
    expect(spans.map((s) => s.text).toList(), [
      'see ',
      'https://example.com/a',
      ' and ',
      'www.test.dev/x',
      ' please',
    ]);
    expect(spans[1].url, 'https://example.com/a');
    expect(spans[3].url, 'www.test.dev/x');
  });

  test('strips trailing sentence punctuation from the URL', () {
    final spans = ChatLinkDetector.parse('Go to https://example.com.');
    expect(spans.map((s) => s.text).toList(), [
      'Go to ',
      'https://example.com',
      '.',
    ]);
    expect(spans[1].url, 'https://example.com');
  });

  test('keeps balanced parentheses inside a path', () {
    const raw = 'https://en.wikipedia.org/wiki/Hello_(world)';
    expect(ChatLinkDetector.parse(raw).single.url, raw);
  });

  test('strips a dangling closing paren after a URL', () {
    final spans = ChatLinkDetector.parse('see https://example.com).');
    expect(spans[1].url, 'https://example.com');
  });

  test('toLaunchUri only allows http(s)', () {
    expect(
      ChatLinkDetector.toLaunchUri('www.example.com/x')?.toString(),
      'https://www.example.com/x',
    );
    expect(ChatLinkDetector.toLaunchUri('javascript:alert(1)'), isNull);
    expect(ChatLinkDetector.toLaunchUri('ftp://files.example'), isNull);
  });

  test('preview cards are enabled when the OG API exists', () {
    expect(ChatLinkPreview.enabled, isTrue);
  });
}
