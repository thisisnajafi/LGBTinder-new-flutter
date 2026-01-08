// Screen: ProfileSharingScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Profile sharing screen - Share profile functionality
class ProfileSharingScreen extends ConsumerStatefulWidget {
  const ProfileSharingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSharingScreen> createState() => _ProfileSharingScreenState();
}

class _ProfileSharingScreenState extends ConsumerState<ProfileSharingScreen> {
  String? _profileShareUrl;
  String? _profileQrCode;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateShareUrl();
  }

  Future<void> _generateShareUrl() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // TODO: Generate share URL from API
      // GET /api/profile/share-url
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _profileShareUrl = 'https://lgbtfinder.com/profile/12345';
          _profileQrCode = null; // TODO: Generate QR code
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate share URL: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
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

    // TODO: Copy to clipboard
    // await Clipboard.setData(ClipboardData(text: _profileShareUrl));
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
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Share Profile',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          SectionHeader(
            title: 'Share Your Profile',
            icon: Icons.share,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Share your profile link with friends or on social media',
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Share URL
          SectionHeader(
            title: 'Profile Link',
            icon: Icons.link,
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
                        child: Text(
                          _profileShareUrl ?? 'Generating...',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
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
                    icon: Icons.share,
                  ),
                ],
              ],
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Share options
          SectionHeader(
            title: 'Share Options',
            icon: Icons.more_horiz,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildShareOption(
            icon: Icons.message,
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
            icon: Icons.email,
            title: 'Share via Email',
            description: 'Send via email',
            onTap: _shareProfile,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildShareOption(
            icon: Icons.qr_code,
            title: 'QR Code',
            description: 'Generate QR code for easy sharing',
            onTap: () {
              // TODO: Show QR code dialog
              AlertDialogCustom.show(
                context,
                title: 'QR Code',
                message: 'QR code generation coming soon',
                icon: Icons.qr_code,
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Privacy note
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.accentPurple.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.accentPurple,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Text(
                    'Anyone with this link can view your profile. Make sure you trust the person you\'re sharing with.',
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
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
                  color: AppColors.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Icon(
                  icon,
                  color: AppColors.accentPurple,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
