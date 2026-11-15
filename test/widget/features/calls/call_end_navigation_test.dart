import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/utils/call_end_orchestrator.dart';
import 'package:lgbtindernew/features/calls/utils/call_navigation.dart';
import 'package:lgbtindernew/routes/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('leaveCallRoutes', () {
    testWidgets('pops duplicate incoming under the in-call page', (tester) async {
      final router = GoRouter(
        initialLocation: '/chat',
        routes: [
          GoRoute(
            path: '/chat',
            builder: (_, __) => const Scaffold(body: Text('chat')),
          ),
          GoRoute(
            path: AppRoutes.incomingCall,
            builder: (_, __) => const Scaffold(body: Text('incoming')),
          ),
          GoRoute(
            path: AppRoutes.outgoingCall,
            builder: (_, __) => const Scaffold(body: Text('outgoing')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const Scaffold(body: Text('home')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push(AppRoutes.incomingCall);
      await tester.pumpAndSettle();
      router.push(AppRoutes.incomingCall);
      await tester.pumpAndSettle();
      router.push('${AppRoutes.outgoingCall}?callId=131');
      await tester.pumpAndSettle();

      expect(find.text('outgoing'), findsOneWidget);

      leaveCallRoutes(router, callId: '131');
      await tester.pumpAndSettle();

      expect(find.text('outgoing'), findsNothing);
      expect(find.text('incoming'), findsNothing);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('empty call stack falls back to home', (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.outgoingCall,
        routes: [
          GoRoute(
            path: AppRoutes.outgoingCall,
            builder: (_, __) => const Scaffold(body: Text('outgoing-only')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const Scaffold(body: Text('home')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('outgoing-only'), findsOneWidget);

      leaveCallRoutes(router);
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('outgoing-only'), findsNothing);
    });

    testWidgets('disposed-widget end still navigates via captured router',
        (tester) async {
      final orch = CallEndOrchestrator();
      expect(orch.beginEnd('55'), isTrue);

      final router = GoRouter(
        initialLocation: '/safe',
        routes: [
          GoRoute(
            path: '/safe',
            builder: (_, __) => const Scaffold(body: Text('safe')),
          ),
          GoRoute(
            path: AppRoutes.outgoingCall,
            builder: (_, __) => const Scaffold(body: Text('call')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push(AppRoutes.outgoingCall);
      await tester.pumpAndSettle();

      // Simulate end after the triggering widget unmounted: only router remains.
      leaveCallRoutes(router, callId: '55');
      orch.markEnded('55');
      await tester.pumpAndSettle();

      expect(orch.beginEnd('55'), isFalse);
      expect(find.text('safe'), findsOneWidget);
      expect(find.text('call'), findsNothing);
    });
  });

  group('openActiveCallReplacingIncoming', () {
    testWidgets('replaces incoming instead of stacking', (tester) async {
      final router = GoRouter(
        initialLocation: '/chat',
        routes: [
          GoRoute(
            path: '/chat',
            builder: (_, __) => const Scaffold(body: Text('chat')),
          ),
          GoRoute(
            path: AppRoutes.incomingCall,
            builder: (_, __) => const Scaffold(body: Text('incoming')),
          ),
          GoRoute(
            path: AppRoutes.outgoingCall,
            builder: (_, __) => const Scaffold(body: Text('outgoing')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push(AppRoutes.incomingCall);
      await tester.pumpAndSettle();

      openActiveCallReplacingIncoming(
        router,
        const IncomingCallData(
          callId: '131',
          callType: 'audio',
          callerId: 2,
          callerName: 'Peer',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('outgoing'), findsOneWidget);
      leaveCallRoutes(router);
      await tester.pumpAndSettle();
      expect(find.text('chat'), findsOneWidget);
      expect(find.text('incoming'), findsNothing);
    });
  });
}
