import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/widgets/optimized_image.dart';
import 'package:lgbtindernew/features/auth/data/models/login_response.dart';
import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/call_history_avatar.dart';
import 'package:lgbtindernew/features/calls/presentation/widgets/messenger_call_row.dart';
import 'package:lgbtindernew/features/calls/utils/messenger_call_groups.dart';

Call _endedCall() {
  return Call(
    id: 1,
    callId: '1',
    callerId: 1,
    receiverId: 20,
    receiver: UserData(
      id: 20,
      firstName: 'Alex',
      lastName: 'N',
      email: 'alex@test.com',
    ),
    callType: 'audio',
    status: 'ended',
    startedAt: DateTime(2026, 9, 12, 16),
  );
}

void main() {
  testWidgets('messenger call row uses thumbnail avatar decode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MessengerCallRow(
              group: MessengerCallGroup(
                peerId: 20,
                peerName: 'Alex N',
                peerAvatarUrl: 'https://cdn.example/avatar.jpg',
                latest: _endedCall(),
                count: 1,
                missedCount: 0,
              ),
              currentUserId: 1,
              onOpenHistory: () {},
              onCallAgain: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Alex N'), findsOneWidget);
    expect(find.byType(CallHistoryAvatar), findsOneWidget);
    final image = tester.widget<OptimizedImage>(find.byType(OptimizedImage));
    expect(image.size, ImageSize.thumbnail);
    expect(image.width, 52);
    expect(image.height, 52);
  });
}
