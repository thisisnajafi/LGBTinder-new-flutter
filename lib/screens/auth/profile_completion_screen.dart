// Screen: ProfileCompletionScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_device_name.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/app_logger.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../core/responsive/responsive.dart';
import '../../features/auth/data/models/complete_registration_request.dart';
import '../../features/auth/providers/auth_service_provider.dart';
import '../../features/auth/utils/profile_completion_draft.dart';
import '../../features/profile/data/models/update_profile_request.dart';
import '../../features/profile/providers/profile_page_cache_provider.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../routes/app_router.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/profile/avatar_upload.dart';
import '../../widgets/profile/edit/profile_field_editor.dart';
import '../../widgets/profile/photo_gallery.dart';

/// Profile completion screen — paints from [profilePageCacheProvider] on open
/// (PERF-SCR-PCOMP-001). Does not await [getMyProfile] / [refresh] on first frame.
class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  ProfileCompletionDraft _draft = const ProfileCompletionDraft();
  bool _dirty = false;
  ProviderSubscription<AsyncValue<ProfilePageData>>? _cacheSub;

  @override
  void initState() {
    super.initState();
    _cacheSub = ref.listenManual(
      profilePageCacheProvider,
      (previous, next) {
        if (!mounted || _dirty) return;
        final profile = next.valueOrNull?.profile;
        if (profile == null) return;
        setState(() {
          _draft = ProfileCompletionDraft.fromProfile(profile);
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _cacheSub?.close();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_draft.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      try {
        final request = CompleteRegistrationRequest(
          deviceName: await AppDeviceName.resolve(),
          phoneNumber: '0000000000',
          countryId: 1,
          cityId: 1,
          gender: 1,
          birthDate: '1990-01-01',
          minAgePreference: 18,
          maxAgePreference: 99,
          profileBio: _draft.bio.isNotEmpty ? _draft.bio : 'Hi there!',
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
        await authService.completeRegistration(request);
      } catch (e) {
        AppLogger.warning(
          'Complete registration failed or not needed: $e',
          tag: 'Auth',
        );
      }

      final profileService = ref.read(profileServiceProvider);
      final updateRequest = UpdateProfileRequest(
        profileBio: _draft.bio.isNotEmpty ? _draft.bio : null,
      );

      if (updateRequest.toJson().isNotEmpty) {
        await profileService.updateProfile(updateRequest);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
        context.go(AppRoutes.home);
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
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final percent = _draft.percent;

    return AppPageScaffold(
      title: 'Complete Profile',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
              color: surfaceColor,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppText(
                          'Profile Completion',
                          style: AppTypography.h3.copyWith(color: textColor),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentPurple,
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            const DividerCustom(),
            SectionHeader(
              title: 'Profile Photo',
              iconPath: AppIcons.user,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
              child: Center(
                child: AvatarUpload(
                  imageUrl: _draft.avatarUrl,
                  name: _draft.name.isNotEmpty ? _draft.name : 'User',
                  size: 120.0,
                  onUpload: () {},
                  onEdit: () {},
                ),
              ),
            ),
            const DividerCustom(),
            SectionHeader(
              title: 'Basic Information',
              iconPath: AppIcons.info,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              child: Column(
                children: [
                  ProfileFieldEditor(
                    label: 'Name',
                    initialValue: _draft.name,
                    onSave: (value) {
                      setState(() {
                        _dirty = true;
                        _draft = _draft.copyWith(name: value);
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ProfileFieldEditor(
                    label: 'Age',
                    initialValue: _draft.age?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    onSave: (value) {
                      setState(() {
                        _dirty = true;
                        _draft = _draft.copyWith(age: int.tryParse(value));
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ProfileFieldEditor(
                    label: 'Location',
                    initialValue: _draft.location,
                    onSave: (value) {
                      setState(() {
                        _dirty = true;
                        _draft = _draft.copyWith(location: value);
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  ProfileFieldEditor(
                    label: 'Bio',
                    initialValue: _draft.bio,
                    maxLines: 5,
                    maxLength: 500,
                    hintText: 'Tell us about yourself...',
                    onSave: (value) {
                      setState(() {
                        _dirty = true;
                        _draft = _draft.copyWith(bio: value);
                      });
                    },
                  ),
                ],
              ),
            ),
            const DividerCustom(),
            PhotoGallery(
              imageUrls: _draft.imageUrls,
              isEditable: true,
              onAddPhoto: () {},
              onImageTap: (index, url) {},
            ),
            const DividerCustom(),
            SectionHeader(
              title: 'Interests',
              iconPath: AppIcons.favorite,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
              child: Text(
                'Add interests to help others find you',
                style: AppTypography.body.copyWith(color: secondaryTextColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
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
