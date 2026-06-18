import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/widgets/app_action_bottom_sheet.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../features/payments/data/models/plan_limits.dart';

/// Result from the super like message bottom sheet.
class SuperlikeSheetResult {
  final String? message;
  final bool openPurchase;

  const SuperlikeSheetResult({
    this.message,
    this.openPurchase = false,
  });
}

/// Modal bottom sheet for sending a super like with a required message.
Future<SuperlikeSheetResult?> showSuperlikeMessageSheet(
  BuildContext context, {
  required SuperlikeInfo superlikeInfo,
}) {
  final pageMessenger = ScaffoldMessenger.maybeOf(context);

  return showModalBottomSheet<SuperlikeSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (sheetContext) => AppBottomSheetShell(
      showCancel: false,
      body: _SuperlikeMessageSheetBody(
        superlikeInfo: superlikeInfo,
      ),
    ),
  ).whenComplete(() {
    pageMessenger?.clearSnackBars();
  });
}

class _SuperlikeMessageSheetBody extends StatefulWidget {
  const _SuperlikeMessageSheetBody({required this.superlikeInfo});

  final SuperlikeInfo superlikeInfo;

  @override
  State<_SuperlikeMessageSheetBody> createState() =>
      _SuperlikeMessageSheetBodyState();
}

class _SuperlikeMessageSheetBodyState extends State<_SuperlikeMessageSheetBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final canSuperlike = widget.superlikeInfo.canSuperlike;
    final message = _controller.text.trim();
    final canSend = canSuperlike && message.isNotEmpty;

    return AppBottomSheetCard(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.spacingLG,
          AppSpacing.spacingMD,
          AppSpacing.spacingLG,
          AppSpacing.spacingLG,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.warningYellow.withOpacity(0.25),
                        AppColors.lgbtGradient[1].withOpacity(0.2),
                        AppColors.accentPurple.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                    border: Border.all(
                      color: AppColors.warningYellow.withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.warningYellow,
                              AppColors.lgbtGradient[1],
                            ],
                          ),
                        ),
                        child: const Center(
                          child: AppSvgIcon(
                            assetPath: AppIcons.star,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Super Like',
                              style: AppTypography.h3.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: AppSpacing.spacingXS),
                            Text(
                              canSuperlike
                                  ? widget.superlikeInfo.remainingLabel
                                  : 'No Super Likes remaining',
                              style: AppTypography.bodySmall.copyWith(
                                color: canSuperlike
                                    ? AppColors.warningYellow
                                    : AppColors.feedbackError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (canSuperlike) ...[
                              SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                'Stand out with a personal note',
                                style: AppTypography.bodySmall.copyWith(
                                  color: textSecondary,
                                ),
                              ),
                            ] else ...[
                              SizedBox(height: AppSpacing.spacingXS),
                              Text(
                                'Purchase extra Super Likes or wait for your daily reset.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingLG),
                TextField(
                  controller: _controller,
                  enabled: canSuperlike,
                  maxLines: 4,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.body.copyWith(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: canSuperlike
                        ? 'Say something memorable…'
                        : 'Add Super Likes to send a message',
                    hintStyle: AppTypography.body.copyWith(
                      color: textSecondary,
                    ),
                    counterStyle: AppTypography.caption.copyWith(
                      color: textSecondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.borderMediumDark
                            : AppColors.borderMediumLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.borderMediumDark
                            : AppColors.borderMediumLight,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.borderMediumDark.withOpacity(0.5)
                            : AppColors.borderMediumLight.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: const BorderSide(
                        color: AppColors.warningYellow,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: AppSpacing.spacingLG),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacingMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusMD,
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTypography.button.copyWith(
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      flex: 2,
                      child: canSuperlike
                          ? ElevatedButton(
                              onPressed: canSend
                                  ? () {
                                      Navigator.pop(
                                        context,
                                        SuperlikeSheetResult(
                                          message: _controller.text.trim(),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.spacingMD,
                                ),
                                backgroundColor: AppColors.warningYellow,
                                foregroundColor: Colors.black87,
                                disabledBackgroundColor:
                                    AppColors.warningYellow.withOpacity(0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.radiusMD,
                                  ),
                                ),
                                elevation: canSend ? 4 : 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppSvgIcon(
                                    assetPath: AppIcons.star,
                                    size: 18,
                                    color: Colors.black87,
                                  ),
                                  SizedBox(width: AppSpacing.spacingSM),
                                  Text(
                                    'Send',
                                    style: AppTypography.button.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  const SuperlikeSheetResult(
                                    openPurchase: true,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.spacingMD,
                                ),
                                backgroundColor: AppColors.accentPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.radiusMD,
                                  ),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const AppSvgIcon(
                                    assetPath: AppIcons.star,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: AppSpacing.spacingSM),
                                  Flexible(
                                    child: Text(
                                      'Purchase Super Likes',
                                      style: AppTypography.button.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}
