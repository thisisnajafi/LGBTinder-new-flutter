import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';
import 'package:lgbtindernew/screens/discovery/likes_received_screen.dart';

void main() {
  testWidgets('like card uses thumbnail OptimizedImage', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LikesReceivedCard(
              like: {
                'name': 'Sam',
                'age': 28,
                'avatar_url': 'https://example.com/sam.jpg',
                'is_verified': false,
                'is_premium': false,
                'liked_at': DateTime.now(),
                'bio': 'Hello',
                'user_id': 2,
                'id': 1,
              },
              formatTime: (_) => 'Just now',
              onProfileTap: () {},
              onPass: () {},
              onAccept: () {},
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<OptimizedImage>(find.byType(OptimizedImage));
    expect(image.size, ImageSize.thumbnail);
    expect(image.width, 56);
    expect(image.height, 56);
    expect(find.text('Sam, 28'), findsOneWidget);
  });
}
