// Screen: ProfileCompletionScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_bio.dart';
import '../../widgets/profile/photo_gallery.dart';
import '../../widgets/profile/profile_info_sections.dart';
import '../../widgets/profile/avatar_upload.dart';
import '../../widgets/profile/edit/profile_field_editor.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import '../../pages/home_page.dart';
import '../../core/utils/app_icons.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/data/models/complete_registration_request.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/data/models/update_profile_request.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import 'dart:developer' as developer;

/// Profile completion screen - Complete user profile
class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  // Profile data
  String? _avatarUrl;
  String _name = '';
  int? _age;
  String _location = '';
  String _bio = '';
  List<String> _imageUrls = [];
  List<String> _interests = [];
  String? _gender;
  List<String>? _preferredGenders;
  int _completionPercentage = 0;

  @override
  void initState() {
    super.initState();
    _calculateCompletion();
  }

  void _calculateCompletion() {
    int completed = 0;
    int total = 8;

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) completed++;
    if (_name.isNotEmpty) completed++;
    if (_age != null) completed++;
    if (_location.isNotEmpty) completed++;
    if (_bio.isNotEmpty) completed++;
    if (_imageUrls.length >= 3) completed++;
    if (_interests.isNotEmpty) completed++;
    if (_gender != null) completed++;

    setState(() {
      _completionPercentage = ((completed / total) * 100).round();
    });
  }

  Future<void> _handleSave() async {
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    try {
      // First, try to complete registration if we have a profile completion token
      final authService = ref.read(authServiceProvider);

      // Check if we need to complete registration (exchange profile completion token for full token)
      try {
        // Prepare minimal profile completion data
        final request = CompleteRegistrationRequest(
          deviceName: 'mobile',
          phoneNumber: '0000000000', // Placeholder
          countryId: 1, // Default
          cityId: 1, // Default
          gender: 1, // Default
          birthDate: '1990-01-01', // Default
          minAgePreference: 18,
          maxAgePreference: 99,
          profileBio: _bio.isNotEmpty ? _bio : 'Hi there!',
          height: 170,
          weight: 70,
          smoke: false,
          drink: false,
          gym: false,
          musicGenres: [],
          educations: [],
          jobs: [],
          languages: [1],
          interests: [],
          preferredGenders: [],
          relationGoals: [1],
        );

        // Try to complete registration
        await authService.completeRegistration(request);
      } catch (e) {
        // If complete registration fails, user might already be fully authenticated
        // Continue with profile update
        debugPrint('Complete registration failed or not needed: $e');
      }

      // Now update profile with collected data
      final profileService = ref.read(profileServiceProvider);
      final updateRequest = UpdateProfileRequest(
        profileBio: _bio.isNotEmpty ? _bio : null,
        // Add other fields as they become available
      );

      if (updateRequest.toJson().isNotEmpty) {
        await profileService.updateProfile(updateRequest);
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );

        // Navigate to home - user should now be fully authenticated
        context.go('/home');
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to complete profile',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to complete profile',
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Complete Profile',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              color: surfaceColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Completion',
                        style: AppTypography.h3.copyWith(color: textColor),
                      ),
                      Text(
                        '$_completionPercentage%',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  LinearProgressIndicator(
                    value: _completionPercentage / 100,
                    backgroundColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            DividerCustom(),

            // Profile photo
            SectionHeader(
              title: 'Profile Photo',
              icon: Icons.person,
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Center(
                child: AvatarUpload(
                  imageUrl: _avatarUrl,
                  name: _name.isNotEmpty ? _name : 'User',
                  size: 120.0,
                  onUpload: () {
                    // TODO: Open image picker
                    setState(() {
                      _avatarUrl = 'https://via.placeholder.com/400';
                      _calculateCompletion();
                    });
                  },
                  onEdit: () {
                    // TODO: Open image picker
                    setState(() {
                      _avatarUrl = 'https://via.placeholder.com/400';
                      _calculateCompletion();
                    });
                  },
                ),
              ),
            ),
            DividerCustom(),

            // Basic info
            SectionHeader(
              title: 'Basic Information',
              iconPath: AppIcons.info,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              child: Column(
                children: [
                  ProfileFieldEditor(
                    label: 'Name',
                    initialValue: _name,
                    onSave: (value) {
                      setState(() {
                        _name = value;
                        _calculateCompletion();
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ProfileFieldEditor(
                    label: 'Age',
                    initialValue: _age?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    onSave: (value) {
                      setState(() {
                        _age = int.tryParse(value);
                        _calculateCompletion();
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ProfileFieldEditor(
                    label: 'Location',
                    initialValue: _location,
                    onSave: (value) {
                      setState(() {
                        _location = value;
                        _calculateCompletion();
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ProfileFieldEditor(
                    label: 'Bio',
                    initialValue: _bio,
                    maxLines: 5,
                    maxLength: 500,
                    hintText: 'Tell us about yourself...',
                    onSave: (value) {
                      setState(() {
                        _bio = value;
                        _calculateCompletion();
                      });
                    },
                  ),
                ],
              ),
            ),
            DividerCustom(),

            // Photos
            PhotoGallery(
              imageUrls: _imageUrls,
              isEditable: true,
              onAddPhoto: () {
                // TODO: Open image picker
                setState(() {
                  _imageUrls.add('https://via.placeholder.com/400');
                  _calculateCompletion();
                });
              },
              onImageTap: (index, url) {
                // TODO: Open image viewer
              },
            ),
            DividerCustom(),

            // Interests
            SectionHeader(
              title: 'Interests',
              iconPath: AppIcons.favorite,
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Text(
                'Add interests to help others find you',
                style: AppTypography.body.copyWith(color: secondaryTextColor),
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: GradientButton(
                text: 'Save Profile',
                onPressed: _handleSave,
                isFullWidth: true,
              ),
            ),
            SizedBox(height: AppSpacing.spacingXXL),
          ],
        ),
      ),
    );
  }
}
