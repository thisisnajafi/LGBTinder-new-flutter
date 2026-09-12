import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/providers/chat_link_preview_provider.dart';
import '../../features/chat/utils/chat_link_detector.dart';
import '../../core/widgets/optimized_image.dart';
import 'chat_linked_text.dart';

/// Compact OG card under a text bubble (CHAT-UX-004 / CHAT-BE-003).
class ChatLinkPreviewCard extends ConsumerWidget {
  final String url;
  final bool isSent;
  final ChatOgPreview? preview;

  const ChatLinkPreviewCard({
    super.key,
    required this.url,
    this.isSent = false,
    this.preview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ChatLinkPreview.enabled) return const SizedBox.shrink();
    if (preview != null) {
      return preview!.hasContent
          ? _Card(preview: preview!, isSent: isSent)
          : const SizedBox.shrink();
    }
    final async = ref.watch(chatLinkPreviewProvider(url));
    return async.maybeWhen(
      data: (data) {
        if (data == null || !data.hasContent) {
          return const SizedBox.shrink();
        }
        return _Card(preview: data, isSent: isSent);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Card extends StatelessWidget {
  final ChatOgPreview preview;
  final bool isSent;

  const _Card({required this.preview, required this.isSent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onBubble = isSent
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final muted = isSent
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final fill = isSent
        ? Colors.white.withValues(alpha: 0.14)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final border = isSent
        ? Colors.white.withValues(alpha: 0.28)
        : (isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight);
    final host = ChatLinkDetector.toLaunchUri(preview.url)?.host ?? preview.url;
    final title = preview.title ?? host;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacingSM),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ChatLinkOpener.open(preview.url),
          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          child: Ink(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (preview.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.radiusSM),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.9,
                      child: OptimizedImage(
                        imageUrl: preview.imageUrl!,
                        fit: BoxFit.cover,
                        size: ImageSize.small,
                        errorWidget: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacingSM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.link,
                        size: 16,
                        color: muted,
                      ),
                      const SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                color: onBubble,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (preview.description != null) ...[
                              const SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                preview.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
