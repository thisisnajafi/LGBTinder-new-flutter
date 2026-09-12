import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';

/// One cell in the Telegram-style attach grid (CHAT-INPUT-002).
class ChatAttachmentAction {
  final String id;
  final String label;
  final String iconPath;
  final Color? iconColor;
  final VoidCallback onTap;

  const ChatAttachmentAction({
    required this.id,
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.iconColor,
  });
}

/// Six-cell attachment sheet: Camera, Gallery, Voice, File, Profile, Self-Destruct.
class ChatAttachmentSheet {
  ChatAttachmentSheet._();

  static const double topRadius = 20;
  static const double minCell = 44;
  static const int columns = 3;

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onVoice,
    required VoidCallback onFile,
    required VoidCallback onProfile,
    required VoidCallback onSelfDestruct,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ChatAttachmentSheetBody(
          actions: [
            ChatAttachmentAction(
              id: 'camera',
              label: 'Camera',
              iconPath: AppIcons.camera,
              iconColor: theme.colorScheme.primary,
              onTap: onCamera,
            ),
            ChatAttachmentAction(
              id: 'gallery',
              label: 'Gallery',
              iconPath: AppIcons.gallery,
              iconColor: theme.colorScheme.secondary,
              onTap: onGallery,
            ),
            ChatAttachmentAction(
              id: 'voice',
              label: 'Voice',
              iconPath: AppIcons.microphone,
              iconColor: theme.colorScheme.primary,
              onTap: onVoice,
            ),
            ChatAttachmentAction(
              id: 'file',
              label: 'File',
              iconPath: AppIcons.document,
              iconColor: theme.colorScheme.primary,
              onTap: onFile,
            ),
            ChatAttachmentAction(
              id: 'profile',
              label: 'Profile',
              iconPath: AppIcons.user,
              iconColor: theme.colorScheme.primary,
              onTap: onProfile,
            ),
            ChatAttachmentAction(
              id: 'self-destruct',
              label: 'Self-Destruct',
              iconPath: AppIcons.flame,
              iconColor: theme.colorScheme.error,
              onTap: onSelfDestruct,
            ),
          ],
        );
      },
    );
  }
}

/// Visible attach-grid body (tests host this without a modal).
class ChatAttachmentSheetBody extends StatefulWidget {
  final List<ChatAttachmentAction> actions;

  const ChatAttachmentSheetBody({
    super.key,
    required this.actions,
  });

  @override
  State<ChatAttachmentSheetBody> createState() =>
      _ChatAttachmentSheetBodyState();
}

class _ChatAttachmentSheetBodyState extends State<ChatAttachmentSheetBody>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  bool _started = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = !AppAnimations.animationsEnabled(context);
    if (_reduced) return;
    final last = widget.actions.isEmpty ? 0 : widget.actions.length - 1;
    final total = AppAnimations.chatAttachGridStagger * last +
        AppAnimations.chatAttachGridCell;
    _controller = AnimationController(vsync: this, duration: total)..forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(ChatAttachmentSheet.topRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spacingLG,
            AppSpacing.spacingSM,
            AppSpacing.spacingLG,
            AppSpacing.spacingLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              AppText(
                'Attach',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              GridView.builder(
                key: const ValueKey('chat-attach-grid'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ChatAttachmentSheet.columns,
                  mainAxisSpacing: AppSpacing.spacingMD,
                  crossAxisSpacing: AppSpacing.spacingMD,
                  mainAxisExtent: 96,
                ),
                itemBuilder: (context, index) =>
                    _cell(index, widget.actions[index], theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(int index, ChatAttachmentAction action, ThemeData theme) {
    final iconColor = action.iconColor ?? theme.colorScheme.primary;
    final tile = Semantics(
      button: true,
      label: action.label,
      child: InkWell(
        onTap: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            action.onTap();
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.spacingMD),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ChatAttachmentSheet.minCell,
            minHeight: ChatAttachmentSheet.minCell,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: AppSvgIcon(
                  assetPath: action.iconPath,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              AppText(
                action.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final controller = _controller;
    if (_reduced || controller == null) return tile;

    final totalMs = controller.duration?.inMilliseconds ?? 1;
    final start =
        (AppAnimations.chatAttachGridStagger.inMilliseconds * index) / totalMs;
    final end = ((AppAnimations.chatAttachGridStagger.inMilliseconds * index) +
            AppAnimations.chatAttachGridCell.inMilliseconds) /
        totalMs;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: AppAnimations.curveDefault,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: tile,
      ),
    );
  }
}
