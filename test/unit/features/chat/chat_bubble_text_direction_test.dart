import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/utils/chat_bubble_text_direction.dart';

void main() {
  test('Persian text is RTL, English LTR, empty LTR', () {
    expect(ChatBubbleTextDirection.of('سلام دوست من'), TextDirection.rtl);
    expect(ChatBubbleTextDirection.of('hello'), TextDirection.ltr);
    expect(ChatBubbleTextDirection.of('   '), TextDirection.ltr);
  });
}
