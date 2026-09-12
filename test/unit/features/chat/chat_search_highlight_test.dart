import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/features/chat/utils/chat_search_highlight.dart';

void main() {
  test('matching substring uses the highlight color', () {
    final spans = ChatSearchHighlight.spans(
      text: 'Alex Rivera',
      query: 'LEX',
      style: const TextStyle(color: Color(0xFF111111)),
      highlightColor: AppTheme.lightTheme.colorScheme.primary,
    );

    expect(spans, hasLength(3));
    expect((spans[0] as TextSpan).text, 'A');
    expect((spans[1] as TextSpan).text, 'lex');
    expect(
      (spans[1] as TextSpan).style?.color,
      AppTheme.lightTheme.colorScheme.primary,
    );
    expect((spans[2] as TextSpan).text, ' Rivera');
  });

  test('empty query leaves the string unhighlighted', () {
    final spans = ChatSearchHighlight.spans(
      text: 'Alex',
      query: '  ',
      style: const TextStyle(),
      highlightColor: AppTheme.lightTheme.colorScheme.primary,
    );
    expect(spans, hasLength(1));
    expect((spans.single as TextSpan).text, 'Alex');
  });
}
