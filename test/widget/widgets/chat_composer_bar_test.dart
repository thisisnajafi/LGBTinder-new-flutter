import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/providers/chat_thread_providers.dart';
import 'package:lgbtindernew/widgets/chat/chat_composer_bar.dart';
import 'package:lgbtindernew/widgets/chat/message_input.dart';
import 'package:lgbtindernew/widgets/chat/message_reply_widget.dart';

void main() {
  testWidgets('ChatComposerBar shows reply preview from composer provider',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ChatComposerBar(
              peerUserId: 4,
              onSend: (_) {},
              onMediaTap: () {},
              onMediaLongPress: () {},
              onVoiceRecordStart: () async => true,
              onVoiceRecordSend: () async {},
              onVoiceRecordCancel: () async {},
              onTextChanged: (_) {},
              onFocusChange: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    container.read(chatComposerProvider(4).notifier).beginReply(
          messageId: 9,
          text: 'hello there',
          type: 'text',
          name: 'Sam',
        );
    await tester.pump();

    expect(find.byType(MessageReplyWidget), findsOneWidget);
    expect(find.text('hello there'), findsOneWidget);
    expect(find.byType(MessageInput), findsOneWidget);

    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-reply-cancel')));
    await tester.pump();
    expect(container.read(chatComposerProvider(4)).replyMessageId, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('ChatComposerBar surfaces remaining edit time', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sentAt = DateTime.now().subtract(const Duration(minutes: 5));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ChatComposerBar(
              peerUserId: 4,
              onSend: (_) {},
              onMediaTap: () {},
              onMediaLongPress: () {},
              onVoiceRecordStart: () async => true,
              onVoiceRecordSend: () async {},
              onVoiceRecordCancel: () async {},
              onTextChanged: (_) {},
              onFocusChange: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    container.read(chatComposerProvider(4).notifier).beginEdit(
          messageId: 8,
          preview: 'original text',
          createdAt: sentAt,
        );
    await tester.pump();

    expect(find.textContaining('Editing ·'), findsOneWidget);
    expect(find.text('original text'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-edit-pencil')), findsOneWidget);
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      contains(AppIcons.edit),
    );
    expect(
      tester
          .widgetList<AppSvgIcon>(find.byType(AppSvgIcon))
          .map((icon) => icon.assetPath),
      contains(AppIcons.tickCircle),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      'Edit message...',
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-reply-cancel')));
    await tester.pump();
    expect(container.read(chatComposerProvider(4)).isEditing, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
