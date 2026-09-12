import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../utils/chat_link_detector.dart';
import 'chat_providers.dart';

/// In-memory OG fetch keyed by the launch URL (CHAT-BE-003).
final chatLinkPreviewProvider =
    FutureProvider.autoDispose.family<ChatOgPreview?, String>((ref, url) async {
  if (!ChatLinkPreview.enabled) return null;
  final uri = ChatLinkDetector.toLaunchUri(url);
  if (uri == null) return null;
  try {
    final preview =
        await ref.read(chatServiceProvider).getLinkPreview(uri.toString());
    return preview.hasContent ? preview : null;
  } catch (e) {
    AppLogger.warning(
      'link preview failed',
      tag: 'ChatLink',
      error: e,
    );
    return null;
  }
});
