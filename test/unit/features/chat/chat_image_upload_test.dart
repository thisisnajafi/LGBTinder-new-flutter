import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message_delivery_status.dart';
import 'package:lgbtindernew/features/chat/providers/chat_image_upload_progress_provider.dart';
import 'package:lgbtindernew/features/chat/utils/chat_local_media.dart';
import 'package:lgbtindernew/features/chat/utils/chat_message_preview.dart';
import 'package:lgbtindernew/widgets/chat/chat_image_send_overlay.dart';
import 'package:lgbtindernew/widgets/chat/message_bubble.dart';

void main() {
  test('local path detection covers file URIs and filesystem paths', () {
    expect(ChatLocalMedia.isLocalPath('/tmp/a.jpg'), isTrue);
    expect(ChatLocalMedia.isLocalPath(r'C:\tmp\a.jpg'), isTrue);
    expect(ChatLocalMedia.isLocalPath('file:///tmp/a.jpg'), isTrue);
    expect(ChatLocalMedia.isLocalPath('https://cdn.example/a.jpg'), isFalse);
    expect(
      ChatLocalMedia.toFilePath('file:///tmp/a.jpg'),
      Uri.parse('file:///tmp/a.jpg').toFilePath(),
    );
  });

  test('list preview for an incoming image is Photo', () {
    expect(chatMessagePreviewText(messageType: 'image'), 'Photo');
  });

  test('upload progress throttles tiny deltas then reaches 1.0', () {
    final notifier = ChatImageUploadProgressNotifier();
    notifier.setProgress('c1', 0.10);
    notifier.setProgress('c1', 0.11);
    expect(notifier.state['c1'], 0.10);
    notifier.setProgress('c1', 0.20);
    expect(notifier.state['c1'], 0.20);
    notifier.setProgress('c1', 1);
    expect(notifier.state['c1'], 1.0);
  });

  testWidgets('sending image bubble shows percent overlay', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(chatImageUploadProgressProvider.notifier).setProgress(
          'c1',
          0.42,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: MessageBubble(
                    message: '',
                    isSent: true,
                    messageType: 'image',
                    mediaUrl: '/tmp/missing-photo.jpg',
                    clientId: 'c1',
                    deliveryStatus: MessageDeliveryStatus.sending,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('42%'), findsOneWidget);
  });

  testWidgets('failed image bubble shows retry overlay, not the percent',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: MessageBubble(
                    message: '',
                    isSent: true,
                    messageType: 'image',
                    mediaUrl: '/tmp/missing-photo.jpg',
                    clientId: 'c1',
                    deliveryStatus: MessageDeliveryStatus.failed,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('0%'), findsNothing);
    expect(find.byType(ChatImageSendOverlay), findsOneWidget);
    expect(find.bySemanticsLabel('Retry sending photo'), findsOneWidget);
  });

  testWidgets('failed overlay tap retries send', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: ChatImageSendOverlay(
                    isFailed: true,
                    onRetry: () => retried = true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Retry sending photo'));
    expect(retried, isTrue);
  });
}
