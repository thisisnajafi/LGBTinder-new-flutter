import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/widgets/verification/verification_video_limits.dart';

void main() {
  test('video can finish only after 5 seconds and must stop at 10', () {
    expect(
      VerificationVideoLimits.canFinish(const Duration(seconds: 4)),
      isFalse,
    );
    expect(
      VerificationVideoLimits.canFinish(const Duration(seconds: 5)),
      isTrue,
    );
    expect(
      VerificationVideoLimits.mustFinish(const Duration(seconds: 9)),
      isFalse,
    );
    expect(
      VerificationVideoLimits.mustFinish(const Duration(seconds: 10)),
      isTrue,
    );
    expect(
      VerificationVideoLimits.clock(const Duration(milliseconds: 10500)),
      '10.0s',
    );
  });
}
