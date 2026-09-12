import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_arrival_bounce.dart';

void main() {
  test('bounce plays only at the latest edge when motion is allowed', () {
    expect(
      ChatArrivalBounce.shouldPlay(
        nearBottom: true,
        animationsEnabled: true,
      ),
      isTrue,
    );
    expect(
      ChatArrivalBounce.shouldPlay(
        nearBottom: false,
        animationsEnabled: true,
      ),
      isFalse,
    );
    expect(
      ChatArrivalBounce.shouldPlay(
        nearBottom: true,
        animationsEnabled: false,
      ),
      isFalse,
    );
  });
}
