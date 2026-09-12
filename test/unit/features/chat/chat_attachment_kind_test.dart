import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_attachment_kind.dart';

void main() {
  test('maps photo, video, and audio suffixes to chat types', () {
    expect(
      ChatAttachmentKindResolver.fromName('photo.JPG'),
      ChatAttachmentKind.image,
    );
    expect(
      ChatAttachmentKindResolver.messageType(ChatAttachmentKind.image),
      'image',
    );
    expect(
      ChatAttachmentKindResolver.fromName('clip.mp4'),
      ChatAttachmentKind.video,
    );
    expect(
      ChatAttachmentKindResolver.messageType(ChatAttachmentKind.video),
      'video',
    );
    expect(
      ChatAttachmentKindResolver.fromName('note.m4a'),
      ChatAttachmentKind.audio,
    );
    expect(
      ChatAttachmentKindResolver.messageType(ChatAttachmentKind.audio),
      'voice',
    );
  });

  test('pdf and unknown files are unsupported', () {
    expect(
      ChatAttachmentKindResolver.fromName('resume.pdf'),
      ChatAttachmentKind.unsupported,
    );
    expect(
      ChatAttachmentKindResolver.messageType(ChatAttachmentKind.unsupported),
      isNull,
    );
    expect(
      ChatAttachmentKindResolver.fromName('archive.zip'),
      ChatAttachmentKind.unsupported,
    );
  });
}
