import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cache/cache_providers.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../routes/app_router.dart';
import '../../data/models/sticker_pack.dart';
import '../../providers/sticker_providers.dart';

/// Bottom sheet sticker picker with pack tabs, grid, and locked-pack upgrade CTA.
class StickerPickerSheet extends ConsumerStatefulWidget {
  final void Function(StickerItem sticker) onStickerSelected;

  const StickerPickerSheet({
    super.key,
    required this.onStickerSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required void Function(StickerItem sticker) onStickerSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerPickerSheet(onStickerSelected: onStickerSelected),
    );
  }

  @override
  ConsumerState<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends ConsumerState<StickerPickerSheet>
    with SingleTickerProviderStateMixin {
  int _selectedPackIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final disableAnimations = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first)
            .disableAnimations
        : false;

    _slideController = AnimationController(
      duration: disableAnimations
          ? Duration.zero
          : AppAnimations.transitionModal,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppAnimations.curveDefault,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _closeSheet() async {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _slideController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _handleStickerTap(StickerPack pack, StickerItem sticker) {
    widget.onStickerSelected(sticker);
    _closeSheet();
  }

  void _openUpgrade() {
    Navigator.of(context).pop();
    context.push(
      Uri(
        path: AppRoutes.featureLocked,
        queryParameters: const {
          'title': 'Premium stickers',
          'desc': 'Upgrade to silder or golden to unlock exclusive sticker packs.',
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final packsAsync = ref.watch(stickerPacksProvider);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.radiusXL),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingLG,
                  vertical: AppSpacing.spacingMD,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stickers',
                        style: AppTypography.h4.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Close sticker picker',
                      button: true,
                      child: IconButton(
                        onPressed: _closeSheet,
                        icon: AppSvgIcon(
                          assetPath: AppIcons.close,
                          size: 22,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: packsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Could not load stickers',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  data: (packs) {
                    if (packs.isEmpty) {
                      return Center(
                        child: Text(
                          'No sticker packs available',
                          style: AppTypography.body.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }

                    final safeIndex =
                        _selectedPackIndex.clamp(0, packs.length - 1);
                    final selectedPack = packs[safeIndex];

                    return Column(
                      children: [
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingLG,
                            ),
                            itemCount: packs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.spacingSM),
                            itemBuilder: (context, index) {
                              final pack = packs[index];
                              final isSelected = index == safeIndex;
                              return Semantics(
                                label: '${pack.name} sticker pack',
                                selected: isSelected,
                                button: true,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedPackIndex = index),
                                  child: _PackTab(
                                    pack: pack,
                                    isSelected: isSelected,
                                    isDark: isDark,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacingSM),
                        Expanded(
                          child: selectedPack.isUnlocked
                              ? _StickerGrid(
                                  packId: selectedPack.id,
                                  onStickerTap: (sticker) =>
                                      _handleStickerTap(selectedPack, sticker),
                                )
                              : _LockedPackOverlay(
                                  packName: selectedPack.name,
                                  onUpgrade: _openUpgrade,
                                  isDark: isDark,
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackTab extends ConsumerWidget {
  final StickerPack pack;
  final bool isSelected;
  final bool isDark;

  const _PackTab({
    required this.pack,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor = isSelected
        ? AppColors.primaryLight
        : (isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: pack.thumbnailUrl,
              cacheManager: ref.read(imageCacheServiceProvider),
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              ),
              errorWidget: (_, __, ___) => Center(
                child: AppSvgIcon(
                  assetPath: AppIcons.emoji,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            if (!pack.isUnlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.lock,
                    size: 16,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StickerGrid extends ConsumerWidget {
  final int packId;
  final void Function(StickerItem sticker) onStickerTap;

  const _StickerGrid({
    required this.packId,
    required this.onStickerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stickersAsync = ref.watch(stickerPackStickersProvider(packId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return stickersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Could not load stickers',
          style: AppTypography.body.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
      data: (stickers) {
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.spacingLG),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: AppSpacing.spacingMD,
            crossAxisSpacing: AppSpacing.spacingMD,
          ),
          itemCount: stickers.length,
          itemBuilder: (context, index) {
            final sticker = stickers[index];
            return Semantics(
              label: sticker.altText ?? 'Sticker',
              button: true,
              child: GestureDetector(
                onTap: () => onStickerTap(sticker),
                child: CachedNetworkImage(
                  imageUrl: sticker.imageUrl,
                  cacheManager: ref.read(imageCacheServiceProvider),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => ColoredBox(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LockedPackOverlay extends StatelessWidget {
  final String packName;
  final VoidCallback onUpgrade;
  final bool isDark;

  const _LockedPackOverlay({
    required this.packName,
    required this.onUpgrade,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: AppIcons.lockCircle,
              size: 48,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            Text(
              '$packName is premium',
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Upgrade to silder or golden to unlock this sticker pack.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            Semantics(
              label: 'Upgrade to unlock stickers',
              button: true,
              child: FilledButton(
                onPressed: onUpgrade,
                child: const Text('View plans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
