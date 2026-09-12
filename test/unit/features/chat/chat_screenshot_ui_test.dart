import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_screenshot_ui.dart';

void main() {
  test('screenshot notice copy depends on sent vs received', () {
    expect(
      ChatScreenshotUi.threadCaption(isSent: true),
      ChatScreenshotUi.youTook,
    );
    expect(
      ChatScreenshotUi.threadCaption(isSent: false),
      ChatScreenshotUi.theyTook,
    );
  });

  test('detects system screenshot rows', () {
    expect(
      ChatScreenshotUi.isScreenshotNotice({
        'type': 'system',
        'text': 'screenshot',
      }),
      isTrue,
    );
    expect(
      ChatScreenshotUi.isSystemRow({'type': 'text', 'text': 'hi'}),
      isFalse,
    );
  });
}
