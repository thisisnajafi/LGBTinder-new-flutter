// Screen: ProfileWizardPage
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/animation_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/api_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_haptics.dart';
import '../core/utils/app_media_picker.dart';
import '../core/utils/country_phone_utils.dart';
import '../core/utils/image_upload_compressor.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/auth/data/models/check_token_response.dart';
import '../features/auth/data/models/complete_registration_request.dart';
import '../features/auth/providers/auth_service_provider.dart';
import '../features/onboarding/utils/finish_onboarding_navigation.dart';
import '../features/onboarding/widgets/onboarding_celebration_screen.dart';
import '../features/onboarding/widgets/onboarding_progress_indicator.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/providers/profile_wizard_provider.dart';
import '../features/profile/providers/wizard_reference_cache_provider.dart';
import '../features/reference_data/data/models/reference_item.dart';
import '../routes/app_router.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/profile/profile_photo_source_sheet.dart';
import '../widgets/profile/wizard/wizard_step_about.dart';
import '../widgets/profile/wizard/wizard_step_basic_info.dart';
import '../widgets/profile/wizard/wizard_step_gallery.dart';
import '../widgets/profile/wizard/wizard_step_interests.dart';
import '../widgets/profile/wizard/wizard_step_photos.dart';
import '../widgets/profile/wizard/wizard_step_preferences.dart';
import '../widgets/profile/wizard/wizard_step_review.dart';

/// Profile wizard page - Step-by-step profile setup for new users
class ProfileWizardPage extends ConsumerStatefulWidget {
  final String? initialFirstName;
  final String? initialLastName;

  const ProfileWizardPage({
    super.key,
    this.initialFirstName,
    this.initialLastName,
  });

  @override
  ConsumerState<ProfileWizardPage> createState() => _ProfileWizardPageState();
}

class _ProfileWizardPageState extends ConsumerState<ProfileWizardPage> {
  final PageController _pageController = PageController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _profileSubmissionComplete = false;

  ProfileWizardState get _draft => ref.read(profileWizardProvider);

  ProfileWizardNotifier get _wizard => ref.read(profileWizardProvider.notifier);

  @override
  void initState() {
    super.initState();
    _countryCodeController.text = '+1';
    _nameController.addListener(_syncNameFromController);
    _bioController.addListener(_syncBioFromController);
    _prefillRegistrationName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRegisteredNameFromSession();
      _loadUserProfile();
      _verifyProfileNotAlreadyComplete();
    });
  }

  void _syncNameFromController() {
    _wizard.setName(_nameController.text);
  }

  void _syncBioFromController() {
    _wizard.setBio(_bioController.text);
  }

  void _flushControllersToDraft() {
    _wizard.setName(_nameController.text);
    _wizard.setBio(_bioController.text);
  }

  void _prefillRegistrationName() {
    if (_draft.name.trim().isNotEmpty) return;
    final parts = <String>[
      if (widget.initialFirstName?.trim().isNotEmpty == true)
        widget.initialFirstName!.trim(),
      if (widget.initialLastName?.trim().isNotEmpty == true)
        widget.initialLastName!.trim(),
    ];
    if (parts.isEmpty) return;
    final fullName = parts.join(' ');
    _nameController.text = fullName;
    _wizard.setName(fullName);
  }

  Future<void> _loadRegisteredNameFromSession() async {
    if (_draft.name.trim().isNotEmpty) return;
    try {
      final session = await ref
          .read(tokenStorageServiceProvider)
          .getUserSession();
      if (session == null || !mounted) return;
      final first = session.user.firstName.trim();
      final last = session.user.lastName.trim();
      if (first.isEmpty || first == 'User') return;
      final fullName = last.isNotEmpty ? '$first $last' : first;
      _nameController.text = fullName;
      _wizard.setName(fullName);
    } catch (_) {
      // Non-fatal — registration name may come from route params instead.
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncNameFromController);
    _bioController.removeListener(_syncBioFromController);
    _pageController.dispose();
    _countryCodeController.dispose();
    _phoneNumberController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _verifyProfileNotAlreadyComplete() async {
    try {
      final authService = ref.read(authServiceProvider);
      final state = await authService.checkToken();
      await authService.syncBootstrapSession(state);
      if (!mounted || !state.isComplete) return;
      context.go(AppRoutes.home);
    } catch (_) {
      // Non-fatal — user can continue the wizard if the check fails offline.
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getMyProfile();
      if (!mounted) return;

      final nameAlreadySet = _draft.name.trim().isNotEmpty;
      _wizard.applyFromProfile(profile, nameAlreadySet: nameAlreadySet);

      final draft = _draft;
      if (_nameController.text != draft.name) {
        _nameController.text = draft.name;
      }
      if (_bioController.text != draft.bio) {
        _bioController.text = draft.bio;
      }

      if (profile.phoneNumber != null &&
          profile.phoneNumber!.trim().isNotEmpty) {
        try {
          final iso = draft.selectedCountry != null
              ? CountryPhoneUtils.resolveIso(country: draft.selectedCountry)
              : CountryPhoneUtils.isoFromDialCode(draft.countryCode);
          final parsed = CountryPhoneUtils.parseInternational(
            profile.phoneNumber!,
            hintIso: iso,
          );
          _wizard.setPhone(
            phoneNumber: parsed.e164,
            countryCode: parsed.dialCode,
          );
          _countryCodeController.text = parsed.dialCode;
          _phoneNumberController.text = parsed.formattedNational;
        } catch (_) {
          _wizard.setPhone(phoneNumber: profile.phoneNumber!.trim());
          _phoneNumberController.text = profile.phoneNumber!.trim();
        }
      }

      _applyResumeStep(_wizard.resolveResumeStep());
    } catch (e) {
      // Silently fail - user might not have a profile yet or not authenticated
    }
  }

  void _applyResumeStep(int step) {
    if (!mounted || step <= 0) return;
    _currentStep = step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(step);
    });
  }

  Duration _pageDuration() {
    return AppAnimations.animationsEnabled(context)
        ? AppAnimations.transitionPage
        : Duration.zero;
  }

  void _showStepError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.feedbackError,
      ),
    );
  }

  String? _validateCurrentStep() {
    final draft = _draft;
    switch (_currentStep) {
      case 0:
        if (!draft.hasProfilePhoto) {
          return 'Please upload a profile photo';
        }
        return null;
      case 1:
        if (_phoneFormKey.currentState != null &&
            !_phoneFormKey.currentState!.validate()) {
          return '';
        }
        if (draft.countryId == null) return 'Please select your country';
        if (draft.cityId == null) return 'Please select your city';
        if (draft.genderId == null) return 'Please select your gender';
        if (draft.birthDate == null) return 'Please select your birth date';
        return null;
      case 2:
        if (draft.bio.isEmpty) return 'Please enter your bio';
        if (draft.educations.isEmpty) {
          return 'Please select one education level';
        }
        if (draft.jobs.isEmpty) return 'Please select one job';
        if (draft.languages.isEmpty) {
          return 'Please select at least one language';
        }
        return null;
      case 3:
        if (draft.preferredGenders.isEmpty) {
          return 'Please select at least one preferred gender';
        }
        if (draft.relationGoals.isEmpty) {
          return 'Please select at least one relationship goal';
        }
        if (draft.minAgePreference >= draft.maxAgePreference) {
          return 'Max age preference must be greater than min age preference';
        }
        return null;
      case 4:
        if (draft.interestsIds.isEmpty) {
          return 'Please select at least one interest';
        }
        if (draft.interestsIds.length > 10) {
          return 'You can select up to 10 interests';
        }
        if (draft.musicGenres.isEmpty) {
          return 'Please select at least one music genre';
        }
        return null;
      default:
        return null;
    }
  }

  String? _validateComplete(ProfileWizardState draft) {
    if (!draft.hasProfilePhoto) return 'Please upload a profile photo';
    if (draft.phoneNumber.isEmpty) return 'Please enter your phone number';
    if (draft.phoneNumber.isNotEmpty) {
      final iso = CountryPhoneUtils.resolveIso(
        country: draft.selectedCountry,
        dialCode: draft.countryCode,
      );
      final phoneError = CountryPhoneUtils.validateNational(
        _phoneNumberController.text,
        iso,
      );
      if (phoneError != null) return phoneError;
    }
    if (draft.countryId == null ||
        draft.cityId == null ||
        draft.genderId == null ||
        draft.birthDate == null) {
      return 'Please complete all required fields';
    }
    if (draft.bio.isEmpty) return 'Please enter your bio';
    if (draft.educations.isEmpty) return 'Please select one education level';
    if (draft.jobs.isEmpty) return 'Please select one job';
    if (draft.languages.isEmpty) return 'Please select at least one language';
    if (draft.preferredGenders.isEmpty) {
      return 'Please select at least one preferred gender';
    }
    if (draft.relationGoals.isEmpty) {
      return 'Please select at least one relationship goal';
    }
    if (draft.musicGenres.isEmpty) {
      return 'Please select at least one music genre';
    }
    if (draft.interestsIds.isEmpty) {
      return 'Please select at least one interest';
    }
    if (draft.minAgePreference >= draft.maxAgePreference) {
      return 'Max age preference must be greater than min age preference';
    }
    return null;
  }

  void _nextStep() {
    _flushControllersToDraft();
    final error = _validateCurrentStep();
    if (error != null) {
      if (error.isNotEmpty) _showStepError(error);
      return;
    }

    if (_currentStep < 6) {
      AppHaptics.light();
      _pageController.nextPage(
        duration: _pageDuration(),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeWizard();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      AppHaptics.selection();
      _pageController.previousPage(
        duration: _pageDuration(),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (e) {
      // Fallback if device info fails
    }
    return 'Unknown Device';
  }

  Future<void> _exitWizardToDiscover() async {
    await finishProfileOnboardingAndGoHome(
      ref,
      context,
      profileSubmissionComplete: _profileSubmissionComplete,
    );
  }

  Future<void> _pickImage(ImageSource source, {bool isPrimary = false}) async {
    try {
      final XFile? image = await AppMediaPicker.pickImage(source: source);
      if (image == null) return;
      final file = File(image.path);
      if (isPrimary || _currentStep == 0) {
        _wizard.setPrimaryPhoto(file);
        return;
      }
      if (_draft.remainingGallerySlots <= 0) {
        if (mounted) {
          _showStepError(
            'You can add up to ${ProfileWizardState.maxAdditionalPhotos} gallery photos.',
          );
        }
        return;
      }
      _wizard.addGalleryFiles([
        file,
      ], maxPhotos: ProfileWizardState.maxAdditionalPhotos);
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to pick image',
        );
      }
    }
  }

  Future<void> _pickAdditionalImages(ImageSource source) async {
    final remaining = _draft.remainingGallerySlots;
    if (remaining <= 0) {
      if (mounted) {
        _showStepError(
          'You can add up to ${ProfileWizardState.maxAdditionalPhotos} gallery photos '
          '(${AppConstants.maxTotalProfilePhotos} total including primary).',
        );
      }
      return;
    }

    try {
      if (source == ImageSource.gallery) {
        final images = await AppMediaPicker.pickMultiImage(
          limit: remaining,
        );
        if (images.isEmpty || !mounted) return;
        _wizard.addGalleryFiles(
          images.map((image) => File(image.path)),
          maxPhotos: ProfileWizardState.maxAdditionalPhotos,
        );
        AppHaptics.light();
        return;
      }

      await _pickImage(source, isPrimary: false);
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to pick images',
        );
      }
    }
  }

  Future<({File? primaryImage, List<File> galleryImages})>
  _prepareRegistrationMedia() async {
    final draft = _draft;
    final uploadPrimary =
        draft.primaryImageFile != null && !draft.primaryAlreadyUploaded;
    var galleryFiles = List<File>.from(draft.additionalImageFiles);
    final remainingSlots =
        ProfileWizardState.maxAdditionalPhotos - draft.existingGalleryCount;

    if (galleryFiles.length > remainingSlots) {
      galleryFiles = galleryFiles.take(remainingSlots).toList();
    }

    File? primaryImage;
    if (uploadPrimary && draft.primaryImageFile != null) {
      primaryImage = await ImageUploadCompressor.prepareForUpload(
        draft.primaryImageFile!,
      );
    }

    final galleryImages = <File>[];
    for (final file in galleryFiles) {
      galleryImages.add(await ImageUploadCompressor.prepareForUpload(file));
    }

    return (primaryImage: primaryImage, galleryImages: galleryImages);
  }

  List<String> _celebrationPhotoSources(ProfileWizardState draft) {
    final uploaded = draft.uploadedImages
        .map((image) => image.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();
    if (uploaded.isNotEmpty) return uploaded;

    final local = <String>[];
    if (draft.primaryImageFile != null) {
      local.add(draft.primaryImageFile!.path);
    }
    local.addAll(draft.additionalImageFiles.map((file) => file.path));
    if (local.isNotEmpty) return local;

    if (draft.avatarUrl != null && draft.avatarUrl!.isNotEmpty) {
      return [draft.avatarUrl!];
    }
    return const [];
  }

  String? _celebrationLocation(ProfileWizardState draft) {
    final refs = ref.read(wizardReferenceCacheProvider);
    final countries = refs.countries.valueOrNull ?? [];
    final cities = ref.read(wizardCitiesProvider).valueOrNull ?? [];

    final country = countries.firstWhere(
      (item) => item.id == draft.countryId,
      orElse: () => ReferenceItem(id: -1, title: ''),
    );
    final city = cities.firstWhere(
      (item) => item.id == draft.cityId,
      orElse: () => ReferenceItem(id: -1, title: ''),
    );

    final parts = <String>[
      if (city.id != -1 && city.title.isNotEmpty) city.title,
      if (country.id != -1 && country.title.isNotEmpty) country.title,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _celebrationRelationshipGoal(ProfileWizardState draft) {
    final goals =
        ref.read(wizardReferenceCacheProvider).relationGoals.valueOrNull ?? [];
    for (final goalId in draft.relationGoals) {
      final match = goals.where((goal) => goal.id == goalId).toList();
      if (match.isNotEmpty && match.first.title.isNotEmpty) {
        return match.first.title;
      }
    }
    return null;
  }

  Future<void> _completeWizard() async {
    if (_profileSubmissionComplete) {
      await _exitWizardToDiscover();
      return;
    }

    _flushControllersToDraft();

    if (_phoneFormKey.currentState != null &&
        !_phoneFormKey.currentState!.validate()) {
      return;
    }

    final draft = _draft;
    final errorMessage = _validateComplete(draft);
    if (errorMessage != null) {
      _showStepError(errorMessage);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final media = await _prepareRegistrationMedia();
      final latest = _draft;

      final authService = ref.read(authServiceProvider);
      final deviceName = await _getDeviceName();

      final rawCountryCode = _countryCodeController.text.trim().isNotEmpty
          ? _countryCodeController.text.trim()
          : (latest.countryCode ??
                CountryPhoneUtils.dialCodeForCountry(latest.selectedCountry));
      final normalizedCountryCode = CountryPhoneUtils.normalizeDialCode(
        rawCountryCode,
      );
      final iso = CountryPhoneUtils.resolveIso(
        country: latest.selectedCountry,
        dialCode: normalizedCountryCode,
      );
      final parsedPhone = CountryPhoneUtils.tryBuildFromNational(
        nationalInput: _phoneNumberController.text,
        iso: iso,
        dialCode: normalizedCountryCode,
      );
      final formattedPhone =
          parsedPhone?.e164 ??
          (latest.phoneNumber.startsWith('+')
              ? latest.phoneNumber
              : '$normalizedCountryCode${CountryPhoneUtils.digitsOnly(latest.phoneNumber)}');

      final birthDateString = latest.birthDate!.toIso8601String().split('T')[0];

      final request = CompleteRegistrationRequest(
        deviceName: deviceName,
        phoneNumber: formattedPhone,
        countryId: latest.countryId!,
        cityId: latest.cityId!,
        gender: latest.genderId!,
        birthDate: birthDateString,
        minAgePreference: latest.minAgePreference,
        maxAgePreference: latest.maxAgePreference,
        profileBio: latest.bio,
        height: latest.height,
        weight: latest.weight,
        smoke: latest.smoke,
        drink: latest.drink,
        gym: latest.gym,
        musicGenres: latest.musicGenres,
        educations: latest.educations,
        jobs: latest.jobs,
        languages: latest.languages,
        interests: latest.interestsIds,
        preferredGenders: latest.preferredGenders,
        relationGoals: latest.relationGoals,
      );

      final response = await authService.completeRegistration(
        request,
        primaryImage: media.primaryImage,
        galleryImages: media.galleryImages,
      );

      if (mounted) {
        _wizard.clearLocalImages();
      }

      CheckTokenResponse? tokenState;
      try {
        tokenState = await authService.checkToken();
        await authService.syncBootstrapSession(tokenState);
      } catch (_) {
        // Fall back to complete-registration payload when offline.
      }

      final isComplete = tokenState?.isComplete ?? response.profileCompleted;
      _profileSubmissionComplete = true;

      if (isComplete && mounted) {
        await _exitWizardToDiscover();
        return;
      }

      if (mounted) {
        final celebrationDraft = _draft;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => OnboardingCelebrationScreen(
              displayName: celebrationDraft.name.isNotEmpty
                  ? celebrationDraft.name
                  : 'You',
              age: celebrationDraft.age,
              location: _celebrationLocation(celebrationDraft),
              bio: celebrationDraft.bio.isNotEmpty
                  ? celebrationDraft.bio
                  : null,
              relationshipGoal: _celebrationRelationshipGoal(celebrationDraft),
              heightCm: celebrationDraft.height,
              photoSources: _celebrationPhotoSources(celebrationDraft),
              topInterests: celebrationDraft.selectedInterestTitles
                  .take(6)
                  .toList(),
            ),
          ),
        );
      }
    } on ApiError catch (e) {
      if (mounted &&
          e.message.toLowerCase().contains('profile completion ability')) {
        try {
          final state = await ref.read(authServiceProvider).checkToken();
          await ref.read(authServiceProvider).syncBootstrapSession(state);
          if (state.isComplete && mounted) {
            context.go(AppRoutes.home);
            return;
          }
        } catch (_) {}
      }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumDetailScaffold(
      title: formatSettingsTitle('Setup Profile'),
      subtitle: 'Step ${_currentStep + 1} of 7',
      onBack: _currentStep > 0 ? _previousStep : () => context.pop(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSettingsLayout.horizontalPadding,
              AppSpacing.spacingXL,
              AppSettingsLayout.horizontalPadding,
              AppSpacing.spacingSM,
            ),
            child: OnboardingProgressIndicator(
              currentStep: _currentStep,
              totalSteps: 7,
              style: OnboardingProgressStyle.segmentedBar,
              stepTitles: const [
                'Profile Photo',
                'Basic Info',
                'About You',
                'Preferences & Lifestyle',
                'Interests & Music',
                'Additional Photos',
                'Review',
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
                AppHaptics.selection();
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                RepaintBoundary(
                  key: WizardStepPhotos.pageKey,
                  child: WizardStepPhotos(
                    onPickPhoto: () => _showImageSourceDialog(isPrimary: true),
                  ),
                ),
                RepaintBoundary(
                  key: WizardStepBasicInfo.pageKey,
                  child: WizardStepBasicInfo(
                    nameController: _nameController,
                    phoneFormKey: _phoneFormKey,
                    phoneNumberController: _phoneNumberController,
                    countryCodeController: _countryCodeController,
                  ),
                ),
                RepaintBoundary(
                  key: WizardStepAbout.pageKey,
                  child: WizardStepAbout(bioController: _bioController),
                ),
                const RepaintBoundary(
                  key: WizardStepPreferences.pageKey,
                  child: WizardStepPreferences(),
                ),
                const RepaintBoundary(
                  key: WizardStepInterests.pageKey,
                  child: WizardStepInterests(),
                ),
                RepaintBoundary(
                  key: WizardStepGallery.pageKey,
                  child: WizardStepGallery(
                    onPickPhotos: () =>
                        _showImageSourceDialog(isPrimary: false),
                  ),
                ),
                const RepaintBoundary(
                  key: WizardStepReview.pageKey,
                  child: WizardStepReview(),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight,
              border: Border(
                top: BorderSide(
                  color: AppColors.accentViolet.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.spacingMD,
                          ),
                          side: BorderSide(color: AppColors.accentPurple),
                        ),
                        child: Text(
                          'Back',
                          style: AppTypography.button.copyWith(
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: GradientButton(
                      text: _currentStep == 6
                          ? (_profileSubmissionComplete
                                ? 'Start Discovering'
                                : 'Complete')
                          : 'Next',
                      onPressed: _isLoading
                          ? null
                          : (_currentStep == 6 ? _completeWizard : _nextStep),
                      isLoading: _isLoading && _currentStep == 6,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog({required bool isPrimary}) {
    FocusScope.of(context).unfocus();

    ProfilePhotoSourceSheet.show(
      context,
      title: isPrimary ? 'Profile photo' : 'Additional photos',
      gallerySubtitle: isPrimary
          ? 'Pick an existing photo'
          : 'Select one or more photos at once',
      onSourceSelected: (source) => isPrimary
          ? _pickImage(source, isPrimary: true)
          : _pickAdditionalImages(source),
    );
  }

  @visibleForTesting
  int get testCurrentStep => _currentStep;

  @visibleForTesting
  void testJumpToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.jumpToPage(step);
  }

  @visibleForTesting
  void testSeedPrimaryPhoto(File file) {
    _wizard.setPrimaryPhoto(file);
  }

  @visibleForTesting
  void testSeedStep1Phone({
    String countryCode = '+1',
    String phone = '5551234567',
  }) {
    _countryCodeController.text = countryCode;
    _phoneNumberController.text = phone;
    _wizard.setPhone(phoneNumber: phone, countryCode: countryCode);
  }

  @visibleForTesting
  void testSeedCompleteState(File photo) {
    _wizard.seedCompleteForTests(
      photo: photo,
      name: 'Alex User',
      phoneNumber: '5551234567',
      countryCode: '+1',
      bio: 'Bio text for tests',
    );
    _nameController.text = 'Alex User';
    _bioController.text = 'Bio text for tests';
    testSeedStep1Phone();
    testJumpToStep(6);
  }
}
