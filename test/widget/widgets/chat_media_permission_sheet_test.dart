import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/chat_media_permissions.dart';
import 'package:lgbtindernew/widgets/chat/chat_media_permission_sheet.dart';

void main() {
  testWidgets('denied sheet always offers Open Settings', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ChatMediaPermissionSheet.show(
                    context,
                    kind: ChatMediaPermissionKind.photos,
                    permanentlyDenied: true,
                    onOpenSettings: () async {
                      opened++;
                    },
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Enable photos'), findsOneWidget);
    expect(find.text(ChatMediaPermissionCopy.openSettingsLabel), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(AppSvgIcon), findsWidgets);

    await tester.tap(find.text(ChatMediaPermissionCopy.openSettingsLabel));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });
}
