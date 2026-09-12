import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/app_icons.dart';
import 'package:lgbtindernew/features/chat/utils/self_destruct_send.dart';

void main() {
  test('duration pills are 5 / 10 / 30 / 60 seconds', () {
    expect(SelfDestructSend.durationOptionsSeconds, [5, 10, 30, 60]);
  });

  test('API message type is disappearing_image', () {
    expect(SelfDestructSend.messageType, 'disappearing_image');
  });

  test('sender copy is waiting or opened, never the photo caption', () {
    expect(
      SelfDestructSend.senderLabel(openedByPeer: false),
      'Waiting to be opened',
    );
    expect(SelfDestructSend.senderLabel(openedByPeer: true), 'Opened');
  });

  test('unopened sender shows expires_in_seconds, not remaining', () {
    expect(
      SelfDestructSend.displayDurationSeconds(
        isSent: true,
        openedByPeer: false,
        expiresInSeconds: 10,
        remainingSeconds: 3,
      ),
      10,
    );
  });

  test('receiver unopened hides duration until they open', () {
    expect(
      SelfDestructSend.displayDurationSeconds(
        isSent: false,
        openedByPeer: false,
        expiresInSeconds: 10,
        remainingSeconds: 10,
      ),
      isNull,
    );
  });

  test('receiver unopened copy includes tap hint and duration', () {
    expect(
      SelfDestructSend.receiverUnopenedLabel(10),
      'Photo • Tap to view • disappears in 10s',
    );
    expect(
      SelfDestructSend.receiverUnopenedLabel(null),
      'Photo • Tap to view',
    );
  });

  test('expired copy distinguishes viewed vs never viewed', () {
    expect(
      SelfDestructSend.expiredLabel(viewed: true),
      'Photo expired',
    );
    expect(
      SelfDestructSend.expiredLabel(viewed: false),
      'Photo no longer available',
    );
  });

  test('receiver preview duration prefers expires_in_seconds', () {
    expect(
      SelfDestructSend.receiverPreviewDurationSeconds(
        expiresInSeconds: 30,
        remainingSeconds: 5,
      ),
      30,
    );
  });

  test('outline and bold flame SVGs share the same glyph family', () {
    expect(AppIcons.flame, 'assets/icons/outline/flame.svg');
    expect(AppIcons.flameBold, 'assets/icons/bold/flame.svg');
  });
}
