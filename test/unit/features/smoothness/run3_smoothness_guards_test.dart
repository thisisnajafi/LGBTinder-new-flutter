import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/widgets/cards/swipeable_card.dart';
import 'package:lgbtindernew/widgets/chat/last_seen_widget.dart';

/// Cheap regression guards for run3 smoothness fixes.
void main() {
  test('LastSeenWidget is StatelessWidget (no 1s ticker)', () {
    expect(const LastSeenWidget(), isA<StatelessWidget>());
  });

  test('SwipeableCard exposes carouselEnabled for off-tab pause', () {
    const card = SwipeableCard(userId: 1, name: 'A');
    expect(card.carouselEnabled, isTrue);
    const paused = SwipeableCard(
      userId: 1,
      name: 'A',
      carouselEnabled: false,
    );
    expect(paused.carouselEnabled, isFalse);
  });

  test('likes-received and matches routes use platformPredictivePage', () {
    final routerSource = File('lib/routes/app_router.dart').readAsStringSync();
    expect(
      routerSource.contains(
        "path: 'likes-received'",
      ),
      isTrue,
    );
    expect(
      routerSource.contains(
        "platformPredictivePage(state, const LikesReceivedScreen())",
      ),
      isTrue,
    );
    expect(
      routerSource.contains(
        "platformPredictivePage(state, const MatchesScreen())",
      ),
      isTrue,
    );
    // Ensure we did not leave the expensive slideFade on those high-frequency paths.
    final likesBlock = routerSource.split("path: 'likes-received'")[1]
        .split("path: 'matches'")[0];
    expect(likesBlock.contains('slideFadePage'), isFalse);
  });
}
