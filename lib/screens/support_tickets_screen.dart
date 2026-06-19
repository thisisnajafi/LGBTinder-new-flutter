// Screen: SupportTicketsScreen — list tickets, create ticket, view ticket detail (TicketApiService).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/providers/api_providers.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_action_bottom_sheet.dart';
import '../widgets/buttons/gradient_button.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/models/api_error.dart';
import 'package:lgbtindernew/core/services/app_logger.dart';

/// Parsed ticket item from GET tickets list or GET tickets/:id.
class SupportTicketItem {
  final int id;
  final String? subject;
  final String? message;
  final String? status;
  final String? createdAt;

  SupportTicketItem({
    required this.id,
    this.subject,
    this.message,
    this.status,
    this.createdAt,
  });

  static SupportTicketItem fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return SupportTicketItem(
      id: id is int ? id : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      subject: json['subject']?.toString(),
      message: json['message']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
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
      final List<dynamic> raw = data['data']?['tickets'] ?? data['tickets'] ?? (data['data'] is List ? data['data'] as List : const []);
      final list = raw.map((e) => SupportTicketItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
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

  Future<void> _createTicket(String subject, String message) async {
    try {
      final service = ref.read(ticketApiServiceProvider);
      await service.createTicket({'subject': subject, 'message': message});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket created')));
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
                  'New support ticket',
                  style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ),
              SizedBox(height: AppSpacing.spacingMD),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
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
                  final subject = subjectController.text.trim();
                  final message = messageController.text.trim();
                  if (subject.isEmpty || message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter subject and message')),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  await _createTicket(subject, message);
                },
                text: 'Create ticket',
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showTicketDetail(BuildContext context, SupportTicketItem ticket, bool isDark, Color textColor, Color secondaryTextColor, Color surfaceColor, Color borderColor) async {
    SupportTicketItem detail = ticket;
    try {
      final service = ref.read(ticketApiServiceProvider);
      final data = await service.getTicket(ticket.id);
      if (data['data'] != null && context.mounted) {
        detail = SupportTicketItem.fromJson(Map<String, dynamic>.from(data['data'] as Map));
      }
    } catch (e) { AppLogger.warning('Silently caught exception', tag: 'support_tickets_screen', error: e); }
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
        onPressed: () =>
            _showNewTicketBottomSheet(context, isDark, textColor, surfaceColor),
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
                          style: AppTypography.body
                              .copyWith(color: secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.spacingMD),
                        TextButton(
                          onPressed: _loadTickets,
                          child: Text(
                            'Retry',
                            style: AppTypography.button
                                .copyWith(color: AppColors.accentViolet),
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
                              style: AppTypography.body
                                  .copyWith(color: secondaryTextColor),
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
                                  title: ticket.subject ?? 'Ticket #${ticket.id}',
                                  subtitle: [
                                    if (ticket.status != null) ticket.status,
                                    if (ticket.createdAt != null) ticket.createdAt,
                                  ].join(' · '),
                                  onTap: () => _showTicketDetail(
                                    context,
                                    ticket,
                                    isDark,
                                    textColor,
                                    secondaryTextColor,
                                    surfaceColor,
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

  const _TicketDetailSheet({
    required this.ticket,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
            Text(
              ticket.subject ?? 'Ticket #${ticket.id}',
              style: AppTypography.h3.copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
            if (ticket.status != null) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text('Status: ${ticket.status}', style: AppTypography.bodySmall.copyWith(color: secondaryTextColor)),
            ],
            if (ticket.createdAt != null) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text('Created: ${ticket.createdAt}', style: AppTypography.bodySmall.copyWith(color: secondaryTextColor)),
            ],
            SizedBox(height: AppSpacing.spacingMD),
            if (ticket.message != null && ticket.message!.isNotEmpty)
              Text(
                ticket.message!,
                style: AppTypography.body.copyWith(color: textColor),
              )
            else
              Text(
                'No message.',
                style: AppTypography.body.copyWith(color: secondaryTextColor),
              ),
          ],
        ),
      ),
    );
  }
}
