import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/theme/typography.dart';
import 'package:lgbtindernew/features/chat/utils/chat_link_detector.dart';
import 'package:lgbtindernew/widgets/chat/chat_link_preview_card.dart';

void main() {
  test('ChatOgPreview.hasContent requires title or image', () {
    expect(
      const ChatOgPreview(url: 'https://example.com').hasContent,
      isFalse,
    );
    expect(
      const ChatOgPreview(url: 'https://example.com', title: 'Hello').hasContent,
      isTrue,
    );
  });

  testWidgets('renders title and host without Material Icons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChatLinkPreviewCard(
              url: 'https://example.com/post',
              preview: ChatOgPreview(
                url: 'https://example.com/post',
                title: 'Example post',
                description: 'A short summary',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Example post'), findsOneWidget);
    expect(find.text('A short summary'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);

    final title = tester.widget<Text>(find.text('Example post'));
    expect(title.style?.fontSize, AppTypography.body.fontSize);
  });

  testWidgets('hides when preview has no content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ChatLinkPreviewCard(
              url: 'https://example.com',
              preview: ChatOgPreview(url: 'https://example.com'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('example.com'), findsNothing);
  });
}
