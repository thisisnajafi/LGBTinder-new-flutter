import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_gallery_items.dart';
import 'package:lgbtindernew/features/chat/utils/chat_image_saver.dart';
import 'package:lgbtindernew/widgets/chat/chat_image_viewer.dart';

void main() {
  test('gallery items skip locked, expired, and non-image rows', () {
    final items = ChatGalleryItems.fromMaps([
      {'kind': 'date_badge', 'type': 'image', 'attachment_url': 'https://x/a.jpg'},
      {'kind': 'call', 'type': 'image', 'attachment_url': 'https://x/b.jpg'},
      {'kind': 'unread_separator', 'type': 'image', 'attachment_url': 'https://x/c.jpg'},
      {
        'id': 1,
        'type': 'image',
        'attachment_url': 'https://cdn.example/one.jpg',
        'hero_tag': 'chat_image_1',
      },
      {
        'id': 2,
        'type': 'image',
        'is_locked': true,
        'attachment_url': 'https://cdn.example/locked.jpg',
      },
      {
        'id': 3,
        'type': 'disappearing_image',
        'attachment_url': 'https://cdn.example/sd.jpg',
      },
      {
        'id': 4,
        'type': 'image',
        'is_expired': true,
        'attachment_url': 'https://cdn.example/expired.jpg',
      },
      {
        'id': 5,
        'client_id': 'c5',
        'type': 'image',
        'attachment_url': 'https://cdn.example/two.jpg',
      },
    ]);

    expect(items.map((item) => item.messageId), [1, 5]);
    expect(items.first.heroTag, 'chat_image_1');
    expect(items.last.heroTag, 'chat_image_5');
    expect(
      ChatGalleryItems.indexFor(items, {'client_id': 'c5', 'id': 5}),
      1,
    );
    expect(ChatGalleryItem.heroTagFor(messageId: 9), 'chat_image_9');
    expect(
      ChatGalleryItem.heroTagFor(clientId: 'pending-1'),
      'chat_image_pending-1',
    );
  });

  test('same media URL still gets unique hero tags per message', () {
    final items = ChatGalleryItems.fromMaps([
      {
        'id': 11,
        'type': 'image',
        'attachment_url': 'https://cdn.example/same.jpg',
      },
      {
        'id': 12,
        'client_id': 'c12',
        'type': 'image',
        'attachment_url': 'https://cdn.example/same.jpg',
      },
      {
        'id': 0,
        'client_id': 'local-a',
        'type': 'image',
        'attachment_url': 'https://cdn.example/same.jpg',
      },
    ]);

    expect(items.map((item) => item.heroTag).toSet().length, 3);
    expect(items.map((item) => item.heroTag), [
      'chat_image_11',
      'chat_image_12',
      'chat_image_local-a',
    ]);
  });

  test('pinch range is 0.5–5×', () {
    expect(ChatImageViewer.minScale, 0.5);
    expect(ChatImageViewer.maxScale, 5);
  });

  testWidgets('album swipe, download, close, and swipe-down dismiss',
      (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                ChatImageViewer.open(
                  context,
                  imageUrl: '/tmp/one.jpg',
                  heroTag: 'chat_image_1',
                  images: const [
                    ChatGalleryItem(
                      url: '/tmp/one.jpg',
                      heroTag: 'chat_image_1',
                      messageId: 1,
                    ),
                    ChatGalleryItem(
                      url: '/tmp/two.jpg',
                      heroTag: 'chat_image_2',
                      messageId: 2,
                    ),
                  ],
                  saveHandler: (url) async {
                    saved = url;
                    return const ChatImageSaveResult(saved: true);
                  },
                  chromeHideAfter: Duration.zero,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsWidgets);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(Hero), findsWidgets);
    expect(
      tester
          .widgetList<Hero>(find.byType(Hero))
          .map((hero) => hero.tag)
          .toSet(),
      {'chat_image_1'},
    );
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('chat-image-viewer-barrier')),
          )
          .color,
      Colors.black,
    );

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(
      tester
          .widgetList<Hero>(find.byType(Hero))
          .map((hero) => hero.tag)
          .toSet(),
      {'chat_image_2'},
    );

    await tester.tap(find.bySemanticsLabel('Save photo to gallery'));
    await tester.pump();
    expect(saved, '/tmp/two.jpg');
    expect(find.text('Saved to gallery'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close photo'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
}
