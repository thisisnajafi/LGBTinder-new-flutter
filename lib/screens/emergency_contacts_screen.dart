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
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';

/// Emergency contacts screen - Manage emergency contacts
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.emergencyContacts,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Canonical API (Task 7): GET /emergency-contacts returns data.contacts; legacy safety returns data (list)
        final raw = response.data!;
        final List<dynamic> list;
        if (raw is Map && raw['contacts'] != null && raw['contacts'] is List) {
          list = List<dynamic>.from(raw['contacts'] as List);
        } else if (raw is List) {
          list = List<dynamic>.from(raw as List);
        } else if (raw is Map && raw['data'] is List) {
          list = List<dynamic>.from(raw['data'] as List);
        } else {
          list = <dynamic>[];
        }
        setState(() {
          _contacts = list.map((contact) => contact as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _contacts = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _contacts = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddContact() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddContactDialog(),
    );
    if (result != null) {
      try {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.post<Map<String, dynamic>>(
          ApiEndpoints.emergencyContacts,
          data: result,
          fromJson: (json) => json as Map<String, dynamic>,
        );

        if (response.isSuccess && response.data != null) {
          // Reload contacts to get the updated list with proper IDs
          await _loadContacts();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add emergency contact: $e')),
        );
      }
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
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.delete<Map<String, dynamic>>(
          '${ApiEndpoints.emergencyContacts}/$id',
          fromJson: (json) => json as Map<String, dynamic>,
        );

        // Reload contacts
        await _loadContacts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency contact removed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove emergency contact: $e')),
        );
      }
    }
  }

  Future<void> _handleEmergencyAlert() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Send Emergency Alert',
      message: 'This will immediately notify all your emergency contacts. Only use this feature in genuine emergencies.',
      confirmText: 'Send Alert',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.post<Map<String, dynamic>>(
          ApiEndpoints.emergencyTrigger,
          data: {
            'message': 'Emergency alert triggered from LGBTFinder app',
            'include_location': true,
          },
          fromJson: (json) => json as Map<String, dynamic>,
        );

        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert sent to your contacts'),
              backgroundColor: AppColors.onlineGreen,
            ),
          );
        } else {
          throw Exception('Failed to send emergency alert');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send emergency alert: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
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
          // Emergency alert button (only show if contacts exist)
          if (_contacts.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              child: ElevatedButton(
                onPressed: _handleEmergencyAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.notificationRed,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, color: Colors.white),
                    SizedBox(width: AppSpacing.spacingSM),
                    Text(
                      'Send Emergency Alert',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.spacingMD),
          ],

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
  final _emailController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isPrimary = false;

  final List<String> _relationshipOptions = [
    'Parent',
    'Sibling',
    'Child',
    'Spouse/Partner',
    'Friend',
    'Colleague',
    'Doctor',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusLG),
      ),
      title: Text(
        'Add Emergency Contact',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter contact\'s full name',
                  prefixIcon: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '+1234567890',
                  prefixIcon: Icon(Icons.phone, color: theme.colorScheme.onSurfaceVariant),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  // Basic phone number validation
                  if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value.replaceAll(' ', ''))) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),

              // Email field (optional)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'contact@example.com',
                  prefixIcon: Icon(Icons.email, color: theme.colorScheme.onSurfaceVariant),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),

              // Relationship dropdown
              DropdownButtonFormField<String>(
                value: _relationshipController.text.isNotEmpty ? _relationshipController.text : null,
                decoration: InputDecoration(
                  labelText: 'Relationship *',
                  prefixIcon: Icon(Icons.people, color: theme.colorScheme.onSurfaceVariant),
                ),
                items: _relationshipOptions.map((relationship) {
                  return DropdownMenuItem<String>(
                    value: relationship,
                    child: Text(relationship),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _relationshipController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a relationship';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.spacingMD),

              // Notes field (optional)
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional information about this contact',
                  prefixIcon: Icon(Icons.note, color: theme.colorScheme.onSurfaceVariant),
                ),
                maxLines: 2,
              ),
              SizedBox(height: AppSpacing.spacingMD),

              // Primary contact checkbox
              CheckboxListTile(
                title: Text(
                  'Set as primary emergency contact',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Primary contacts receive priority notifications',
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isPrimary,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'phone_number': _phoneController.text.trim(),
                'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
                'relationship': _relationshipController.text,
                'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                'is_primary': _isPrimary,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
            ),
          ),
          child: Text('Add Contact'),
        ),
      ],
    );
  }
}
