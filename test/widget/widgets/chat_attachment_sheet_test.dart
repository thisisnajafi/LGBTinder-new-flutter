import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/widgets/chat/chat_attachment_sheet.dart';

void main() {
  test('attach grid uses 50ms stagger, 20px radius, 44px cells', () {
    expect(AppAnimations.chatAttachGridStagger, const Duration(milliseconds: 50));
    expect(AppAnimations.chatAttachGridCell, const Duration(milliseconds: 220));
    expect(ChatAttachmentSheet.topRadius, 20);
    expect(ChatAttachmentSheet.minCell, 44);
    expect(ChatAttachmentSheet.columns, 3);
  });

  Widget host({
    required List<ChatAttachmentAction> actions,
    bool reduceMotion = false,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: reduceMotion
          ? (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              );
            }
          : null,
      home: Scaffold(
        body: ChatAttachmentSheetBody(actions: actions),
      ),
    );
  }

  List<ChatAttachmentAction> sixActions({VoidCallback? onCamera}) {
    return [
      ChatAttachmentAction(
        id: 'camera',
        label: 'Camera',
        iconPath: AppIcons.document,
        onTap: onCamera ?? () {},
      ),
      ChatAttachmentAction(
        id: 'gallery',
        label: 'Gallery',
        iconPath: AppIcons.document,
        onTap: () {},
      ),
      ChatAttachmentAction(
        id: 'voice',
        label: 'Voice',
        iconPath: AppIcons.microphone,
        onTap: () {},
      ),
      ChatAttachmentAction(
        id: 'file',
        label: 'File',
        iconPath: AppIcons.document,
        onTap: () {},
      ),
      ChatAttachmentAction(
        id: 'profile',
        label: 'Profile',
        iconPath: AppIcons.document,
        onTap: () {},
      ),
      ChatAttachmentAction(
        id: 'self-destruct',
        label: 'Self-Destruct',
        iconPath: AppIcons.flame,
        onTap: () {},
      ),
    ];
  }

  testWidgets('sheet shows six SVG cells and no stickers', (tester) async {
    await tester.pumpWidget(host(actions: sixActions()));
    await tester.pumpAndSettle();

    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Self-Destruct'), findsOneWidget);
    expect(find.text('Stickers'), findsNothing);
    expect(find.byType(AppSvgIcon), findsNWidgets(6));
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(find.byIcon(Icons.insert_drive_file), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
  });

  testWidgets('sheet uses surface and 20px top radius', (tester) async {
    await tester.pumpWidget(host(actions: sixActions()));
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(ChatAttachmentSheetBody),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppTheme.lightTheme.colorScheme.surface);
    expect(
      material.borderRadius,
      const BorderRadius.vertical(
        top: Radius.circular(ChatAttachmentSheet.topRadius),
      ),
    );
  });

  testWidgets('each cell is at least 44px', (tester) async {
    await tester.pumpWidget(host(actions: sixActions()));
    await tester.pumpAndSettle();

    final boxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    final cells = boxes.where(
      (box) =>
          box.constraints.minWidth == ChatAttachmentSheet.minCell &&
          box.constraints.minHeight == ChatAttachmentSheet.minCell,
    );
    expect(cells.length, 6);
  });

  testWidgets('Reduce Motion skips cell stagger', (tester) async {
    Duration? duration;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Builder(
              builder: (inner) {
                duration = AppAnimations.chatAttachGridDuration(inner);
                return child!;
              },
            ),
          );
        },
        home: Scaffold(
          body: ChatAttachmentSheetBody(actions: sixActions()),
        ),
      ),
    );
    await tester.pump();

    expect(duration, Duration.zero);
    expect(
      find.descendant(
        of: find.byType(ChatAttachmentSheetBody),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ChatAttachmentSheetBody),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('cell tap runs after the sheet frame', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(actions: sixActions(onCamera: () => tapped = true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    expect(tapped, isFalse);
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('ChatAttachmentSheet.show hosts the six labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  ChatAttachmentSheet.show(
                    context: context,
                    onCamera: () {},
                    onGallery: () {},
                    onVoice: () {},
                    onFile: () {},
                    onProfile: () {},
                    onSelfDestruct: () {},
                  );
                },
                child: const Text('open-attach'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open-attach'));
    await tester.pumpAndSettle();

    expect(find.text('Attach'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Self-Destruct'), findsOneWidget);
    expect(find.text('Stickers'), findsNothing);
  });
}
