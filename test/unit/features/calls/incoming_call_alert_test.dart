import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/data/services/call_kit_service.dart';
import 'package:lgbtindernew/features/calls/utils/full_screen_intent_gate.dart';
import 'package:lgbtindernew/shared/services/background_message_display.dart';
import 'package:lgbtindernew/shared/services/notification_quick_actions.dart';

void main() {
  test('incoming call requests the full-screen locked UI', () {
    final params = buildIncomingCallKitParams(
      data: const IncomingCallData(
        callId: '15',
        callType: 'video',
        callerId: 4,
        callerName: 'Alex',
      ),
      ringtone: 'call_ringtone',
      avatar: 'https://cdn.example/a.jpg',
      backgroundColor: '#121212',
      actionColor: '#EC4899',
    );

    expect(params.android?.isCustomNotification, isTrue);
    expect(params.android?.isShowFullLockedScreen, isTrue);
    expect(params.android?.isImportant, isTrue);
    expect(params.android?.ringtonePath, 'call_ringtone');
    expect(params.missedCallNotification?.isShowCallback, isTrue);
    expect(params.missedCallNotification?.callbackText, 'Call back');
    expect(params.missedCallNotification?.showNotification, isTrue);
  });

  test('full-screen intent is asked once for a denied signed-in user', () {
    final session = FullScreenIntentPromptSession();
    expect(session.shouldAsk(canUseFullScreenIntent: false), isTrue);
    expect(session.shouldAsk(canUseFullScreenIntent: true), isFalse);

    session.remember(FullScreenIntentChoice.notNow);
    expect(session.shouldAsk(canUseFullScreenIntent: false), isFalse);

    final opened = FullScreenIntentPromptSession();
    expect(opened.shouldAsk(canUseFullScreenIntent: false), isTrue);
    opened.remember(FullScreenIntentChoice.openSettings);
    expect(opened.shouldAsk(canUseFullScreenIntent: false), isFalse);
    expect(opened.shouldAsk(canUseFullScreenIntent: true), isFalse);
  });

  test('full-screen intent settings open once when the permission is missing', () {
    expect(
      shouldPromptFullScreenIntent(
        canUseFullScreenIntent: false,
        alreadyPrompted: false,
      ),
      isTrue,
    );
    expect(
      shouldPromptFullScreenIntent(
        canUseFullScreenIntent: false,
        alreadyPrompted: true,
      ),
      isFalse,
    );
    expect(
      shouldPromptFullScreenIntent(
        canUseFullScreenIntent: true,
        alreadyPrompted: false,
      ),
      isFalse,
    );
  });

  test('missed call row and group summary both keep Call back', () {
    final row = missedCallAndroidDetails(
      title: 'Missed call',
      body: 'You missed a video call from Alex',
      tag: 'lgbtfinder-missed_call-15',
    );
    final summary = missedCallAndroidDetails(
      title: 'Missed call',
      body: 'You missed a video call from Alex',
      tag: 'missed_calls',
      summary: true,
    );

    expect(row.actions, isNotNull);
    expect(row.actions!.single.id, kNotificationActionCallBack);
    expect(row.actions!.single.title, 'Call back');
    expect(row.actions!.single.showsUserInterface, isTrue);
    expect(row.groupKey, kMissedCallGroupKey);
    expect(summary.actions!.single.id, kNotificationActionCallBack);
    expect(summary.groupKey, kMissedCallGroupKey);
    expect(summary.channelId, kLgbtfinderCallsChannelId);
  });
}
