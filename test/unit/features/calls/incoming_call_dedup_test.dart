import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/providers/incoming_call_provider.dart';
import 'package:lgbtindernew/features/calls/utils/call_ring_timeout.dart';
import 'package:lgbtindernew/shared/services/incoming_call_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

IncomingCallData _data(String id) => IncomingCallData(
      callId: id,
      callType: 'audio',
      callerId: 2,
      callerName: 'Caller $id',
    );

Map<String, dynamic> _payload(String id) => {
      'type': 'incoming_call',
      'call_id': id,
      'call_type': 'audio',
      'caller_id': 2,
      'caller_name': 'Caller $id',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late IncomingCallNotifier notifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IncomingCallHandler.clearPendingCallData();
    container = ProviderContainer();
    notifier = container.read(incomingCallProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    IncomingCallHandler.clearPendingCallData();
    await Future<void>.delayed(Duration.zero);
  });

  group('IncomingCallNotifier — the same call never rings twice', () {
    test('adopting a CallKit row shows it once', () {
      notifier.adoptRinging(_data('7'));
      expect(container.read(incomingCallProvider)?.callId, '7');
      expect(notifier.isClosed('7'), isFalse);

      // Resume + Pusher + listen all re-adopt the same id: still one call.
      notifier.adoptRinging(_data('7'));
      expect(container.read(incomingCallProvider)?.callId, '7');
    });

    test('ring timeout closes the call for every later source', () async {
      notifier.adoptRinging(_data('7'));
      await notifier.timeoutDismissFor('7');
      expect(container.read(incomingCallProvider), isNull);
      expect(notifier.isClosed('7'), isTrue);

      // Persisted payload read on the next resume.
      notifier.adoptRinging(_data('7'));
      expect(container.read(incomingCallProvider), isNull);

      // Late FCM copy of the same invite.
      notifier.present(_payload('7'));
      expect(container.read(incomingCallProvider), isNull);
    });

    test('caller cancel before the UI adopted the call blocks a ghost ring',
        () async {
      // Killed-app invite persisted by the push handler…
      await IncomingCallHandler.persistShow(_data('8'));
      expect(IncomingCallHandler.dataForCallId('8'), isNotNull);

      // …and Pusher reports the caller hung up before anything was shown.
      await notifier.dismissRemote('8');

      expect(notifier.isClosed('8'), isTrue);
      expect(IncomingCallHandler.dataForCallId('8'), isNull);
      expect(await IncomingCallHandler.loadPersisted(), isNull);

      notifier.adoptRinging(_data('8'));
      notifier.present(_payload('8'));
      expect(container.read(incomingCallProvider), isNull);
    });

    test('remote end while ringing hides the call and keeps it closed',
        () async {
      notifier.adoptRinging(_data('9'));
      await notifier.dismissRemote('9');

      expect(container.read(incomingCallProvider), isNull);
      notifier.adoptRinging(_data('9'));
      expect(container.read(incomingCallProvider), isNull);
    });

    test('closing one call does not block a different call', () async {
      notifier.adoptRinging(_data('7'));
      await notifier.timeoutDismissFor('7');

      notifier.adoptRinging(_data('10'));
      expect(container.read(incomingCallProvider)?.callId, '10');
    });

    test('remote end for another call leaves the ringing one alone',
        () async {
      notifier.adoptRinging(_data('11'));
      await notifier.dismissRemote('12');

      expect(container.read(incomingCallProvider)?.callId, '11');
      expect(notifier.isClosed('11'), isFalse);
      expect(notifier.isClosed('12'), isTrue);
    });

    test('closed-call memory is bounded', () async {
      for (var i = 0; i < 200; i++) {
        await notifier.dismissRemote('c$i');
      }
      // Oldest ids are forgotten, newest are kept.
      expect(notifier.isClosed('c0'), isFalse);
      expect(notifier.isClosed('c199'), isTrue);
    });
  });

  group('IncomingCallHandler — stale ringing payloads', () {
    test('freshness follows the ring timeout', () {
      final now = DateTime(2026, 1, 1, 12);
      final ring = CallRingTimeout.duration;

      expect(
        IncomingCallHandler.isRingingPayloadFresh(
          now.subtract(const Duration(seconds: 5)).millisecondsSinceEpoch,
          now: now,
        ),
        isTrue,
      );
      expect(
        IncomingCallHandler.isRingingPayloadFresh(
          now.subtract(ring).millisecondsSinceEpoch,
          now: now,
        ),
        isTrue,
      );
      expect(
        IncomingCallHandler.isRingingPayloadFresh(
          now
              .subtract(ring + const Duration(minutes: 1))
              .millisecondsSinceEpoch,
          now: now,
        ),
        isFalse,
      );
      // Payloads written before timestamps existed keep the old behavior.
      expect(IncomingCallHandler.isRingingPayloadFresh(null, now: now), isTrue);
    });

    test('a just-shown invite is restored as ringing', () async {
      await IncomingCallHandler.persistShow(_data('20'));
      final restored = await IncomingCallHandler.loadPersisted();

      expect(restored?.data.callId, '20');
      expect(restored?.accepted, isFalse);
    });

    test('an hour-old unanswered invite on disk is dropped, not rung',
        () async {
      await IncomingCallHandler.persistShow(_data('21'));
      final prefs = await SharedPreferences.getInstance();
      final payload = prefs.getString('lgbtfinder_pending_incoming_call');
      expect(payload, isNotNull);

      // Next process start: nothing in memory, only what is on disk.
      IncomingCallHandler.clearPendingCallData();
      await Future<void>.delayed(Duration.zero);
      SharedPreferences.setMockInitialValues({
        'lgbtfinder_pending_incoming_call': payload!,
        'lgbtfinder_pending_incoming_accepted': false,
        'lgbtfinder_pending_incoming_shown_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      });

      expect(await IncomingCallHandler.loadPersisted(), isNull);
      await Future<void>.delayed(Duration.zero);
      final after = await SharedPreferences.getInstance();
      expect(after.getString('lgbtfinder_pending_incoming_call'), isNull);
    });

    test('an answered call on disk is still restored regardless of age',
        () async {
      await IncomingCallHandler.markAccepted(_data('22'));
      final prefs = await SharedPreferences.getInstance();
      final payload = prefs.getString('lgbtfinder_pending_incoming_call');

      IncomingCallHandler.clearPendingCallData();
      await Future<void>.delayed(Duration.zero);
      SharedPreferences.setMockInitialValues({
        'lgbtfinder_pending_incoming_call': payload!,
        'lgbtfinder_pending_incoming_accepted': true,
        'lgbtfinder_pending_incoming_shown_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      });

      final restored = await IncomingCallHandler.loadPersisted();
      expect(restored?.data.callId, '22');
      expect(restored?.accepted, isTrue);
    });

    test('duplicates of the same invite do not extend its ringing window',
        () async {
      await IncomingCallHandler.persistShow(_data('23'));
      final prefs = await SharedPreferences.getInstance();
      final first = prefs.getInt('lgbtfinder_pending_incoming_shown_at');

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await IncomingCallHandler.persistShow(_data('23'));

      expect(prefs.getInt('lgbtfinder_pending_incoming_shown_at'), first);
    });
  });
}
