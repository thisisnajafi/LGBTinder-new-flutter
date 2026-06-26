import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';

/// Premium empty state for a conversation with no messages yet.
class ChatEmptyConversation extends StatelessWidget {
  const ChatEmptyConversation({
    super.key,
    this.peerName,
  });

  final String? peerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = peerName != null && peerName!.trim().isNotEmpty
        ? 'Say hi to ${peerName!.trim()}'
        : 'Start the conversation';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumPageHeader.horizontalPadding,
        ),
        child: PremiumShell(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentViolet.withValues(alpha: 0.16),
                      AppColors.accentRose.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.message,
                    size: 32,
                    color: AppColors.accentViolet,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              Text(
                'No messages yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              Text(
                greeting,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
