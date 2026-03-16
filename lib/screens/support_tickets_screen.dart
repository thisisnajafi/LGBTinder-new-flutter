// Screen: SupportTicketsScreen — list tickets, create ticket, view ticket detail (TicketApiService).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/providers/api_providers.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../shared/services/error_handler_service.dart';
import '../shared/models/api_error.dart';

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
                label: 'Create ticket',
              ),
            ],
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
    } catch (_) {}
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLG)),
      ),
      builder: (ctx) => _TicketDetailSheet(
        ticket: detail,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        borderColor: borderColor,
      ),
    );
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
        title: 'Support tickets',
        showBackButton: true,
        actions: [
          TextButton.icon(
            onPressed: () => _showNewTicketBottomSheet(context, isDark, textColor, surfaceColor),
            icon: Icon(Icons.add, size: 20, color: AppColors.accentPurple),
            label: Text(
              'New ticket',
              style: AppTypography.button.copyWith(color: AppColors.accentPurple),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: AppTypography.body.copyWith(color: secondaryTextColor), textAlign: TextAlign.center),
                        SizedBox(height: AppSpacing.spacingMD),
                        TextButton(
                          onPressed: _loadTickets,
                          child: Text('Retry', style: AppTypography.button.copyWith(color: AppColors.accentPurple)),
                        ),
                      ],
                    ),
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 64, color: secondaryTextColor),
                          SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'No tickets yet',
                            style: AppTypography.h3.copyWith(color: textColor),
                          ),
                          SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'Create a ticket to get help from support.',
                            style: AppTypography.body.copyWith(color: secondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.spacingLG),
                          GradientButton(
                            onPressed: () => _showNewTicketBottomSheet(context, isDark, textColor, surfaceColor),
                            label: 'New ticket',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.spacingMD),
                        itemCount: _tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _tickets[index];
                          return _TicketTile(
                            ticket: ticket,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            surfaceColor: surfaceColor,
                            borderColor: borderColor,
                            onTap: () => _showTicketDetail(context, ticket, isDark, textColor, secondaryTextColor, surfaceColor, borderColor),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final SupportTicketItem ticket;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _TicketTile({
    required this.ticket,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.subject ?? 'Ticket #${ticket.id}',
                        style: AppTypography.body.copyWith(color: textColor, fontWeight: FontWeight.w600),
                      ),
                      if (ticket.status != null || ticket.createdAt != null) ...[
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          [if (ticket.status != null) ticket.status, if (ticket.createdAt != null) ticket.createdAt].join(' · '),
                          style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: secondaryTextColor),
              ],
            ),
          ),
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
