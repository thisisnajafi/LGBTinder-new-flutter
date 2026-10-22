import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_theme.dart';
import 'package:lgbtindernew/widgets/chat/chat_peer_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('official avatar contains the full logo with padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: ChatPeerAvatar(
              size: 52,
              isOfficial: true,
              imageUrl: 'https://example.com/storage/brand/lgbtfinder-logo.png',
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.image(const AssetImage('assets/images/logo/logo.png')),
    );
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);

    final box = tester.getRect(find.byKey(ChatPeerAvatar.officialLogoKey));
    final painted = tester.getRect(find.byType(Image));
    expect(box.width, 52);
    expect(box.height, 52);
    expect(painted.width, lessThan(box.width * 0.75));
    expect(painted.center.dx, closeTo(box.center.dx, 1));
    expect(painted.center.dy, closeTo(box.center.dy, 1));
    expect(find.bySemanticsLabel('LGBTFinder Team'), findsOneWidget);
  });
}
