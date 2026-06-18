// Screen: HelpSupportScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/providers/api_providers.dart';
import '../shared/services/landing_service.dart';
import '../core/widgets/app_grouped_list_card.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_action_bottom_sheet.dart';
import '../widgets/buttons/gradient_button.dart';
import '../routes/app_router.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

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
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final surfaceColor = theme.colorScheme.surface;
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.35);

    return AppSettingsDetailScaffold(
      title: 'Help & Support',
      body: AppSettingsDetailList(
        children: [
          AppGroupedListSection(
            title: 'About',
            padding: AppSettingsLayout.firstSectionPadding,
            children: [
              AppSettingsInset(
                child: Consumer(
                  builder: (context, ref, _) {
                    final settingsAsync = ref.watch(_landingSettingsProvider);
                    return settingsAsync.when(
                      data: (LandingSettings? settings) {
                        if (settings == null) {
                          return _buildAboutPlaceholder(
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          );
                        }
                        return _buildAboutContent(
                          settings: settings,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        );
                      },
                      loading: () => _buildAboutPlaceholder(
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      error: (_, __) => _buildAboutPlaceholder(
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Consumer(
            builder: (context, ref, _) {
              final statsAsync = ref.watch(_landingStatsProvider);
              return statsAsync.when(
                data: (List<LandingStatItem> stats) {
                  if (stats.isEmpty) return const SizedBox.shrink();
                  return AppGroupedListSection(
                    title: 'Community',
                    padding: AppSettingsLayout.sectionPadding,
                    children: [
                      AppSettingsInset(
                        child: _buildStatsContent(
                          stats: stats,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final testimonialsAsync = ref.watch(_landingTestimonialsProvider);
              return testimonialsAsync.when(
                data: (List<LandingTestimonialItem> list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return AppGroupedListSection(
                    title: 'What People Say',
                    padding: AppSettingsLayout.sectionPadding,
                    children: [
                      AppSettingsInset(
                        child: _buildTestimonialsContent(
                          list: list,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          AppGroupedListSection(
            title: 'Tips & Blog',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final blogsAsync = ref.watch(_landingBlogsProvider);
                  return blogsAsync.when(
                    data: (List<LandingBlogItem> blogs) {
                      if (blogs.isEmpty) {
                        return AppSettingsInset(
                          child: _buildBlogPlaceholder(
                            secondaryTextColor: secondaryTextColor,
                          ),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < blogs.length; i++) ...[
                            AppGroupedListTile(
                              iconPath: AppIcons.documentText,
                              label: blogs[i].title ?? 'Untitled',
                              subtitle: blogs[i].excerpt,
                              onTap: () => _showBlogDetail(
                                context,
                                ref,
                                blogs[i],
                                isDark,
                                textColor,
                                secondaryTextColor,
                                surfaceColor,
                                borderColor,
                              ),
                              showDivider: i < blogs.length - 1,
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => AppSettingsInset(
                      child: _buildBlogPlaceholder(
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                    error: (_, __) => AppSettingsInset(
                      child: _buildBlogPlaceholder(
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          AppGroupedListSection(
            title: 'Contact Support',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              AppGroupedListTile(
                iconPath: AppIcons.send,
                label: 'Send A Message',
                subtitle: 'We\'ll get back to you soon',
                onTap: () => _showContactFormBottomSheet(
                  context,
                  ref,
                  isDark,
                  textColor,
                  secondaryTextColor,
                  surfaceColor,
                  borderColor,
                ),
              ),
              AppGroupedListTile(
                iconPath: AppIcons.document,
                label: 'My Tickets',
                subtitle: 'View and create support tickets',
                onTap: () => context.push(AppRoutes.supportTickets),
              ),
              AppGroupedListTile(
                iconPath: AppIcons.message,
                label: 'Email Support',
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Unable to open email app. You can create a support ticket instead.',
                          ),
                          action: SnackBarAction(
                            label: 'Create ticket',
                            onPressed: () => context.push(AppRoutes.supportTickets),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Unable to open email app. You can create a support ticket instead.',
                        ),
                        action: SnackBarAction(
                          label: 'Create ticket',
                          onPressed: () => context.push(AppRoutes.supportTickets),
                        ),
                      ),
                    );
                  }
                },
              ),
              AppGroupedListTile(
                iconPath: AppIcons.messageCircle,
                label: 'Live Chat',
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
                          child: const Text('OK'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push(AppRoutes.supportTickets);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Create Ticket'),
                        ),
                      ],
                    ),
                  );
                },
                showDivider: false,
              ),
            ],
          ),
          AppGroupedListSection(
            title: 'Frequently Asked Questions',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              for (var i = 0; i < _faqItems.length; i++)
                _buildGroupedFAQItem(
                  question: _faqItems[i]['question'] as String,
                  answer: _faqItems[i]['answer'] as String,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  showDivider: i < _faqItems.length - 1,
                ),
            ],
          ),
          AppGroupedListSection(
            title: 'Legal',
            padding: AppSettingsLayout.sectionPadding,
            children: [
              AppGroupedListTile(
                iconPath: AppIcons.documentText,
                label: 'Terms Of Service',
                onTap: () => context.push(AppRoutes.termsOfService),
              ),
              AppGroupedListTile(
                iconPath: AppIcons.shield,
                label: 'Privacy Policy',
                onTap: () => context.push(AppRoutes.privacyPolicy),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildGroupedFAQItem({
    required String question,
    required String answer,
    required Color textColor,
    required Color secondaryTextColor,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.spacingMD,
              0,
              AppSpacing.spacingMD,
              AppSpacing.spacingMD,
            ),
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
              Text(
                answer,
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const AppGroupedRowSeparator(),
      ],
    );
  }

  Widget _buildAboutContent({
    required LandingSettings settings,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.siteName != null && settings.siteName!.isNotEmpty)
          Text(
            settings.siteName!,
            style: AppTypography.h3.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (settings.tagline != null && settings.tagline!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            settings.tagline!,
            style: AppTypography.body.copyWith(
              color: AppColors.accentPurple,
              fontWeight: FontWeight.w600,
            ),
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
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: [
              if (settings.appStoreUrl != null && settings.appStoreUrl!.isNotEmpty)
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse(settings.appStoreUrl!)),
                  child: Text(
                    'App Store',
                    style: AppTypography.labelMedium.copyWith(color: textColor),
                  ),
                ),
              if (settings.googlePlayUrl != null && settings.googlePlayUrl!.isNotEmpty)
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse(settings.googlePlayUrl!)),
                  child: Text(
                    'Google Play',
                    style: AppTypography.labelMedium.copyWith(color: textColor),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAboutPlaceholder({
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Text(
      'LGBTFinder — Find your match. Be yourself.',
      style: AppTypography.body.copyWith(color: secondaryTextColor),
    );
  }

  Widget _buildStatsContent({
    required List<LandingStatItem> stats,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.take(4).map((s) {
        return Expanded(
          child: Column(
            children: [
              Text(
                s.value ?? '—',
                style: AppTypography.h4.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
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
    );
  }

  Widget _buildTestimonialsContent({
    required List<LandingTestimonialItem> list,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in list.take(3)) ...[
          if (t.quote != null && t.quote!.isNotEmpty)
            Text(
              '"${t.quote}"',
              style: AppTypography.body.copyWith(
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (t.author != null || t.location != null) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              [if (t.author != null) t.author, if (t.location != null) t.location]
                  .join(' · '),
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
          ],
          if (t != list.take(3).last) SizedBox(height: AppSpacing.spacingMD),
        ],
      ],
    );
  }

  Widget _buildBlogPlaceholder({
    required Color secondaryTextColor,
  }) {
    return Text(
      'Tips and blog posts will appear here.',
      style: AppTypography.body.copyWith(color: secondaryTextColor),
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
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'help_support_screen', error: e); }
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheetShell(
        showCancel: true,
        body: AppBottomSheetListBody(
          title: detail!.title?.isNotEmpty == true ? detail.title! : 'Blog',
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.category != null && detail.category!.isNotEmpty)
                  Text(detail.category!, style: AppTypography.labelMedium.copyWith(color: AppColors.accentPurple)),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheetShell(
        showCancel: true,
        body: AppBottomSheetCard(
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
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                ),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                        content: Text(
                          success
                              ? 'Message sent. We\'ll get back to you soon.'
                              : 'Failed to send. You can create a support ticket now.',
                        ),
                        action: success
                            ? null
                            : SnackBarAction(
                                label: 'Create ticket',
                                onPressed: () => context.push(AppRoutes.supportTickets),
                              ),
                      ),
                    );
                  }
                },
                text: 'Send message',
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
