// Screen: HelpSupportScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/landing_service.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/bottom_sheet_custom.dart';
import 'legal/terms_of_service_screen.dart';
import 'legal/privacy_policy_screen.dart';
import 'support_tickets_screen.dart';

/// Fetches landing/settings for About section (app store links, tagline, description).
final _landingSettingsProvider = FutureProvider.autoDispose<LandingSettings?>((ref) {
  return ref.watch(landingServiceProvider).getSettings();
});

/// Fetches landing/blogs for Tips & Blog section.
final _landingBlogsProvider = FutureProvider.autoDispose<List<LandingBlogItem>>((ref) {
  return ref.watch(landingServiceProvider).getBlogs();
});

/// Fetches landing/stats for About section.
final _landingStatsProvider = FutureProvider.autoDispose<List<LandingStatItem>>((ref) {
  return ref.watch(landingServiceProvider).getStats();
});

/// Fetches landing/testimonials for About section.
final _landingTestimonialsProvider = FutureProvider.autoDispose<List<LandingTestimonialItem>>((ref) {
  return ref.watch(landingServiceProvider).getTestimonials();
});

/// Help and support screen - About (from landing/settings), contact form, FAQ, legal
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
          // About (from GET landing/settings)
          SectionHeader(
            title: 'About',
            icon: Icons.info_outline,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Consumer(
            builder: (context, ref, _) {
              final settingsAsync = ref.watch(_landingSettingsProvider);
              return settingsAsync.when(
                data: (LandingSettings? settings) {
                  if (settings == null) {
                    return _buildAboutPlaceholder(textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor);
                  }
                  return _buildAboutSection(settings: settings, textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor);
                },
                loading: () => _buildAboutPlaceholder(textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor),
                error: (_, __) => _buildAboutPlaceholder(textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor),
              );
            },
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(_landingStatsProvider);
              return statsAsync.when(
                data: (List<LandingStatItem> stats) {
                  if (stats.isEmpty) return SizedBox.shrink();
                  return _buildStatsRow(stats: stats, textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor);
                },
                loading: () => SizedBox.shrink(),
                error: (_, __) => SizedBox.shrink(),
              );
            },
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Consumer(
            builder: (context, ref, _) {
              final testimonialsAsync = ref.watch(_landingTestimonialsProvider);
              return testimonialsAsync.when(
                data: (List<LandingTestimonialItem> list) {
                  if (list.isEmpty) return SizedBox.shrink();
                  return _buildTestimonialsSection(list: list, textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor);
                },
                loading: () => SizedBox.shrink(),
                error: (_, __) => SizedBox.shrink(),
              );
            },
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Tips & Blog (from GET landing/blogs)
          SectionHeader(
            title: 'Tips & Blog',
            icon: Icons.article_outlined,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Consumer(
            builder: (context, ref, _) {
              final blogsAsync = ref.watch(_landingBlogsProvider);
              return blogsAsync.when(
                data: (List<LandingBlogItem> blogs) {
                  if (blogs.isEmpty) {
                    return _buildBlogPlaceholder(textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: blogs.map((blog) => _buildBlogTile(
                      blog: blog,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      onTap: () => _showBlogDetail(context, ref, blog, isDark, textColor, secondaryTextColor, surfaceColor, borderColor),
                    )).toList(),
                  );
                },
                loading: () => _buildBlogPlaceholder(textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor),
                error: (_, __) => _buildBlogPlaceholder(textColor: textColor, secondaryTextColor: secondaryTextColor, surfaceColor: surfaceColor, borderColor: borderColor),
              );
            },
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Contact support
          SectionHeader(
            title: 'Contact Support',
            icon: Icons.support_agent,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildSupportCard(
            icon: Icons.send,
            title: 'Send a message',
            subtitle: 'We\'ll get back to you soon',
            onTap: () => _showContactFormBottomSheet(context, ref, isDark, textColor, secondaryTextColor, surfaceColor, borderColor),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSupportCard(
            icon: Icons.confirmation_number_outlined,
            title: 'My tickets',
            subtitle: 'View and create support tickets',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupportTicketsScreen(),
                ),
              );
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildSupportCard(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@lgbtfinder.com',
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'support@lgbtfinder.com',
                queryParameters: {
                  'subject': 'LGBTFinder Support Request',
                  'body': 'Please describe your issue or question here...',
                },
              );

              try {
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  // Fallback to copying email to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email: support@lgbtfinder.com (copied to clipboard)')),
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

  Widget _buildAboutSection({
    required LandingSettings settings,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.siteName != null && settings.siteName!.isNotEmpty)
            Text(
              settings.siteName!,
              style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
          if (settings.tagline != null && settings.tagline!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              settings.tagline!,
              style: AppTypography.body.copyWith(color: AppColors.accentPurple, fontWeight: FontWeight.w600),
            ),
          ],
          if (settings.description != null && settings.description!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              settings.description!,
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            ),
          ],
          if ((settings.appStoreUrl != null && settings.appStoreUrl!.isNotEmpty) ||
              (settings.googlePlayUrl != null && settings.googlePlayUrl!.isNotEmpty)) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Row(
              children: [
                if (settings.appStoreUrl != null && settings.appStoreUrl!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.spacingSM),
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(settings.appStoreUrl!)),
                      icon: Icon(Icons.apple, size: 20, color: textColor),
                      label: Text('App Store', style: AppTypography.labelMedium.copyWith(color: textColor)),
                    ),
                  ),
                if (settings.googlePlayUrl != null && settings.googlePlayUrl!.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(settings.googlePlayUrl!)),
                    icon: Icon(Icons.android, size: 20, color: textColor),
                    label: Text('Google Play', style: AppTypography.labelMedium.copyWith(color: textColor)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutPlaceholder({
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: secondaryTextColor, size: 24),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Text(
              'LGBTFinder — Find your match. Be yourself.',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required List<LandingStatItem> stats,
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
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats.take(4).map((s) {
          IconData icon = Icons.people;
          if (s.icon == 'heart') icon = Icons.favorite;
          else if (s.icon == 'star') icon = Icons.star;
          else if (s.icon == 'users') icon = Icons.people;
          return Expanded(
            child: Column(
              children: [
                Icon(icon, size: 24, color: AppColors.accentPurple),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  s.value ?? '—',
                  style: AppTypography.titleMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ),
                Text(
                  s.label ?? '',
                  style: AppTypography.caption.copyWith(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestimonialsSection({
    required List<LandingTestimonialItem> list,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What people say',
          style: AppTypography.titleMedium.copyWith(color: textColor, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.spacingSM),
        ...list.take(3).map((t) => Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.quote != null && t.quote!.isNotEmpty)
                  Text(
                    '"${t.quote}"',
                    style: AppTypography.body.copyWith(color: textColor, fontStyle: FontStyle.italic),
                  ),
                if (t.author != null || t.location != null) ...[
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    [if (t.author != null) t.author, if (t.location != null) t.location].join(' · '),
                    style: AppTypography.caption.copyWith(color: secondaryTextColor),
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildBlogPlaceholder({
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, color: secondaryTextColor, size: 24),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Text(
              'Tips and blog posts will appear here.',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogTile({
    required LandingBlogItem blog,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (blog.category != null && blog.category!.isNotEmpty)
                  Text(
                    blog.category!,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.accentPurple),
                  ),
                if (blog.title != null && blog.title!.isNotEmpty) ...[
                  if (blog.category != null && blog.category!.isNotEmpty) SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    blog.title!,
                    style: AppTypography.body.copyWith(color: textColor, fontWeight: FontWeight.w600),
                  ),
                ],
                if (blog.excerpt != null && blog.excerpt!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    blog.excerpt!,
                    style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBlogDetail(
    BuildContext context,
    WidgetRef ref,
    LandingBlogItem blog,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) async {
    LandingBlogItem? detail = blog;
    try {
      final landingService = ref.read(landingServiceProvider);
      final fetched = await landingService.getBlogBySlug(blog.slug);
      if (fetched != null && context.mounted) detail = fetched;
    } catch (_) {}
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLG)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail!.category != null && detail.category!.isNotEmpty)
                Text(detail.category!, style: AppTypography.labelMedium.copyWith(color: AppColors.accentPurple)),
              if (detail.title != null && detail.title!.isNotEmpty) ...[
                if (detail.category != null) SizedBox(height: AppSpacing.spacingXS),
                Text(detail.title!, style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold)),
              ],
              if (detail.date != null && detail.date!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                  child: Text(detail.date!, style: AppTypography.bodySmall.copyWith(color: secondaryTextColor)),
                ),
              SizedBox(height: AppSpacing.spacingMD),
              if (detail.body != null && detail.body!.isNotEmpty)
                Text(detail.body!, style: AppTypography.body.copyWith(color: textColor))
              else if (detail.excerpt != null && detail.excerpt!.isNotEmpty)
                Text(detail.excerpt!, style: AppTypography.body.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactFormBottomSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLG)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contact us',
                style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                ),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                  filled: true,
                  fillColor: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                ),
                maxLines: 4,
              ),
              SizedBox(height: AppSpacing.spacingLG),
              GradientButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final message = messageController.text.trim();
                  final subject = subjectController.text.trim();
                  if (name.isEmpty || email.isEmpty || message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in name, email, and message')),
                    );
                    return;
                  }
                  final landingService = ref.read(landingServiceProvider);
                  final success = await landingService.sendContact(
                    name: name,
                    email: email,
                    message: message,
                    subject: subject.isEmpty ? null : subject,
                  );
                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Message sent. We\'ll get back to you soon.' : 'Failed to send. Please try again.'),
                      ),
                    );
                  }
                },
                label: 'Send message',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
