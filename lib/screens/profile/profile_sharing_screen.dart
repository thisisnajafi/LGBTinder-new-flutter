// Screen: ProfileSharingScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../features/profile/utils/profile_qr.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';

/// Profile sharing screen - Share profile functionality
class ProfileSharingScreen extends ConsumerStatefulWidget {
  const ProfileSharingScreen({super.key});

  @override
  ConsumerState<ProfileSharingScreen> createState() =>
      _ProfileSharingScreenState();
}

class _ProfileSharingScreenState extends ConsumerState<ProfileSharingScreen> {
  static const _fallbackShareUrl = 'https://lgbtfinder.com/profile/12345';

  String? _profileShareUrl;
  EncodedProfileQr? _qr;
  bool _isGenerating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generateShareUrl();
    });
  }

  Future<void> _generateShareUrl() async {
    setState(() => _isGenerating = true);
    try {
      const url = _fallbackShareUrl;
      EncodedProfileQr? qr;
      try {
        qr = await encodeProfileQr(url);
      } catch (_) {
        qr = null;
      }
      if (!mounted) return;
      setState(() {
        _profileShareUrl = url;
        _qr = qr;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate share URL: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareProfile() async {
    if (_profileShareUrl == null) return;
    try {
      await Share.share(
        'Check out my LGBTFinder profile!\n$_profileShareUrl',
        subject: 'My LGBTFinder Profile',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _copyLink() async {
    if (_profileShareUrl == null) return;
    await Clipboard.setData(ClipboardData(text: _profileShareUrl!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return AppPageScaffold(
      title: 'Share Profile',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          const SectionHeader(
            title: 'Share Your Profile',
            iconPath: AppIcons.share,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Share your profile link with friends or on social media',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          SectionHeader(
            title: 'Profile Link',
            iconPath: AppIcons.link,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isGenerating)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.spacingLG),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          _profileShareUrl ?? 'Generating...',
                          style: AppTypography.body.copyWith(color: textColor),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: AppSvgIcon(
                          assetPath: AppIcons.copy,
                          size: 22,
                          color: AppColors.accentPurple,
                        ),
                        onPressed: _copyLink,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  GradientButton(
                    text: 'Share Link',
                    onPressed: _shareProfile,
                    isFullWidth: true,
                    iconPath: AppIcons.share,
                  ),
                ],
              ],
            ),
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'QR Code',
            iconPath: AppIcons.share1,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildQrCard(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Share Options',
            iconPath: AppIcons.more,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildShareOption(
            iconPath: AppIcons.message,
            title: 'Share via Message',
            description: 'Send via SMS or messaging apps',
            onTap: _shareProfile,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildShareOption(
            iconPath: AppIcons.email,
            title: 'Share via Email',
            description: 'Send via email',
            onTap: _shareProfile,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.accentPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.infoCircle,
                  size: 20,
                  color: AppColors.accentPurple,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: AppText(
                    'Anyone with this link can view your profile. Make sure you trust the person you\'re sharing with.',
                    style: AppTypography.caption.copyWith(color: textColor),
                    maxLines: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard({
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          if (_qr == null)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  _isGenerating
                      ? 'Generating QR code…'
                      : 'QR code unavailable',
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            RepaintBoundary(
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: EncodedProfileQrPainter(
                    qr: _qr!,
                    foreground: textColor,
                    background: surfaceColor,
                  ),
                ),
              ),
            ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Scan to open this profile',
            style: AppTypography.caption.copyWith(color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required String iconPath,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: iconPath,
                    size: 24,
                    color: AppColors.accentPurple,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    AppText(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              AppSvgIcon(
                assetPath: AppIcons.chevronRight,
                size: 20,
                color: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
