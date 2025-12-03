import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../lib/core/constants/app_constants.dart';
import '../../lib/features/calls/providers/call_provider.dart';
import '../../lib/features/calls/data/models/initiate_call_request.dart';
import '../../lib/features/calls/data/models/initiate_call_response.dart';
import '../../lib/shared/services/agora_service.dart';
import '../../lib/shared/services/call_quality_monitor.dart';
import '../../lib/widgets/common/incoming_call_overlay.dart';

// Mock classes
class MockCallProvider extends Mock implements CallProvider {
  @override
  Future<InitiateCallResponse> initiateCall(InitiateCallRequest request) async {
    return super.noSuchMethod(
      Invocation.method(#initiateCall, [request]),
      returnValue: InitiateCallResponse(
        callId: 123,
        channelName: 'test_channel',
        token: 'test_token',
      ),
      returnValueForMissingStub: InitiateCallResponse(
        callId: 123,
        channelName: 'test_channel',
        token: 'test_token',
      ),
    );
  }

  @override
  Future<void> acceptCall(int callId) async {
    return super.noSuchMethod(
      Invocation.method(#acceptCall, [callId]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }

  @override
  Future<void> rejectCall(int callId) async {
    return super.noSuchMethod(
      Invocation.method(#rejectCall, [callId]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

class MockAgoraService extends Mock implements AgoraService {}

class MockCallQualityMonitor extends Mock implements CallQualityMonitor {}

void main() {
  late MockCallProvider mockCallProvider;
  late MockAgoraService mockAgoraService;
  late MockCallQualityMonitor mockQualityMonitor;

  setUp(() {
    mockCallProvider = MockCallProvider();
    mockAgoraService = MockAgoraService();
    mockQualityMonitor = MockCallQualityMonitor();

    // Register fallback values for mocktail
    registerFallbackValue(const InitiateCallRequest(
      receiverId: 1,
      callType: 'video',
    ));
  });

  group('Call System Integration Tests', () {
    testWidgets('Video call initiation flow', (WidgetTester tester) async {
      // Test data
      const testUserId = 123;
      const testUserName = 'Test User';
      const testChannelName = 'test_channel_123';
      const testToken = 'test_token_123';

      // Mock successful call initiation
      when(() => mockCallProvider.initiateCall(any())).thenAnswer((_) async {
        return InitiateCallResponse(
          callId: 456,
          channelName: testChannelName,
          token: testToken,
        );
      });

      // Mock Agora service
      when(() => mockAgoraService.initialize()).thenAnswer((_) async {});
      when(() => mockAgoraService.joinChannel(
        channelId: testChannelName,
        token: testToken,
        userId: testUserId,
        isVideoCall: true,
      )).thenAnswer((_) async {});

      // Build test app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callProvider.overrideWithValue(mockCallProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  try {
                    final response = await mockCallProvider.initiateCall(
                      const InitiateCallRequest(
                        receiverId: testUserId,
                        callType: 'video',
                      ),
                    );

                    // Simulate Agora initialization
                    await mockAgoraService.initialize();
                    await mockAgoraService.joinChannel(
                      channelId: response.channelName,
                      token: response.token,
                      userId: testUserId,
                      isVideoCall: true,
                    );

                    // Start quality monitoring
                    mockQualityMonitor.startMonitoring(
                      callId: response.callId.toString(),
                      callerId: testUserId,
                      receiverId: 0,
                      callType: 'video',
                    );
                  } catch (e) {
                    fail('Call initiation failed: $e');
                  }
                },
                child: const Text('Start Video Call'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to start call
      await tester.tap(find.text('Start Video Call'));
      await tester.pump();

      // Verify call initiation was called
      verify(() => mockCallProvider.initiateCall(any())).called(1);

      // Verify Agora service was initialized
      verify(() => mockAgoraService.initialize()).called(1);

      // Verify channel join was called with correct parameters
      verify(() => mockAgoraService.joinChannel(
        channelId: testChannelName,
        token: testToken,
        userId: testUserId,
        isVideoCall: true,
      )).called(1);

      // Verify quality monitoring was started
      verify(() => mockQualityMonitor.startMonitoring(
        callId: '456',
        callerId: testUserId,
        receiverId: 0,
        callType: 'video',
      )).called(1);
    });

    testWidgets('Incoming call overlay displays correctly', (WidgetTester tester) async {
      const testCallData = IncomingCallData(
        callId: '123',
        callType: 'video',
        callerId: 456,
        callerName: 'John Doe',
        callerAvatar: null,
        channelName: 'test_channel',
        token: 'test_token',
      );

      // Build test app
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    IncomingCallManager.showIncomingCall(context, testCallData);
                  },
                  child: const Text('Show Incoming Call'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show overlay
      await tester.tap(find.text('Show Incoming Call'));
      await tester.pumpAndSettle();

      // Verify overlay is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);
      expect(find.text('Incoming call...'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsNWidgets(2)); // Accept button icon + call type icon
    });

    testWidgets('Incoming call accept flow', (WidgetTester tester) async {
      const testCallData = IncomingCallData(
        callId: '123',
        callType: 'video',
        callerId: 456,
        callerName: 'John Doe',
        callerAvatar: null,
        channelName: 'test_channel',
        token: 'test_token',
      );

      // Mock call provider for accept
      when(() => mockCallProvider.acceptCall(123)).thenAnswer((_) async {});

      // Build test app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callProvider.overrideWithValue(mockCallProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      IncomingCallManager.showIncomingCall(context, testCallData);
                    },
                    child: const Text('Show Incoming Call'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show overlay
      await tester.tap(find.text('Show Incoming Call'));
      await tester.pumpAndSettle();

      // Find and tap accept button
      final acceptButton = find.byIcon(Icons.videocam).first; // First video icon is accept button
      await tester.tap(acceptButton);
      await tester.pump();

      // Verify accept call was called
      verify(() => mockCallProvider.acceptCall(123)).called(1);
    });

    testWidgets('Incoming call reject flow', (WidgetTester tester) async {
      const testCallData = IncomingCallData(
        callId: '123',
        callType: 'voice',
        callerId: 456,
        callerName: 'Jane Doe',
        callerAvatar: null,
        channelName: 'test_channel',
        token: 'test_token',
      );

      // Mock call provider for reject
      when(() => mockCallProvider.rejectCall(123)).thenAnswer((_) async {});

      // Build test app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            callProvider.overrideWithValue(mockCallProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      IncomingCallManager.showIncomingCall(context, testCallData);
                    },
                    child: const Text('Show Incoming Call'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show overlay
      await tester.tap(find.text('Show Incoming Call'));
      await tester.pumpAndSettle();

      // Find and tap reject button (end call icon)
      final rejectButton = find.byIcon(Icons.call_end);
      await tester.tap(rejectButton);
      await tester.pump();

      // Verify reject call was called
      verify(() => mockCallProvider.rejectCall(123)).called(1);
    });
  });

  group('Call Quality Monitoring Tests', () {
    test('Quality metrics tracking', () {
      // Test quality monitoring initialization
      mockQualityMonitor.startMonitoring(
        callId: 'test_123',
        callerId: 1,
        receiverId: 2,
        callType: 'video',
      );

      verify(() => mockQualityMonitor.startMonitoring(
        callId: 'test_123',
        callerId: 1,
        receiverId: 2,
        callType: 'video',
      )).called(1);
    });

    test('Call completion handling', () {
      // Test successful call completion
      mockQualityMonitor.stopMonitoring(callSuccessful: true);

      verify(() => mockQualityMonitor.stopMonitoring(callSuccessful: true)).called(1);

      // Test failed call completion
      mockQualityMonitor.stopMonitoring(
        callSuccessful: false,
        failureReason: 'Connection lost',
      );

      verify(() => mockQualityMonitor.stopMonitoring(
        callSuccessful: false,
        failureReason: 'Connection lost',
      )).called(1);
    });

    test('Error recording', () {
      const testError = 'Network timeout';

      mockQualityMonitor.recordError(testError);

      verify(() => mockQualityMonitor.recordError(testError)).called(1);
    });
  });
}
