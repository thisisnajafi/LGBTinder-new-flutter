// Screen: HelpSupportScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/bottom_sheet_custom.dart';
import 'legal/terms_of_service_screen.dart';
import 'legal/privacy_policy_screen.dart';

/// Help and support screen - Get help and support
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I create an account?',
      'answer': 'You can create an account by tapping "Sign Up" on the welcome screen and following the registration process.',
    },
    {
      'question': 'How do I match with someone?',
      'answer': 'Swipe right on profiles you like. If they also swipe right on you, it\'s a match!',
    },
    {
      'question': 'How do I report a user?',
      'answer': 'Go to the user\'s profile, tap the menu icon, and select "Report". Our team will review your report.',
    },
    {
      'question': 'How do I cancel my subscription?',
      'answer': 'Go to Settings > Premium > Manage Subscription to cancel your subscription.',
    },
  ];

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
        title: 'Help & Support',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Contact support
          SectionHeader(
            title: 'Contact Support',
            icon: Icons.support_agent,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSupportCard(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@lgbtinder.com',
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@lgbtinder.com',
                queryParameters: {
                  'subject': 'LGBTinder Support Request',
                  'body': 'Please describe your issue or question here...',
                },
              );

              try {
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  // Fallback to copying email to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email: support@lgbtinder.com (copied to clipboard)')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to open email app')),
                );
              }
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSupportCard(
            icon: Icons.chat_bubble,
            title: 'Live Chat',
            subtitle: 'Available 24/7',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Live Chat Support',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  content: Text(
                    'Our live chat support is currently under development. For immediate assistance, please use email support or check our FAQ section.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Trigger email support instead
                        // TODO: Implement actual live chat integration (e.g., Intercom, Zendesk, etc.)
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Use Email Support'),
                    ),
                  ],
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // FAQ
          SectionHeader(
            title: 'Frequently Asked Questions',
            icon: Icons.help_outline,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ..._faqItems.map((faq) {
            return _buildFAQItem(
              question: faq['question'],
              answer: faq['answer'],
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            );
          }),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Legal
          SectionHeader(
            title: 'Legal',
            icon: Icons.gavel,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ListTile(
            leading: Icon(Icons.description, color: AppColors.accentPurple),
            title: Text(
              'Terms of Service',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: secondaryTextColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: AppColors.accentPurple),
            title: Text(
              'Privacy Policy',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: secondaryTextColor),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
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
                    style: AppTypography.h3.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    subtitle,
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
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppColors.accentPurple,
        collapsedIconColor: secondaryTextColor,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Text(
              answer,
              style: AppTypography.body.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
