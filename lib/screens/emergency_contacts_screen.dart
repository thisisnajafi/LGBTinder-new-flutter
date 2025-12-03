// Screen: EmergencyContactsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/confirmation_dialog.dart';
import '../widgets/error_handling/empty_state.dart';

/// Emergency contacts screen - Manage emergency contacts
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    // TODO: Load contacts from API
    setState(() {
      _contacts = [
        {
          'id': 1,
          'name': 'Emergency Contact 1',
          'phone': '+1234567890',
          'relationship': 'Friend',
        },
      ];
    });
  }

  Future<void> _handleAddContact() async {
    // TODO: Open add contact dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddContactDialog(),
    );
    if (result != null) {
      setState(() {
        _contacts.add({
          'id': _contacts.length + 1,
          ...result,
        });
      });
    }
  }

  Future<void> _handleDeleteContact(int id) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Contact',
      message: 'Are you sure you want to remove this emergency contact?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() {
        _contacts.removeWhere((contact) => contact['id'] == id);
      });
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
        title: 'Emergency Contacts',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: EdgeInsets.all(AppSpacing.spacingLG),
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: AppColors.warningYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: AppColors.warningYellow),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warningYellow,
                  size: 24,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Text(
                    'Emergency contacts can be notified in case of safety concerns',
                    style: AppTypography.body.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contacts list
          Expanded(
            child: _contacts.isEmpty
                ? EmptyState(
                    title: 'No Emergency Contacts',
                    message: 'Add emergency contacts for your safety',
                    icon: Icons.emergency,
                    actionLabel: 'Add Contact',
                    onAction: _handleAddContact,
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
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
                                color: AppColors.notificationRed.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.emergency,
                                color: AppColors.notificationRed,
                              ),
                            ),
                            SizedBox(width: AppSpacing.spacingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact['name'],
                                    style: AppTypography.h3.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.spacingXS),
                                  Text(
                                    contact['phone'],
                                    style: AppTypography.body.copyWith(
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  if (contact['relationship'] != null)
                                    Text(
                                      contact['relationship'],
                                      style: AppTypography.caption.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.notificationRed,
                              ),
                              onPressed: () => _handleDeleteContact(contact['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Add button
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: GradientButton(
              text: 'Add Emergency Contact',
              onPressed: _handleAddContact,
              isFullWidth: true,
              icon: Icons.add,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Dialog(
      backgroundColor: surfaceColor,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Emergency Contact',
                style: AppTypography.h2.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingLG),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a phone number' : null,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextFormField(
                controller: _relationshipController,
                decoration: InputDecoration(
                  labelText: 'Relationship (Optional)',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                style: AppTypography.body.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingLG),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTypography.button.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: GradientButton(
                      text: 'Add',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'name': _nameController.text,
                            'phone': _phoneController.text,
                            'relationship': _relationshipController.text,
                          });
                        }
                      },
                      isFullWidth: true,
                      height: 40,
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
