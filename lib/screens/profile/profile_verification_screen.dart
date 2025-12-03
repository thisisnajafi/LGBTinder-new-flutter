// Screen: ProfileVerificationScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/badges/verification_badge.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Profile verification screen - Verification process and document upload
class ProfileVerificationScreen extends ConsumerStatefulWidget {
  const ProfileVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileVerificationScreen> createState() => _ProfileVerificationScreenState();
}

class _ProfileVerificationScreenState extends ConsumerState<ProfileVerificationScreen> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _verificationStatus = 'pending'; // 'pending', 'approved', 'rejected', 'none'
  String? _rejectionReason;
  DateTime? _submittedAt;
  DateTime? _reviewedAt;

  // Document uploads
  String? _idFrontUrl;
  String? _idBackUrl;
  String? _selfieUrl;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load verification status from API
      // GET /api/profile/verification
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _verificationStatus = 'pending';
          _submittedAt = DateTime.now().subtract(const Duration(days: 2));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load verification status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadDocument(String type) async {
    // TODO: Open image picker and upload document
    // POST /api/profile/verification/documents
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document upload coming soon')),
    );
  }

  Future<void> _submitVerification() async {
    if (_idFrontUrl == null || _idBackUrl == null || _selfieUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Submit verification via API
      // POST /api/profile/verification/submit
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _verificationStatus = 'pending';
          _submittedAt = DateTime.now();
        });
        AlertDialogCustom.show(
          context,
          title: 'Verification Submitted',
          message: 'Your verification request has been submitted. We\'ll review it within 24-48 hours.',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit verification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBarCustom(
          title: 'Verification',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Verification',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Status banner
          if (_verificationStatus == 'approved')
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.onlineGreen,
                    AppColors.onlineGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Account',
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          'Your account has been verified',
                          style: AppTypography.body.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_verificationStatus == 'rejected')
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
              decoration: BoxDecoration(
                color: AppColors.notificationRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: AppColors.notificationRed),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.notificationRed,
                        size: 32,
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: Text(
                          'Verification Rejected',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.notificationRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_rejectionReason != null) ...[
                    SizedBox(height: AppSpacing.spacingMD),
                    Text(
                      'Reason: $_rejectionReason',
                      style: AppTypography.body.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.spacingMD),
                  GradientButton(
                    text: 'Resubmit Verification',
                    onPressed: () {
                      setState(() {
                        _verificationStatus = 'none';
                        _idFrontUrl = null;
                        _idBackUrl = null;
                        _selfieUrl = null;
                      });
                    },
                    isFullWidth: true,
                  ),
                ],
              ),
            )
          else if (_verificationStatus == 'pending')
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: AppColors.warningYellow),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pending,
                    color: AppColors.warningYellow,
                    size: 32,
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Pending',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.warningYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          _submittedAt != null
                              ? 'Submitted ${_formatTime(_submittedAt!)}'
                              : 'Your verification is being reviewed',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Info section
          SectionHeader(
            title: 'Why Verify?',
            icon: Icons.info,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBenefitItem(
                  icon: Icons.verified_user,
                  title: 'Build Trust',
                  description: 'Show others you\'re a real person',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                _buildBenefitItem(
                  icon: Icons.trending_up,
                  title: 'Get More Matches',
                  description: 'Verified profiles get 3x more matches',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                _buildBenefitItem(
                  icon: Icons.security,
                  title: 'Safer Community',
                  description: 'Help keep our community safe and authentic',
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ],
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Document uploads
          if (_verificationStatus != 'approved') ...[
            SectionHeader(
              title: 'Required Documents',
              icon: Icons.description,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildDocumentUpload(
              title: 'ID Front',
              description: 'Upload the front of your government-issued ID',
              imageUrl: _idFrontUrl,
              onUpload: () => _uploadDocument('id_front'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildDocumentUpload(
              title: 'ID Back',
              description: 'Upload the back of your government-issued ID',
              imageUrl: _idBackUrl,
              onUpload: () => _uploadDocument('id_back'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildDocumentUpload(
              title: 'Selfie',
              description: 'Take a selfie holding your ID next to your face',
              imageUrl: _selfieUrl,
              onUpload: () => _uploadDocument('selfie'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Guidelines
            SectionHeader(
              title: 'Guidelines',
              icon: Icons.rule,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuidelineItem(
                    '• ID must be government-issued (driver\'s license, passport, etc.)',
                    textColor,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  _buildGuidelineItem(
                    '• All text must be clearly visible and readable',
                    textColor,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  _buildGuidelineItem(
                    '• Selfie must show your full face and the ID clearly',
                    textColor,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  _buildGuidelineItem(
                    '• Documents must be valid and not expired',
                    textColor,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  _buildGuidelineItem(
                    '• Review typically takes 24-48 hours',
                    textColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.spacingXXL),
            GradientButton(
              text: _isSubmitting ? 'Submitting...' : 'Submit for Verification',
              onPressed: _isSubmitting || _verificationStatus == 'pending'
                  ? null
                  : _submitVerification,
              isLoading: _isSubmitting,
              isFullWidth: true,
              icon: Icons.send,
            ),
          ],
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          ),
          child: Icon(
            icon,
            color: AppColors.accentPurple,
            size: 20,
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
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String description,
    required String? imageUrl,
    required VoidCallback onUpload,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: imageUrl != null
              ? AppColors.onlineGreen
              : borderColor,
          width: imageUrl != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (imageUrl != null)
                Icon(
                  Icons.check_circle,
                  color: AppColors.onlineGreen,
                  size: 24,
                ),
            ],
          ),
          if (imageUrl != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              child: Container(
                height: 150,
                width: double.infinity,
                color: surfaceColor,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: surfaceColor,
                      child: Icon(
                        Icons.image,
                        color: secondaryTextColor,
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: AppSpacing.spacingMD),
            GradientButton(
              text: 'Upload $title',
              onPressed: onUpload,
              isFullWidth: true,
              icon: Icons.upload,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text, Color textColor) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: textColor,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
