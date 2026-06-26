// Screen: SupportTicketsScreen — list tickets, create ticket, view ticket detail (TicketApiService).
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/providers/api_providers.dart';
import '../core/services/app_logger.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_action_bottom_sheet.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../widgets/buttons/gradient_button.dart';

const _situationOptions = <String, String>{
  'bug': 'Bug / technical issue',
  'feature_request': 'Feature request',
  'account_issue': 'Account issue',
  'payment_issue': 'Payment issue',
  'other': 'Other',
};

/// Parsed ticket item from GET tickets list or GET tickets/:id.
class SupportTicketItem {
  final int id;
  final String? title;
  final String? description;
  final String? situation;
  final String? status;
  final String? screenshotUrl;
  final String? adminNotes;
  final String? resolvedAt;
  final String? createdAt;
  final String? updatedAt;

  SupportTicketItem({
    required this.id,
    this.title,
    this.description,
    this.situation,
    this.status,
    this.screenshotUrl,
    this.adminNotes,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  String get displayTitle => title?.trim().isNotEmpty == true ? title!.trim() : 'Ticket #$id';

  String get displayStatusLabel => statusLabel(status, hasAdminReply: adminNotes?.trim().isNotEmpty == true);

  static String statusLabel(String? status, {bool hasAdminReply = false}) {
    switch (status) {
      case 'pending':
        return hasAdminReply ? 'Answered' : 'Open';
      case 'in_progress':
        return hasAdminReply ? 'Answered' : 'In progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status ?? 'Unknown';
    }
  }

  static String situationLabel(String? situation) =>
      _situationOptions[situation] ?? situation ?? 'General';

  static List<dynamic> extractList(Map<String, dynamic> data) {
    final tickets = data['tickets'];
    if (tickets is List) return tickets;
    if (tickets is Map && tickets['data'] is List) {
      return tickets['data'] as List;
    }
    return const [];
  }

  static SupportTicketItem? fromPayload(Map<String, dynamic> data) {
    if (data['ticket'] is Map) {
      return fromJson(Map<String, dynamic>.from(data['ticket'] as Map));
    }
    if (data.containsKey('id')) {
      return fromJson(data);
    }
    return null;
  }

  static SupportTicketItem fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return SupportTicketItem(
      id: id is int ? id : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['subject']?.toString(),
      description: json['description']?.toString() ?? json['message']?.toString(),
      situation: json['situation']?.toString(),
      status: json['status']?.toString(),
      screenshotUrl: json['screenshot_url']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

/// Support tickets screen: list (GET tickets), create (POST tickets), detail (GET tickets/:id).
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  List<SupportTicketItem> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(ticketApiServiceProvider);
      final data = await service.getTickets(page: 1);
      final list = SupportTicketItem.extractList(data)
          .map((e) => SupportTicketItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (mounted) {
        setState(() {
          _tickets = list;
          _loading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _createTicket({
    required String title,
    required String description,
    required String situation,
    String? screenshotPath,
  }) async {
    try {
      final service = ref.read(ticketApiServiceProvider);
      final data = await service.createTicket(
        title: title,
        description: description,
        situation: situation,
        screenshotPath: screenshotPath,
      );
      final created = SupportTicketItem.fromPayload(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created != null
                  ? 'Ticket #${created.id} submitted successfully'
                  : 'Ticket submitted successfully',
            ),
          ),
        );
        _loadTickets();
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context, e, customMessage: 'Failed to create ticket');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(context, e, customMessage: 'Failed to create ticket');
      }
    }
  }

  void _showNewTicketBottomSheet(BuildContext context, bool isDark, Color textColor, Color surfaceColor) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedSituation = 'bug';
    String? screenshotPath;
    File? screenshotFile;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => AppBottomSheetShell(
          showCancel: true,
          body: AppBottomSheetCard(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.spacingLG,
                right: AppSpacing.spacingLG,
                top: AppSpacing.spacingLG,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.spacingLG,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New support ticket',
                    style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSituation,
                    decoration: InputDecoration(
                      labelText: 'Issue type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    ),
                    items: _situationOptions.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedSituation = value);
                      }
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSM)),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        maxHeight: 1920,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setSheetState(() {
                          screenshotPath = image.path;
                          screenshotFile = File(image.path);
                        });
                      }
                    },
                    icon: AppSvgIcon(assetPath: AppIcons.gallery, size: 18, color: AppColors.accentViolet),
                    label: Text(screenshotFile == null ? 'Attach screenshot (optional)' : 'Change screenshot'),
                  ),
                  if (screenshotFile != null) ...[
                    SizedBox(height: AppSpacing.spacingSM),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      child: Image.file(
                        screenshotFile!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.spacingLG),
                  GradientButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();
                      if (title.isEmpty || description.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title and description')),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop();
                      await _createTicket(
                        title: title,
                        description: description,
                        situation: selectedSituation,
                        screenshotPath: screenshotPath,
                      );
                    },
                    text: 'Create ticket',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetail(
    BuildContext context,
    SupportTicketItem ticket,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) async {
    SupportTicketItem detail = ticket;
    try {
      final service = ref.read(ticketApiServiceProvider);
      final data = await service.getTicket(ticket.id);
      final parsed = SupportTicketItem.fromPayload(data);
      if (parsed != null) detail = parsed;
    } catch (e) {
      AppLogger.warning('Failed to refresh ticket detail', tag: 'support_tickets_screen', error: e);
    }
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheetShell(
        showCancel: true,
        body: AppBottomSheetCard(
          child: _TicketDetailSheet(
            ticket: detail,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return AppSettingsDetailScaffold(
      title: 'Support tickets',
      subtitle: 'View and create support requests',
      action: IconButton(
        onPressed: () => _showNewTicketBottomSheet(context, isDark, textColor, surfaceColor),
        icon: AppSvgIcon(
          assetPath: AppIcons.add,
          size: 22,
          color: AppColors.accentViolet,
        ),
        tooltip: 'New ticket',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacingLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: AppTypography.body.copyWith(color: secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.spacingMD),
                        TextButton(
                          onPressed: _loadTickets,
                          child: Text(
                            'Retry',
                            style: AppTypography.button.copyWith(color: AppColors.accentViolet),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.spacingLG),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppSvgIcon(
                              assetPath: AppIcons.document,
                              size: 56,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(height: AppSpacing.spacingMD),
                            Text(
                              'No tickets yet',
                              style: AppTypography.h3.copyWith(color: textColor),
                            ),
                            const SizedBox(height: AppSpacing.spacingSM),
                            Text(
                              'Create a ticket to get help from support.',
                              style: AppTypography.body.copyWith(color: secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.spacingLG),
                            GradientButton(
                              onPressed: () => _showNewTicketBottomSheet(
                                context,
                                isDark,
                                textColor,
                                surfaceColor,
                              ),
                              text: 'New ticket',
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: AppSettingsDetailList(
                        children: [
                          PremiumSettingsGroup(
                            title: 'Your tickets',
                            children: [
                              for (final ticket in _tickets)
                                PremiumSettingsTile(
                                  iconPath: AppIcons.document,
                                  title: ticket.displayTitle,
                                  subtitle: [
                                    ticket.displayStatusLabel,
                                    if (ticket.createdAt != null) ticket.createdAt,
                                  ].join(' · '),
                                  onTap: () => _showTicketDetail(
                                    context,
                                    ticket,
                                    isDark,
                                    textColor,
                                    secondaryTextColor,
                                    borderColor,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _TicketDetailSheet extends StatelessWidget {
  final SupportTicketItem ticket;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final bool isDark;

  const _TicketDetailSheet({
    required this.ticket,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.displayTitle,
              style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              'Status: ${ticket.displayStatusLabel}',
              style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
            ),
            if (ticket.situation != null) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                'Type: ${SupportTicketItem.situationLabel(ticket.situation)}',
                style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
              ),
            ],
            if (ticket.createdAt != null) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                'Created: ${ticket.createdAt}',
                style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
              ),
            ],
            if (ticket.resolvedAt != null) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                'Resolved: ${ticket.resolvedAt}',
                style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
              ),
            ],
            SizedBox(height: AppSpacing.spacingMD),
            Text('Your message', style: AppTypography.titleMedium.copyWith(color: textColor)),
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              ticket.description?.isNotEmpty == true ? ticket.description! : 'No description provided.',
              style: AppTypography.body.copyWith(color: textColor),
            ),
            if (ticket.screenshotUrl != null && ticket.screenshotUrl!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacingMD),
              Text('Screenshot', style: AppTypography.titleMedium.copyWith(color: textColor)),
              SizedBox(height: AppSpacing.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                child: CachedNetworkImage(
                  imageUrl: ticket.screenshotUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Text(
                      'Could not load screenshot',
                      style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                    ),
                  ),
                ),
              ),
            ],
            if (ticket.adminNotes != null && ticket.adminNotes!.trim().isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacingLG),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.spacingMD),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support reply',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.accentViolet),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      ticket.adminNotes!,
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
