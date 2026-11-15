import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/calls/data/models/active_call_session.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/pages/incoming_call_page.dart';
import 'package:lgbtindernew/features/calls/providers/incoming_call_provider.dart';
import 'package:lgbtindernew/features/calls/utils/call_navigation.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _call = IncomingCallData(
  callId: '131',
  callType: 'audio',
  callerId: 2,
  callerName: 'Test Caller',
);

/// Incoming notifier with the network / CallKit side effects cut out, so the
/// tests drive exactly the state changes the real flows produce.
class _FakeIncoming extends IncomingCallNotifier {
  final Set<String> answered = <String>{};

  @override
  IncomingCallData? build() => null;

  @override
  bool get isAppForeground => true;

  @override
  bool wasAnswered(String callId) => answered.contains(callId);

  void ring(IncomingCallData data) => state = data;

  /// Decline / caller cancelled / ring timeout: state simply goes away.
  void close() => state = null;

  /// In-app or CallKit accept: marked answered, then state goes away.
  void answer(String callId) {
    answered.add(callId);
    state = null;
  }
}

GoRouter _router({String initial = '/chat', bool realIncomingPage = false}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/chat',
        builder: (_, __) => const Scaffold(body: Text('chat')),
      ),
      GoRoute(
        path: AppRoutes.incomingCall,
        builder: (_, __) => realIncomingPage
            ? const IncomingCallPage()
            : const Scaffold(body: Text('incoming')),
      ),
      GoRoute(
        path: AppRoutes.outgoingCall,
        builder: (_, __) => const Scaffold(body: Text('in-call')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
    ],
  );
}

/// The incoming page has a looping pulse, so `pumpAndSettle` never returns.
/// Step far enough for a route transition to finish and be removed.
Future<void> _settleRoutes(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

List<String> _stack(GoRouter router) => router
    .routerDelegate.currentConfiguration.matches
    .map((m) => m.matchedLocation)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('leaveIncomingCallRoute', () {
    testWidgets('pops an incoming page pushed over another route',
        (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push(AppRoutes.incomingCall);
      await tester.pumpAndSettle();

      // The reason the old self-pop never fired: the URI is still the base.
      expect(router.routerDelegate.currentConfiguration.uri.path, '/chat');
      expect(topCallStackPath(router), AppRoutes.incomingCall);

      expect(leaveIncomingCallRoute(router), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('chat'), findsOneWidget);
      expect(find.text('incoming'), findsNothing);
      expect(_stack(router), ['/chat']);
    });

    testWidgets('never touches a live in-call page or the page below it',
        (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push('${AppRoutes.outgoingCall}?callId=131');
      await tester.pumpAndSettle();

      expect(leaveIncomingCallRoute(router), isFalse);
      await tester.pumpAndSettle();

      expect(find.text('in-call'), findsOneWidget);
      expect(_stack(router), ['/chat', AppRoutes.outgoingCall]);

      // And with nothing call-related on top it is a no-op too.
      leaveCallRoutes(router);
      await tester.pumpAndSettle();
      expect(leaveIncomingCallRoute(router), isFalse);
      expect(_stack(router), ['/chat']);
    });

    testWidgets('removes stacked duplicates but stops at the base route',
        (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push(AppRoutes.incomingCall);
      await tester.pumpAndSettle();
      router.push(AppRoutes.incomingCall);
      await tester.pumpAndSettle();

      expect(leaveIncomingCallRoute(router), isTrue);
      await tester.pumpAndSettle();

      expect(_stack(router), ['/chat']);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('a lone incoming route goes home instead of staying black',
        (tester) async {
      final router = _router(initial: AppRoutes.incomingCall);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('incoming'), findsOneWidget);

      expect(leaveIncomingCallRoute(router), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('incoming'), findsNothing);
    });
  });

  group('active call route detection (imperative push aware)', () {
    testWidgets('finds the in-call page by call id', (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(isActiveCallRouteOnStack(router, '131'), isFalse);

      router.push('${AppRoutes.outgoingCall}?callId=131&recipientId=2');
      await tester.pumpAndSettle();

      expect(isActiveCallRouteOnStack(router, '131'), isTrue);
      expect(isActiveCallRouteOnStack(router, '132'), isFalse);
      expect(isActiveCallRouteOnStack(router, ''), isFalse);
    });

    testWidgets('restoreActiveCallRoute does not stack a second call page',
        (tester) async {
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      const session = ActiveCallSession(
        callId: 131,
        peerId: 2,
        peerName: 'Peer',
        isVideo: false,
      );

      restoreActiveCallRoute(router, session);
      await tester.pumpAndSettle();
      expect(_stack(router), ['/chat', AppRoutes.outgoingCall]);

      // Notification tap / banner tap while the page is already showing.
      restoreActiveCallRoute(router, session);
      restoreActiveCallRoute(router, session);
      await tester.pumpAndSettle();

      expect(_stack(router), ['/chat', AppRoutes.outgoingCall]);
    });
  });

  group('IncomingCallPage', () {
    Future<(GoRouter, _FakeIncoming)> pumpRinging(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [incomingCallProvider.overrideWith(_FakeIncoming.new)],
      );
      addTearDown(container.dispose);
      final router = _router(realIncomingPage: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      final notifier =
          container.read(incomingCallProvider.notifier) as _FakeIncoming;
      notifier.ring(_call);
      router.push(AppRoutes.incomingCall);
      await _settleRoutes(tester);
      expect(find.text('Test Caller'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      return (router, notifier);
    }

    testWidgets('leaves when the call is declined / cancelled (no black page)',
        (tester) async {
      final (router, notifier) = await pumpRinging(tester);

      notifier.close();
      await _settleRoutes(tester);

      expect(_stack(router), ['/chat']);
      expect(find.byType(IncomingCallPage), findsNothing);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('answered call is replaced by the in-call page, not popped',
        (tester) async {
      final (router, notifier) = await pumpRinging(tester);

      // Same order as IncomingCallNotifier.accept().
      openActiveCallReplacingIncoming(router, _call);
      notifier.answer(_call.callId);
      await _settleRoutes(tester);

      expect(_stack(router), ['/chat', AppRoutes.outgoingCall]);
      expect(find.text('in-call'), findsOneWidget);

      // Past the grace window: nothing pops the live call.
      await tester.pump(const Duration(seconds: 3));
      expect(_stack(router), ['/chat', AppRoutes.outgoingCall]);

      leaveCallRoutes(router);
      await _settleRoutes(tester);
      expect(_stack(router), ['/chat']);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('answered call whose in-call page never opens still leaves',
        (tester) async {
      final (router, notifier) = await pumpRinging(tester);

      notifier.answer(_call.callId);
      await tester.pump();
      await tester.pump();
      // Inside the grace window the accept path still owns navigation.
      expect(_stack(router), ['/chat', AppRoutes.incomingCall]);

      await tester.pump(const Duration(seconds: 3));
      await _settleRoutes(tester);

      expect(_stack(router), ['/chat']);
      expect(find.byType(IncomingCallPage), findsNothing);
    });

    testWidgets('a second ring while leaving keeps the page', (tester) async {
      final (router, notifier) = await pumpRinging(tester);

      notifier.close();
      // New invite lands before the post-frame leave runs.
      notifier.ring(
        const IncomingCallData(
          callId: '132',
          callType: 'video',
          callerId: 3,
          callerName: 'Second Caller',
        ),
      );
      await _settleRoutes(tester);

      expect(_stack(router), ['/chat', AppRoutes.incomingCall]);
      expect(find.text('Second Caller'), findsOneWidget);
    });
  });
}
