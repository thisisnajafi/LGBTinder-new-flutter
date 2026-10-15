import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/services/callkit_pending_flusher.dart';
import 'package:lgbtindernew/features/calls/data/services/callkit_terminal_request.dart';

void main() {
  group('stripDeclinesDuringPermissionPrompt', () {
    test('drops a decline recorded while the permission dialog is up', () {
      final kept = stripDeclinesDuringPermissionPrompt(
        const [
          CallKitPendingAction(callId: '64', kind: CallKitPendingKind.decline),
          CallKitPendingAction(callId: '67', kind: CallKitPendingKind.timeout),
        ],
        permissionRequestInFlight: true,
      );
      expect(kept, hasLength(1));
      expect(kept.single.kind, CallKitPendingKind.timeout);
      expect(kept.single.callId, '67');
    });

    test('keeps a real decline when no permission dialog is up', () {
      final kept = stripDeclinesDuringPermissionPrompt(
        const [
          CallKitPendingAction(callId: '64', kind: CallKitPendingKind.decline),
        ],
        permissionRequestInFlight: false,
      );
      expect(kept.single.kind, CallKitPendingKind.decline);
    });
  });

  group('mergeCallKitPending', () {
    test('decline replaces a timeout for the same call', () {
      final merged = mergeCallKitPending(
        const [
          CallKitPendingAction(callId: '70', kind: CallKitPendingKind.timeout),
        ],
        const CallKitPendingAction(
          callId: '70',
          kind: CallKitPendingKind.decline,
        ),
      );
      expect(merged, hasLength(1));
      expect(merged.single.kind, CallKitPendingKind.decline);
    });

    test('timeout does not replace a decline', () {
      final merged = mergeCallKitPending(
        const [
          CallKitPendingAction(callId: '70', kind: CallKitPendingKind.decline),
        ],
        const CallKitPendingAction(
          callId: '70',
          kind: CallKitPendingKind.timeout,
        ),
      );
      expect(merged.single.kind, CallKitPendingKind.decline);
    });

    test('round-trips the decline timestamp and drops a non-numeric id', () {
      final at = DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000);
      final encoded = encodeCallKitPending([
        CallKitPendingAction(
          callId: '70',
          kind: CallKitPendingKind.decline,
          recordedAt: at,
        ),
      ]);
      expect(decodeCallKitPending(encoded).single.recordedAt, at);
    });

    test('round-trips through json and drops a non-numeric id', () {
      final encoded = encodeCallKitPending(const [
        CallKitPendingAction(callId: '70', kind: CallKitPendingKind.decline),
      ]);
      final decoded = decodeCallKitPending(
        '[{"callId":"70","kind":"decline"},{"callId":"not-a-call","kind":"decline"}]',
      );
      expect(decodeCallKitPending(encoded).single.callId, '70');
      expect(decoded, hasLength(1));
    });
  });

  group('buildCallKitTerminalRequest', () {
    test('decline posts reject with the stored bearer token', () {
      final request = buildCallKitTerminalRequest(
        action: const CallKitPendingAction(
          callId: '70',
          kind: CallKitPendingKind.decline,
        ),
        token: 'stored-token',
        apiOrigin: 'https://api.lgbtfinder.com/',
      );
      expect(request, isNotNull);
      expect(
        request!.uri.toString(),
        'https://api.lgbtfinder.com/api/calls/70/reject',
      );
      expect(request.headers['Authorization'], 'Bearer stored-token');
      expect(request.body, contains('User rejected the call'));
      expect(request.uri.path, isNot(contains('/end')));
    });

    test('CallKit timeout posts end so the server stores missed', () {
      final request = buildCallKitTerminalRequest(
        action: const CallKitPendingAction(
          callId: '70',
          kind: CallKitPendingKind.timeout,
        ),
        token: 'stored-token',
        apiOrigin: 'http://10.0.2.2:8000',
      );
      expect(
        request!.uri.toString(),
        'http://10.0.2.2:8000/api/calls/70/end',
      );
      expect(request.body, contains('CallKit timeout'));
      expect(request.uri.path, isNot(contains('reject')));
    });

    test('missing token does not build a request', () {
      expect(
        buildCallKitTerminalRequest(
          action: const CallKitPendingAction(
            callId: '70',
            kind: CallKitPendingKind.decline,
          ),
          token: '  ',
          apiOrigin: 'https://api.lgbtfinder.com',
        ),
        isNull,
      );
    });
  });

  group('declinesEligibleForReplay', () {
    final now = DateTime.utc(2026, 10, 16, 1, 0, 0);

    CallKitPendingAction decline(String id, {Duration age = const Duration(seconds: 5)}) {
      return CallKitPendingAction(
        callId: id,
        kind: CallKitPendingKind.decline,
        recordedAt: now.subtract(age),
      );
    }

    test('replays a fresh decline for the current ringing call', () {
      final kept = declinesEligibleForReplay(
        actions: [decline('85')],
        now: now,
        currentIncomingCallId: '85',
        statusByCallId: const {'85': 'ringing'},
        statusChecked: true,
      );
      expect(kept.single.callId, '85');
    });

    test('drops timeout, stale, mismatched, and answered rows', () {
      final kept = declinesEligibleForReplay(
        actions: [
          const CallKitPendingAction(
            callId: '85',
            kind: CallKitPendingKind.timeout,
          ),
          decline('85', age: const Duration(seconds: 61)),
          decline('86'),
          decline('87'),
          CallKitPendingAction(
            callId: '88',
            kind: CallKitPendingKind.decline,
          ),
        ],
        now: now,
        currentIncomingCallId: '87',
        statusByCallId: const {'87': 'active'},
        statusChecked: true,
      );
      expect(kept, isEmpty);
    });
  });

  group('flushCallKitPending', () {
    test('drops a delivered decline and a 422 timeout', () async {
      final posts = <Uri>[];
      final remaining = await flushCallKitPending(
        actions: const [
          CallKitPendingAction(callId: '70', kind: CallKitPendingKind.decline),
          CallKitPendingAction(callId: '71', kind: CallKitPendingKind.timeout),
        ],
        token: 'stored-token',
        apiOrigin: 'https://api.lgbtfinder.com',
        post: (request) async {
          posts.add(request.uri);
          return request.uri.path.endsWith('/reject') ? 200 : 422;
        },
      );
      expect(remaining, isEmpty);
      expect(posts.map((uri) => uri.path), [
        '/api/calls/70/reject',
        '/api/calls/71/end',
      ]);
    });

    test('keeps the action when the token is missing or the network fails',
        () async {
      final kept = await flushCallKitPending(
        actions: const [
          CallKitPendingAction(callId: '70', kind: CallKitPendingKind.decline),
        ],
        token: null,
        apiOrigin: 'https://api.lgbtfinder.com',
        post: (_) async => 200,
      );
      expect(kept.single.callId, '70');

      final retried = await flushCallKitPending(
        actions: kept,
        token: 'stored-token',
        apiOrigin: 'https://api.lgbtfinder.com',
        post: (_) async => throw Exception('offline'),
      );
      expect(retried.single.kind, CallKitPendingKind.decline);
    });
  });
}
