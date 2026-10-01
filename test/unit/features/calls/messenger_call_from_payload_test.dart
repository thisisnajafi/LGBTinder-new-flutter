import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/utils/messenger_call_from_payload.dart';

void main() {
  test('messengerCallFromPayload fills ringing call for the callee', () {
    final call = messengerCallFromPayload(
      {
        'call_id': 42,
        'caller_id': 7,
        'call_type': 'video',
        'caller_name': 'Alex N',
      },
      currentUserId: 9,
    );

    expect(call, isNotNull);
    expect(call!.id, 42);
    expect(call.callerId, 7);
    expect(call.receiverId, 9);
    expect(call.status, 'ringing');
    expect(call.isVideoCall, isTrue);
  });

  test('durationFromCallPayload reads seconds', () {
    expect(
      durationFromCallPayload({'duration': 12}),
      const Duration(seconds: 12),
    );
    expect(durationFromCallPayload({'duration_seconds': '0'}), isNull);
  });
}
