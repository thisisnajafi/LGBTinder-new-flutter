import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/utils/chat_upload_validation.dart';

void main() {
  group('ChatUploadValidation', () {
    test('matches backend default byte caps', () {
      expect(ChatUploadValidation.maxVideoBytes, 52428800);
      expect(ChatUploadValidation.maxVoiceBytes, 5242880);
      expect(ChatUploadValidation.maxImageBytes, 5242880);
    });

    test('accepts allowed video types under 50 MB', () {
      expect(
        ChatUploadValidation.validateVideo(
          fileName: 'clip.MP4',
          fileSizeBytes: 10 * 1024 * 1024,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateVideo(
          fileName: 'clip.mov',
          fileSizeBytes: ChatUploadValidation.maxVideoBytes,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateVideo(
          fileName: 'clip.webm',
          fileSizeBytes: 1,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateVideo(
          fileName: 'clip.3gp',
          fileSizeBytes: 1,
        ),
        isNull,
      );
    });

    test('rejects oversized or wrong video types with friendly errors', () {
      expect(
        ChatUploadValidation.validateVideo(
          fileName: 'clip.avi',
          fileSizeBytes: 1000,
        ),
        'Videos must be MP4, MOV, WebM, or 3GP.',
      );
      expect(
        ChatUploadValidation.validateVideo(
          fileName: 'clip.mp4',
          fileSizeBytes: ChatUploadValidation.maxVideoBytes + 1,
        ),
        'Video is too large. Maximum size is 50 MB.',
      );
    });

    test('accepts voice m4a/aac/mp3 under 5 MB and rejects others', () {
      expect(
        ChatUploadValidation.validateVoice(
          fileName: 'note.m4a',
          fileSizeBytes: ChatUploadValidation.maxVoiceBytes,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateVoice(
          fileName: 'note.aac',
          fileSizeBytes: 100,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateVoice(
          fileName: 'note.mp3',
          fileSizeBytes: 100,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateVoice(
          fileName: 'note.wav',
          fileSizeBytes: 100,
        ),
        'Voice notes must be M4A, AAC, or MP3.',
      );
      expect(
        ChatUploadValidation.validateVoice(
          fileName: 'note.m4a',
          fileSizeBytes: ChatUploadValidation.maxVoiceBytes + 1,
        ),
        'Voice note is too large. Maximum size is 5 MB.',
      );
    });

    test('accepts images under 5 MB and rejects oversized', () {
      expect(
        ChatUploadValidation.validateImage(
          fileName: 'photo.jpg',
          fileSizeBytes: ChatUploadValidation.maxImageBytes,
        ),
        isNull,
      );
      expect(
        ChatUploadValidation.validateImage(
          fileName: 'photo.png',
          fileSizeBytes: ChatUploadValidation.maxImageBytes + 1,
        ),
        'Image is too large. Maximum size is 5 MB.',
      );
      expect(
        ChatUploadValidation.validateImage(
          fileName: 'doc.pdf',
          fileSizeBytes: 100,
        ),
        'Only image files are allowed.',
      );
    });

    test('text and sticker never allow attachments; documents unsupported', () {
      expect(ChatUploadValidation.allowsAttachment('text'), isFalse);
      expect(ChatUploadValidation.allowsAttachment('sticker'), isFalse);
      expect(ChatUploadValidation.allowsAttachment('image'), isTrue);
      expect(ChatUploadValidation.allowsAttachment('video'), isTrue);
      expect(ChatUploadValidation.allowsAttachment('voice'), isTrue);
      expect(ChatUploadValidation.messageTypeForUpload('resume.pdf'), isNull);
    });

    test('messageTypeForUpload maps allowlisted names only', () {
      expect(ChatUploadValidation.messageTypeForUpload('a.mp4'), 'video');
      expect(ChatUploadValidation.messageTypeForUpload('a.m4a'), 'voice');
      expect(ChatUploadValidation.messageTypeForUpload('a.jpg'), 'image');
      expect(ChatUploadValidation.messageTypeForUpload('a.avi'), isNull);
      expect(ChatUploadValidation.messageTypeForUpload('a.wav'), isNull);
      expect(ChatUploadValidation.messageTypeForUpload('a.pdf'), isNull);
    });
  });
}
