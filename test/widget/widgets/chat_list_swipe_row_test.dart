import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/widgets/chat/chat_list_swipe_row.dart';

void main() {
  test('delete undo window is 5 seconds', () {
    expect(AppAnimations.chatListDeleteUndo, const Duration(seconds: 5));
  });

  Widget host({
    required bool muted,
    bool pinned = false,
    required Future<void> Function() onMute,
    required Future<void> Function() onPin,
    required Future<bool> Function() onConfirm,
    required VoidCallback onDeleted,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: ChatListSwipeRow(
            userId: 9,
            isMuted: muted,
            isPinned: pinned,
            onMuteToggle: onMute,
            onPinToggle: onPin,
            onConfirmDelete: onConfirm,
            onDeleted: onDeleted,
            child: const SizedBox(
              height: 72,
              width: 400,
              child: Text('Alex'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('swipe right then Mute keeps the row', (tester) async {
    var muted = 0;
    var pinned = 0;
    var deleted = 0;

    await tester.pumpWidget(
      host(
        muted: false,
        onMute: () async {
          muted++;
        },
        onPin: () async {
          pinned++;
        },
        onConfirm: () async => false,
        onDeleted: () => deleted++,
      ),
    );

    await tester.drag(find.text('Alex'), const Offset(160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChatListSwipeRow.muteActionKey));
    await tester.pumpAndSettle();

    expect(muted, 1);
    expect(pinned, 0);
    expect(deleted, 0);
    expect(find.text('Alex'), findsOneWidget);
  });

  testWidgets('swipe right then Pin keeps the row', (tester) async {
    var muted = 0;
    var pinned = 0;
    var deleted = 0;

    await tester.pumpWidget(
      host(
        muted: false,
        onMute: () async {
          muted++;
        },
        onPin: () async {
          pinned++;
        },
        onConfirm: () async => false,
        onDeleted: () => deleted++,
      ),
    );

    await tester.drag(find.text('Alex'), const Offset(160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChatListSwipeRow.pinActionKey));
    await tester.pumpAndSettle();

    expect(muted, 0);
    expect(pinned, 1);
    expect(deleted, 0);
    expect(find.text('Alex'), findsOneWidget);
  });

  testWidgets('swipe left deletes after confirm', (tester) async {
    var muted = 0;
    var pinned = 0;
    var deleted = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              if (deleted > 0) return const SizedBox.shrink();
              return SizedBox(
                width: 400,
                child: ChatListSwipeRow(
                  userId: 9,
                  isMuted: true,
                  isPinned: false,
                  onMuteToggle: () async {
                    muted++;
                  },
                  onPinToggle: () async {
                    pinned++;
                  },
                  onConfirmDelete: () async => true,
                  onDeleted: () => setState(() => deleted++),
                  child: const SizedBox(
                    height: 72,
                    width: 400,
                    child: Text('Alex'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.drag(find.text('Alex'), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(muted, 0);
    expect(pinned, 0);
    expect(deleted, 1);
    expect(find.text('Alex'), findsNothing);
  });
}
