import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/screens/legal/legal_document_view.dart';

void main() {
  testWidgets('legal document paints selectable section copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LegalDocumentView(
            lastUpdated: 'December 2024',
            sections: [
              LegalDocumentSection(
                title: '1. Acceptance of Terms',
                body: 'By accessing and using LGBTFinder, you accept.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('December 2024'), findsOneWidget);
    expect(find.textContaining('Acceptance of Terms'), findsOneWidget);
    expect(find.byType(SelectableText), findsNWidgets(2));
  });
}
