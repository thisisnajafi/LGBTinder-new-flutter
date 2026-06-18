// Screen: ProfileWizardPage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/cache/cache_providers.dart';
import '../core/constants/animation_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/widgets/app_page_scaffold.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/app_grouped_list_card.dart';
import '../widgets/profile/profile_wizard_layout.dart';
import '../widgets/profile/avatar_upload.dart';
import '../features/profile/data/models/user_image.dart';
import '../widgets/profile/edit/profile_section_editor.dart';
import '../core/utils/app_icons.dart';
import '../widgets/common/selection_bottom_sheet.dart';
import '../widgets/common/reference_bottom_sheet_field.dart';
import '../widgets/buttons/gradient_button.dart';
import '../features/auth/providers/auth_service_provider.dart';
import '../features/auth/data/models/complete_registration_request.dart';
import '../features/profile/providers/profile_providers.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import '../features/onboarding/widgets/onboarding_progress_indicator.dart';
import '../features/onboarding/widgets/onboarding_celebration_screen.dart';
import '../core/utils/app_haptics.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../features/reference_data/data/models/reference_item.dart';

/// Profile wizard page - Step-by-step profile setup for new users
class ProfileWizardPage extends ConsumerStatefulWidget {
  final String? initialFirstName;
  
  const ProfileWizardPage({Key? key, this.initialFirstName}) : super(key: key);

  @override
  ConsumerState<ProfileWizardPage> createState() => _ProfileWizardPageState();
}

class _ProfileWizardPageState extends ConsumerState<ProfileWizardPage> {
  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _interestSearchController = TextEditingController();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  
  // Form data
  String? _avatarUrl;
  File? _primaryImageFile;
  List<File> _additionalImageFiles = [];
  List<UserImage> _uploadedImages = [];
  String _name = '';
  int? _age;
  String _location = '';
  String _bio = '';
  List<String> _interests = [];
  List<String> _selectedInterests = [];
  
  // Required fields for API
  String _phoneNumber = '';
  String? _countryCode;
  int? _countryId;
  int? _cityId;
  int? _genderId;
  DateTime? _birthDate;
  
  // Required fields (all must be set)
  int _minAgePreference = 18;
  int _maxAgePreference = 30;
  int _height = 170;
  int _weight = 70;
  bool _smoke = false;
  bool _drink = false;
  bool _gym = false;
  List<int> _musicGenres = [];
  List<int> _educations = [];
  List<int> _jobs = [];
  List<int> _languages = [];
  List<int> _interestsIds = [];
  List<int> _preferredGenders = [];
  List<int> _relationGoals = [];

  String _interestSearchQuery = '';

  void _onInterestSearchChanged() {
    setState(() {
      _interestSearchQuery = _interestSearchController.text;
    });
  }

  @override
  void initState() {
    super.initState();
    _countryCodeController.text = _countryCode ?? '+1';
    _phoneNumberController.text = _phoneNumber;
    // Pre-fill name from login response if provided
    if (widget.initialFirstName != null && widget.initialFirstName!.isNotEmpty) {
      _name = widget.initialFirstName!;
      _nameController.text = _name;
    }
    // Load user profile data to pre-fill fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
    _interestSearchController.addListener(_onInterestSearchChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countryCodeController.dispose();
    _phoneNumberController.dispose();
    _nameController.dispose();
    _interestSearchController
      ..removeListener(_onInterestSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getMyProfile();
      
    if (mounted && profile != null) {
        setState(() {
          // Pre-fill name from existing profile (only if not already set from login)
          if (_name.isEmpty && (profile.firstName.isNotEmpty || profile.lastName.isNotEmpty)) {
            _name = '${profile.firstName} ${profile.lastName}'.trim();
            _nameController.text = _name;
          }
          if ((_countryCode == null || _countryCode!.isEmpty) && profile.countryId != null) {
            // Attempt to derive country code later when countries load
            _countryCode = _countryCodeController.text.isNotEmpty
                ? _countryCodeController.text
                : _countryCode;
          }
          // Pre-fill other fields if they exist
          if (profile.profileBio != null && profile.profileBio!.isNotEmpty) {
            _bio = profile.profileBio!;
          }
          if (profile.countryId != null) {
            _countryId = profile.countryId;
          }
          if (profile.cityId != null) {
            _cityId = profile.cityId;
          }
          if (profile.genderId != null) {
            _genderId = profile.genderId;
          }
          if (profile.birthDate != null && profile.birthDate!.isNotEmpty) {
            try {
              _birthDate = DateTime.parse(profile.birthDate!);
              final today = DateTime.now();
              _age = today.year - _birthDate!.year;
              if (today.month < _birthDate!.month ||
                  (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
                _age = _age! - 1;
              }
            } catch (e) {
              // Ignore date parsing errors
            }
          }
          if (profile.height != null) {
            _height = profile.height!;
          }
          if (profile.weight != null) {
            _weight = profile.weight!;
          }
          if (profile.smoke != null) {
            _smoke = profile.smoke!;
          }
          if (profile.drink != null) {
            _drink = profile.drink!;
          }
          if (profile.gym != null) {
            _gym = profile.gym!;
          }
          if (profile.minAgePreference != null) {
            _minAgePreference = profile.minAgePreference!;
          }
          if (profile.maxAgePreference != null) {
            _maxAgePreference = profile.maxAgePreference!;
          }
          if (profile.musicGenres != null && profile.musicGenres!.isNotEmpty) {
            _musicGenres = profile.musicGenres!;
          }
          if (profile.educations != null && profile.educations!.isNotEmpty) {
            _educations = [profile.educations!.first]; // Single selection only
          }
          if (profile.jobs != null && profile.jobs!.isNotEmpty) {
            _jobs = [profile.jobs!.first]; // Single selection only
          }
          if (profile.languages != null && profile.languages!.isNotEmpty) {
            _languages = profile.languages!;
          }
          if (profile.interests != null && profile.interests!.isNotEmpty) {
            _interestsIds = profile.interests!;
          }
          if (profile.preferredGenders != null && profile.preferredGenders!.isNotEmpty) {
            _preferredGenders = profile.preferredGenders!;
          }
          if (profile.relationGoals != null && profile.relationGoals!.isNotEmpty) {
            _relationGoals = profile.relationGoals!;
          }
          // Load primary image if exists
          if (profile.images != null && profile.images!.isNotEmpty) {
            final primaryImage = profile.images!.firstWhere(
              (img) => img.isPrimary,
              orElse: () => profile.images!.first,
            );
            _avatarUrl = primaryImage.imageUrl;
          }
        });
      }
    } catch (e) {
      // Silently fail - user might not have a profile yet or not authenticated
      // This is expected for new users
    }
  }

  // Validation methods
  String? _validateCountryCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country code is required';
    }
    
    final normalized = value.trim();
    final countryCodeRegex = RegExp(r'^\+[1-9]\d{0,3}$');
    
    if (!countryCodeRegex.hasMatch(normalized)) {
      return 'Please enter a valid country code (e.g., +1, +44, +91)';
    }
    
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces, dashes, parentheses, and other formatting characters
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    // Phone number should contain only digits and be 7-15 digits long
    final phoneRegex = RegExp(r'^\d{7,15}$');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number (7-15 digits)';
    }
    
    return null;
  }

  void _nextStep() {
    // Validate step before proceeding
    if (_currentStep == 0 && _primaryImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a profile photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate Step 2 (Basic Information & Contact)
    if (_currentStep == 1) {
      // Validate phone form (if it exists)
      if (_phoneFormKey.currentState != null && !_phoneFormKey.currentState!.validate()) {
        return;
      }
      if (_countryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your country'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_cityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your city'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_genderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your gender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your birth date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Validate Step 3 (About You)
    if (_currentStep == 2) {
      if (_bio.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your bio'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_educations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select one education level'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_jobs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select one job'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_languages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one language'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Validate Step 4 (Preferences & Lifestyle)
    if (_currentStep == 3) {
      if (_preferredGenders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one preferred gender'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_relationGoals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one relationship goal'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_minAgePreference >= _maxAgePreference) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max age preference must be greater than min age preference'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Validate Step 5 (Interests & Music)
    if (_currentStep == 4) {
      if (_interestsIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one interest'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_interestsIds.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can select up to 10 interests'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_musicGenres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one music genre'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    if (_currentStep < 6) {
      AppHaptics.light();
      _pageController.nextPage(
        duration: AppAnimations.transitionPage,
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
        duration: AppAnimations.transitionPage,
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

  Future<void> _pickImage(ImageSource source, {bool isPrimary = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        final file = File(image.path);
        if (isPrimary || _currentStep == 0) {
          // Primary photo
          setState(() {
            _primaryImageFile = file;
            _avatarUrl = file.path; // Temporary local path for preview
          });
        } else {
          // Additional photos
          setState(() {
            _additionalImageFiles.add(file);
          });
        }
      }
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

  Future<void> _uploadAllImages() async {
    if (_primaryImageFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageService = ref.read(imageServiceProvider);
      
      // Upload primary image
      final primaryImage = await imageService.uploadImage(_primaryImageFile!, type: 'primary');
      _uploadedImages.add(primaryImage);
      
      // Set as primary (already set during upload, but ensure it's marked)
      // Profile pictures are automatically set as primary on upload if is_primary is true
      
      // Upload additional images
      for (var imageFile in _additionalImageFiles) {
        try {
          final uploadedImage = await imageService.uploadImage(imageFile, type: 'gallery');
          _uploadedImages.add(uploadedImage);
        } catch (e) {
          // Continue with other images even if one fails
          if (mounted) {
            ErrorHandlerService.showErrorSnackBar(
              context,
              e is ApiError ? e : ApiError(message: e.toString()),
              customMessage: 'Failed to upload one image, continuing...',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e is ApiError ? e : ApiError(message: e.toString()),
          customMessage: 'Failed to upload images',
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  List<String> _celebrationPhotoSources() {
    final uploaded = _uploadedImages
        .map((image) => image.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();
    if (uploaded.isNotEmpty) return uploaded;

    final local = <String>[];
    if (_primaryImageFile != null) {
      local.add(_primaryImageFile!.path);
    }
    local.addAll(_additionalImageFiles.map((file) => file.path));
    if (local.isNotEmpty) return local;

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return [_avatarUrl!];
    }
    return const [];
  }

  String? _celebrationLocation() {
    final countries = ref.read(countriesProvider).valueOrNull ?? [];
    final cities = _countryId != null
        ? ref.read(citiesProvider(_countryId!)).valueOrNull ?? []
        : <ReferenceItem>[];

    final country = countries.firstWhere(
      (item) => item.id == _countryId,
      orElse: () => ReferenceItem(id: -1, title: ''),
    );
    final city = cities.firstWhere(
      (item) => item.id == _cityId,
      orElse: () => ReferenceItem(id: -1, title: ''),
    );

    final parts = <String>[
      if (city.id != -1 && city.title.isNotEmpty) city.title,
      if (country.id != -1 && country.title.isNotEmpty) country.title,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _celebrationRelationshipGoal() {
    final goals = ref.read(relationshipGoalsProvider).valueOrNull ?? [];
    for (final goalId in _relationGoals) {
      final match = goals.where((goal) => goal.id == goalId).toList();
      if (match.isNotEmpty && match.first.title.isNotEmpty) {
        return match.first.title;
      }
    }
    return null;
  }

  Future<void> _completeWizard() async {
    if (_phoneFormKey.currentState != null && !_phoneFormKey.currentState!.validate()) {
      return;
    }
    
    // Validate required fields
    String? errorMessage;
    
    // Check profile photo
    if (_primaryImageFile == null && _avatarUrl == null) {
      errorMessage = 'Please upload a profile photo';
    }
    
    // Check phone number
    if (errorMessage == null && _phoneNumber.isEmpty) {
      errorMessage = 'Please enter your phone number';
    }
    
    // Validate phone number format
    if (errorMessage == null && _phoneNumber.isNotEmpty) {
      final phoneError = _validatePhoneNumber(_phoneNumber);
      if (phoneError != null) {
        errorMessage = phoneError;
      }
    }
    
    // Validate country code format
    if (errorMessage == null) {
      final countryCodeError = _validateCountryCode(_countryCodeController.text);
      if (countryCodeError != null) {
        errorMessage = countryCodeError;
      }
    }
    
    // Check required basic fields
    if (errorMessage == null && (_countryId == null || _cityId == null || _genderId == null || _birthDate == null)) {
      errorMessage = 'Please complete all required fields';
    }
    
    // Check bio
    if (errorMessage == null && _bio.isEmpty) {
      errorMessage = 'Please enter your bio';
    }
    
    // Check educations (single selection)
    if (errorMessage == null && _educations.isEmpty) {
      errorMessage = 'Please select one education level';
    }
    
    // Check jobs (single selection)
    if (errorMessage == null && _jobs.isEmpty) {
      errorMessage = 'Please select one job';
    }
    
    // Check languages
    if (errorMessage == null && _languages.isEmpty) {
      errorMessage = 'Please select at least one language';
    }
    
    // Check preferred genders
    if (errorMessage == null && _preferredGenders.isEmpty) {
      errorMessage = 'Please select at least one preferred gender';
    }
    
    // Check relationship goals
    if (errorMessage == null && _relationGoals.isEmpty) {
      errorMessage = 'Please select at least one relationship goal';
    }
    
    // Check music genres
    if (errorMessage == null && _musicGenres.isEmpty) {
      errorMessage = 'Please select at least one music genre';
    }
    
    // Check interests
    if (errorMessage == null && _interestsIds.isEmpty) {
      errorMessage = 'Please select at least one interest';
    }
    
    // Check age preference
    if (errorMessage == null && _minAgePreference >= _maxAgePreference) {
      errorMessage = 'Max age preference must be greater than min age preference';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First upload all images
      await _uploadAllImages();

      // Then complete registration
      final authService = ref.read(authServiceProvider);
      final deviceName = await _getDeviceName();
      
      // Format phone number with country code
      final rawCountryCode = _countryCodeController.text.trim().isNotEmpty
          ? _countryCodeController.text.trim()
          : (_countryCode ?? '');
      final normalizedCountryCode = rawCountryCode.isNotEmpty
          ? (rawCountryCode.startsWith('+') ? rawCountryCode : '+$rawCountryCode')
          : '';
      final formattedPhone = _phoneNumber.startsWith('+') 
          ? _phoneNumber 
          : '$normalizedCountryCode$_phoneNumber';
      
      // Calculate age from birth date if not provided
      final birthDateString = _birthDate!.toIso8601String().split('T')[0];
      
      final request = CompleteRegistrationRequest(
        deviceName: deviceName,
        phoneNumber: formattedPhone,
        countryId: _countryId!,
        cityId: _cityId!,
        gender: _genderId!,
        birthDate: birthDateString,
        minAgePreference: _minAgePreference,
        maxAgePreference: _maxAgePreference,
        profileBio: _bio,
        height: _height,
        weight: _weight,
        smoke: _smoke,
        drink: _drink,
        gym: _gym,
        musicGenres: _musicGenres,
        educations: _educations,
        jobs: _jobs,
        languages: _languages,
        interests: _interestsIds,
        preferredGenders: _preferredGenders,
        relationGoals: _relationGoals,
      );

      final response = await authService.completeRegistration(request);

      if (mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => OnboardingCelebrationScreen(
              displayName: _name.isNotEmpty ? _name : 'You',
              age: _age,
              location: _celebrationLocation(),
              bio: _bio.isNotEmpty ? _bio : null,
              relationshipGoal: _celebrationRelationshipGoal(),
              heightCm: _height,
              photoSources: _celebrationPhotoSources(),
              topInterests: _selectedInterests.take(6).toList(),
            ),
          ),
        );
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
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return AppPageScaffold(
      title: formatSettingsTitle('Setup Profile'),
      showBackButton: _currentStep > 0,
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSettingsLayout.horizontalPadding,
              AppSpacing.spacingMD,
              AppSettingsLayout.horizontalPadding,
              0,
            ),
            child: OnboardingProgressIndicator(
              currentStep: _currentStep,
              totalSteps: 7,
              style: OnboardingProgressStyle.segmentedBar,
            ),
          ),
          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(textColor, secondaryTextColor, isDark), // Profile Photo
                _buildStep2(textColor, secondaryTextColor, isDark), // Basic Info & Contact
                _buildStep3(textColor, secondaryTextColor, isDark), // About You
                _buildStep4(textColor, secondaryTextColor, isDark), // Preferences & Lifestyle
                _buildStep5(textColor, secondaryTextColor, isDark), // Interests & Music
                _buildStep6(textColor, secondaryTextColor, isDark), // Additional Photos
                _buildStep7(textColor, secondaryTextColor, isDark), // Summary
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
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
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
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
                      text: _currentStep == 6 ? 'Complete' : 'Next',
                      onPressed: (_isLoading || _isUploadingImage) 
                          ? null 
                          : (_currentStep == 6 ? _completeWizard : _nextStep),
                      isLoading: (_isLoading || _isUploadingImage) && _currentStep == 6,
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

  Widget _buildStep1(Color textColor, Color secondaryTextColor, bool isDark) {
    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Profile Photo',
        [
          ProfileWizardLayout.inset(
            child: Column(
              children: [
                Center(
                  child: AvatarUpload(
                    imageUrl: _avatarUrl,
                    name: _name.isNotEmpty ? _name : 'User',
                    size: 120,
                    onUpload: () => _showImageSourceDialog(isPrimary: true),
                    onEdit: () => _showImageSourceDialog(isPrimary: true),
                  ),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Add a profile photo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  'Choose a clear photo that shows your face',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                if (_primaryImageFile != null) ...[
                  SizedBox(height: AppSpacing.spacingMD),
                  AppGroupedInfoTile(
                    label: 'Status',
                    value: 'Profile photo selected',
                    badge: 'Ready',
                    showDivider: false,
                  ),
                ],
              ],
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.footnote(
        text: 'Your primary photo is shown on discovery and in chat.',
      ),
    ]);
  }

  void _showImageSourceDialog({required bool isPrimary}) {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppSvgIcon(
                assetPath: AppIcons.gallery,
                size: 24,
                color: textColor,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isPrimary: isPrimary);
              },
            ),
            ListTile(
              leading: AppSvgIcon(
                assetPath: AppIcons.camera,
                size: 24,
                color: textColor,
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isPrimary: isPrimary);
              },
            ),
            ListTile(
              leading: AppSvgIcon(
                assetPath: AppIcons.close,
                size: 24,
                color: textColor,
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data
    final countriesAsync = ref.watch(countriesProvider);
    final gendersAsync = ref.watch(gendersProvider);
    final citiesAsync = _countryId != null
        ? ref.watch(citiesProvider(_countryId!))
        : const AsyncValue<List<ReferenceItem>>.data([]);

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Basic Information & Contact',
        [
          ProfileWizardLayout.inset(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _name = value;
                    });
                  },
                ),
              ],
            ),
          ),
          countriesAsync.when(
            data: (countries) => ReferenceBottomSheetField(
              label: 'Country',
              hint: 'Select your country',
              selectedId: _countryId,
              items: countries,
              groupedStyle: true,
              onChanged: (value) {
                setState(() {
                  _countryId = value;
                  _cityId = null; // Reset city when country changes
                  final selectedCountry = countries.firstWhere(
                    (c) => c.id == value,
                    orElse: () => ReferenceItem(id: -1, title: '', phoneCode: _countryCode),
                  );
                  final newCode = selectedCountry.phoneCode ?? _countryCode ?? '+1';
                  _countryCode = newCode;
                  _countryCodeController.text = newCode;
                });
              },
              required: true,
              searchable: true,
            ),
            loading: () => _buildLoadingField('Country', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Country', error, textColor, secondaryTextColor, isDark),
          ),
          if (_countryId != null)
            citiesAsync.when(
              data: (cities) => ReferenceBottomSheetField(
                label: 'City',
                hint: 'Select your city',
                selectedId: _cityId,
                items: cities,
                groupedStyle: true,
                onChanged: (value) {
                  setState(() {
                    _cityId = value;
                  });
                },
                required: true,
                enabled: cities.isNotEmpty,
                searchable: true,
              ),
              loading: () => _buildLoadingField('City', textColor, secondaryTextColor, isDark),
              error: (error, stack) => _buildErrorField('City', error, textColor, secondaryTextColor, isDark),
            ),
          countriesAsync.when(
            data: (countries) {
              final selectedCountry = countries.firstWhere(
                (c) => c.id == _countryId,
                orElse: () => ReferenceItem(id: -1, title: ''),
              );
              final defaultCountryCode = selectedCountry.phoneCode ?? '+1';
              final effectiveCountryCode = _countryCode?.isNotEmpty == true
                  ? _countryCode!
                  : defaultCountryCode;

              if (_countryCode == null || _countryCode!.isEmpty) {
                _countryCode = effectiveCountryCode;
              }
              if (_countryCodeController.text != effectiveCountryCode) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _countryCodeController.text = effectiveCountryCode;
                  }
                });
              }

              return ProfileWizardLayout.inset(
                child: Form(
                  key: _phoneFormKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          controller: _countryCodeController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Code',
                            hintText: defaultCountryCode,
                          ),
                          validator: _validateCountryCode,
                          onChanged: (value) {
                            var normalized = value.trim();
                            if (normalized.isNotEmpty && !normalized.startsWith('+')) {
                              normalized = '+$normalized';
                            }
                            setState(() {
                              _countryCode = normalized.isNotEmpty
                                  ? normalized
                                  : defaultCountryCode;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter phone number',
                          ),
                          validator: _validatePhoneNumber,
                          onChanged: (value) {
                            setState(() {
                              _phoneNumber = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => _buildLoadingField('Phone Number', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Phone Number', error, textColor, secondaryTextColor, isDark),
          ),
          gendersAsync.when(
            data: (genders) => ReferenceBottomSheetField(
              label: 'Gender',
              hint: 'Select your gender',
              selectedId: _genderId,
              items: genders,
              groupedStyle: true,
              onChanged: (value) {
                setState(() {
                  _genderId = value;
                });
              },
              required: true,
              searchable: true,
            ),
            loading: () => _buildLoadingField('Gender', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Gender', error, textColor, secondaryTextColor, isDark),
          ),
          ProfileWizardLayout.pickerTile(
            context: context,
            label: 'Birth Date',
            value: _birthDate != null
                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                : null,
            hint: 'Select your birth date',
            required: true,
            showDivider: false,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _birthDate ??
                    DateTime.now().subtract(const Duration(days: 365 * 25)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.accentPurple,
                        onPrimary: Colors.white,
                        surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        onSurface: textColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _birthDate = picked;
                  final today = DateTime.now();
                  _age = today.year - picked.year;
                  if (today.month < picked.month ||
                      (today.month == picked.month && today.day < picked.day)) {
                    _age = _age! - 1;
                  }
                });
              }
            },
          ),
        ],
        first: true,
      ),
    ]);
  }

  // Helper method to show multi-select bottom sheet
  Future<void> _showMultiSelectBottomSheet({
    required String title,
    required List<ReferenceItem> items,
    required List<int> selectedIds,
    required Function(List<int>) onSelected,
    bool withImages = false,
  }) async {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final selected = await SelectionBottomSheet.showMultiSelect<ReferenceItem>(
      context: context,
      title: title,
      items: items,
      getTitle: (item) => item.title,
      selectedItems: items.where((item) => selectedIds.contains(item.id)).toList(),
      searchable: true,
    );
    
    if (selected != null) {
      onSelected(selected.map((item) => item.id).toList());
    }
  }

  // Helper method to show languages bottom sheet with images
  Future<void> _showLanguagesBottomSheet(List<ReferenceItem> languages) async {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    Set<ReferenceItem> selectedLanguages = languages
        .where((l) => _languages.contains(l.id))
        .toSet();
    final TextEditingController searchController = TextEditingController();
    List<ReferenceItem> filteredLanguages = List.from(languages);

    await showModalBottomSheet<List<ReferenceItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void filterLanguages(String query) {
            setModalState(() {
              if (query.isEmpty) {
                filteredLanguages = List.from(languages);
              } else {
                filteredLanguages = languages
                    .where((lang) =>
                        lang.title.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              }
            });
          }

          void toggleSelection(ReferenceItem language) {
            setModalState(() {
              if (selectedLanguages.any((l) => l.id == language.id)) {
                selectedLanguages.removeWhere((l) => l.id == language.id);
              } else {
                selectedLanguages.add(language);
              }
            });
          }

          return AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.radiusXL),
                  topRight: Radius.circular(AppRadius.radiusXL),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: AppSpacing.spacingMD),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Languages',
                              style: AppTypography.h2.copyWith(color: textColor),
                            ),
                            if (selectedLanguages.isNotEmpty)
                              Text(
                                '${selectedLanguages.length} selected',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accentPurple,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (selectedLanguages.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    selectedLanguages.clear();
                                  });
                                },
                                child: Text(
                                  'Clear',
                                  style: AppTypography.button.copyWith(
                                    color: AppColors.accentPurple,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: AppSvgIcon(
                                assetPath: AppIcons.close,
                                size: 24,
                                color: secondaryTextColor,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterLanguages,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: AppSvgIcon(
                            assetPath: AppIcons.search,
                            size: 16,
                            color: secondaryTextColor,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                        ),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  // Languages list with images
                  Flexible(
                    child: filteredLanguages.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(AppSpacing.spacingXXL),
                            child: Text(
                              'No languages found',
                              style: AppTypography.body.copyWith(color: secondaryTextColor),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredLanguages.length,
                            itemBuilder: (context, index) {
                              final language = filteredLanguages[index];
                              final isSelected = selectedLanguages.any((l) => l.id == language.id);

                              return InkWell(
                                onTap: () => toggleSelection(language),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingLG,
                                    vertical: AppSpacing.spacingMD,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentPurple.withOpacity(0.1)
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: borderColor.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Language image
                                      if (language.imageUrl != null)
                                        Container(
                                          width: 48,
                                          height: 48,
                                          margin: EdgeInsets.only(right: AppSpacing.spacingMD),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.accentPurple
                                                  : borderColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                            child: CachedNetworkImage(
                                              imageUrl: language.imageUrl!,
                                              cacheManager: ref.watch(imageCacheServiceProvider),
                                              fadeInDuration: const Duration(milliseconds: 200),
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: surfaceColor,
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        AppColors.accentPurple,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: surfaceColor,
                                                child: AppSvgIcon(
                                                  assetPath: AppIcons.userOutline,
                                                  size: 24,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Checkbox
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.accentPurple
                                                : borderColor,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppColors.accentPurple
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? AppSvgIcon(
                                                assetPath: AppIcons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: AppSpacing.spacingMD),
                                      Expanded(
                                        child: Text(
                                          language.title,
                                          style: AppTypography.body.copyWith(
                                            color: isSelected
                                                ? AppColors.accentPurple
                                                : textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Done button
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(
                        top: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(List<ReferenceItem>.from(selectedLanguages)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            ),
                          ),
                          child: Text(
                            'Done (${selectedLanguages.length})',
                            style: AppTypography.button.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((selected) {
      if (selected != null) {
        setState(() {
          _languages = selected.map((lang) => lang.id).toList();
        });
      }
    });
  }

  // Helper method to show preferred genders bottom sheet with images
  Future<void> _showPreferredGendersBottomSheet(List<ReferenceItem> genders) async {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    Set<ReferenceItem> selectedGenders = genders.where((g) => _preferredGenders.contains(g.id)).toSet();
    final TextEditingController searchController = TextEditingController();
    List<ReferenceItem> filteredGenders = List.from(genders);

    await showModalBottomSheet<List<ReferenceItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void filterGenders(String query) {
            setModalState(() {
              if (query.isEmpty) {
                filteredGenders = List.from(genders);
              } else {
                filteredGenders = genders
                    .where((gender) =>
                        gender.title.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              }
            });
          }

          void toggleSelection(ReferenceItem gender) {
            setModalState(() {
              if (selectedGenders.any((g) => g.id == gender.id)) {
                selectedGenders.removeWhere((g) => g.id == gender.id);
              } else {
                selectedGenders.add(gender);
              }
            });
          }

          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.radiusXL),
                  topRight: Radius.circular(AppRadius.radiusXL),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: AppSpacing.spacingMD),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Preferred Genders',
                              style: AppTypography.h2.copyWith(color: textColor),
                            ),
                            if (selectedGenders.isNotEmpty)
                              Text(
                                '${selectedGenders.length} selected',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accentPurple,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (selectedGenders.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    selectedGenders.clear();
                                  });
                                },
                                child: Text(
                                  'Clear',
                                  style: AppTypography.button.copyWith(
                                    color: AppColors.accentPurple,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: AppSvgIcon(
                                assetPath: AppIcons.close,
                                size: 24,
                                color: secondaryTextColor,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterGenders,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: AppSvgIcon(
                            assetPath: AppIcons.search,
                            size: 16,
                            color: secondaryTextColor,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                        ),
                      ),
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Flexible(
                    child: filteredGenders.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(AppSpacing.spacingXXL),
                            child: Text(
                              'No genders found',
                              style: AppTypography.body.copyWith(color: secondaryTextColor),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredGenders.length,
                            itemBuilder: (context, index) {
                              final gender = filteredGenders[index];
                              final isSelected = selectedGenders.any((g) => g.id == gender.id);

                              return InkWell(
                                onTap: () => toggleSelection(gender),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingLG,
                                    vertical: AppSpacing.spacingMD,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.accentPurple.withOpacity(0.1)
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: borderColor.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (gender.imageUrl != null)
                                        Container(
                                          width: 48,
                                          height: 48,
                                          margin: EdgeInsets.only(right: AppSpacing.spacingMD),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.accentPurple
                                                  : borderColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                            child: CachedNetworkImage(
                                              imageUrl: gender.imageUrl!,
                                              cacheManager: ref.watch(imageCacheServiceProvider),
                                              fadeInDuration: const Duration(milliseconds: 200),
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: surfaceColor,
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        AppColors.accentPurple,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: surfaceColor,
                                                child: AppSvgIcon(
                                                  assetPath: AppIcons.userOutline,
                                                  size: 24,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.accentPurple
                                                : borderColor,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppColors.accentPurple
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? AppSvgIcon(
                                                assetPath: AppIcons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: AppSpacing.spacingMD),
                                      Expanded(
                                        child: Text(
                                          gender.title,
                                          style: AppTypography.body.copyWith(
                                            color: isSelected
                                                ? AppColors.accentPurple
                                                : textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(
                        top: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(List<ReferenceItem>.from(selectedGenders)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                            ),
                          ),
                          child: Text(
                            'Done (${selectedGenders.length})',
                            style: AppTypography.button.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((selected) {
      if (selected != null) {
        setState(() {
          _preferredGenders = selected.map((gender) => gender.id).toList();
        });
      }
    });
  }

  Widget _buildStep3(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data
    final educationLevelsAsync = ref.watch(educationLevelsProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final languagesAsync = ref.watch(languagesProvider);

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'About Me',
        [
          ProfileWizardLayout.inset(
            child: TextFormField(
              initialValue: _bio,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself...',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                setState(() {
                  _bio = value;
                });
              },
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Bio must be 500 characters or less';
                }
                return null;
              },
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.section(
        'Personal Details',
        [
          ProfileWizardLayout.inset(
            child: TextFormField(
              initialValue: _height.toString(),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'Enter your height',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _height = int.tryParse(value.trim()) ?? _height;
                });
              },
            ),
          ),
          const AppGroupedRowSeparator(),
          ProfileWizardLayout.inset(
            child: TextFormField(
              initialValue: _weight.toString(),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'Enter your weight',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _weight = int.tryParse(value.trim()) ?? _weight;
                });
              },
            ),
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'Background',
        [
          educationLevelsAsync.when(
            data: (educations) => ReferenceBottomSheetField(
              label: 'Education',
              hint: 'Select your education level',
              selectedId: _educations.isNotEmpty ? _educations.first : null,
              items: educations,
              groupedStyle: true,
              onChanged: (value) {
                setState(() {
                  _educations = value != null ? [value] : [];
                });
              },
              required: true,
              searchable: true,
            ),
            loading: () => _buildLoadingField('Education', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Education', error, textColor, secondaryTextColor, isDark),
          ),
          jobsAsync.when(
            data: (jobs) => ReferenceBottomSheetField(
              label: 'Job',
              hint: 'Select your job',
              selectedId: _jobs.isNotEmpty ? _jobs.first : null,
              items: jobs,
              groupedStyle: true,
              onChanged: (value) {
                setState(() {
                  _jobs = value != null ? [value] : [];
                });
              },
              required: true,
              searchable: true,
            ),
            loading: () => _buildLoadingField('Job', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Job', error, textColor, secondaryTextColor, isDark),
          ),
          languagesAsync.when(
            data: (languages) {
              final selectedLanguageTitles = languages
                  .where((l) => _languages.contains(l.id))
                  .map((l) => l.title)
                  .toList();

              return _buildGroupedMultiSelectPicker(
                label: 'Languages',
                hint: 'Select languages',
                selectedTitles: selectedLanguageTitles,
                onTap: () => _showLanguagesBottomSheet(languages),
                required: true,
                showDivider: false,
              );
            },
            loading: () => _buildLoadingField('Languages', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Languages', error, textColor, secondaryTextColor, isDark),
          ),
        ],
      ),
    ]);
  }

  Widget _buildGroupedMultiSelectPicker({
    required String label,
    required String hint,
    required List<String> selectedTitles,
    required VoidCallback onTap,
    bool required = false,
    bool showDivider = true,
  }) {
    final value =
        selectedTitles.isEmpty ? null : selectedTitles.join(', ');
    return ProfileWizardLayout.pickerTile(
      context: context,
      label: label,
      value: value,
      hint: hint,
      onTap: onTap,
      required: required,
      showDivider: showDivider,
    );
  }

  Widget _buildLoadingField(String label, Color textColor, Color secondaryTextColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceElevatedLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: isDark
                    ? AppColors.borderMediumDark
                    : AppColors.borderMediumLight,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentPurple,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Text(
                  'Loading...',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorField(String label, Object error, Color textColor, Color secondaryTextColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label *',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              'Failed to load $label: ${error.toString()}',
              style: AppTypography.body.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data
    final preferredGendersAsync = ref.watch(preferredGendersProvider);
    final relationGoalsAsync = ref.watch(relationshipGoalsProvider);

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Preferences & Lifestyle',
        [
          ProfileWizardLayout.inset(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Age Preference',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      ' *',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
          Text(
                                'Min: ${_minAgePreference}',
                                style: AppTypography.body.copyWith(color: textColor),
                              ),
                              SizedBox(height: AppSpacing.spacingSM),
                              Slider(
                                value: _minAgePreference.toDouble(),
                                min: 18,
                                max: _maxAgePreference.toDouble() - 1,
                                divisions: (_maxAgePreference - 19).clamp(1, 82),
                                activeColor: AppColors.accentPurple,
                                inactiveColor: isDark
                                    ? AppColors.borderMediumDark
                                    : AppColors.borderMediumLight,
                                onChanged: (value) {
                                  setState(() {
                                    _minAgePreference = value.round();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Max: ${_maxAgePreference}',
                                style: AppTypography.body.copyWith(color: textColor),
                              ),
                              SizedBox(height: AppSpacing.spacingSM),
                              Slider(
                                value: _maxAgePreference.toDouble(),
                                min: (_minAgePreference + 1).toDouble(),
                                max: 100,
                                divisions: (100 - _minAgePreference - 1).clamp(1, 82),
                                activeColor: AppColors.accentPurple,
                                inactiveColor: isDark
                                    ? AppColors.borderMediumDark
                                    : AppColors.borderMediumLight,
                                onChanged: (value) {
                                  setState(() {
                                    _maxAgePreference = value.round();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const AppGroupedRowSeparator(),
          preferredGendersAsync.when(
            data: (genders) {
              final selectedGenderTitles = genders
                  .where((g) => _preferredGenders.contains(g.id))
                  .map((g) => g.title)
                  .toList();

              return _buildGroupedMultiSelectPicker(
                label: 'Preferred Genders',
                hint: 'Select preferred genders',
                selectedTitles: selectedGenderTitles,
                onTap: () => _showPreferredGendersBottomSheet(genders),
                required: true,
              );
            },
            loading: () => _buildLoadingField('Preferred Genders', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Preferred Genders', error, textColor, secondaryTextColor, isDark),
          ),
          relationGoalsAsync.when(
            data: (goals) {
              final selectedGoalTitles = goals
                  .where((g) => _relationGoals.contains(g.id))
                  .map((g) => g.title)
                  .toList();

              return _buildGroupedMultiSelectPicker(
                label: 'Relationship Goals',
                hint: 'Select relationship goals',
                selectedTitles: selectedGoalTitles,
                onTap: () => _showMultiSelectBottomSheet(
                  title: 'Select Relationship Goals',
                  items: goals,
                  selectedIds: _relationGoals,
                  onSelected: (ids) {
                    setState(() {
                      _relationGoals = ids;
                    });
                  },
                ),
                required: true,
              );
            },
            loading: () => _buildLoadingField('Relationship Goals', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Relationship Goals', error, textColor, secondaryTextColor, isDark),
          ),
          AppGroupedSwitchTile(
            label: 'Smoking',
            subtitle: 'Do you smoke?',
            value: _smoke,
            onChanged: (value) => setState(() => _smoke = value),
          ),
          AppGroupedSwitchTile(
            label: 'Drinking',
            subtitle: 'Do you drink alcohol?',
            value: _drink,
            onChanged: (value) => setState(() => _drink = value),
          ),
          AppGroupedSwitchTile(
            label: 'Gym',
            subtitle: 'Do you work out regularly?',
            value: _gym,
            onChanged: (value) => setState(() => _gym = value),
            showDivider: false,
          ),
        ],
      ),
    ]);
  }

  Widget _buildStep5(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data
    final interestsAsync = ref.watch(interestsProvider);
    final musicGenresAsync = ref.watch(musicGenresProvider);

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Interests & Music',
        [
          interestsAsync.when(
            data: (interests) {
              final filteredInterests = interests.where((item) {
                if (_interestSearchQuery.isEmpty) return true;
                return item.title
                    .toLowerCase()
                    .contains(_interestSearchQuery.toLowerCase());
              }).toList();
              final interestTitles =
                  filteredInterests.map((item) => item.title).toList();

              return ProfileWizardLayout.inset(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _interestSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search interests',
                        hintText: 'Search interests',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppSvgIcon(
                            assetPath: AppIcons.search,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: AppSpacing.spacingLG),
                    if (interestTitles.isEmpty)
                      Text(
                        'No interests found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      )
                    else
                      ProfileSectionEditor(
                        sectionTitle: 'Interests',
                        availableOptions: interestTitles,
                        selectedOptions: _selectedInterests,
                        showSearch: false,
                        autoSave: true,
                        minSelections: 1,
                        maxSelections: 10,
                        onSave: (selected) {
                          setState(() {
                            _selectedInterests = selected;
                            _interests = selected;
                            _interestsIds = selected
                                .map((title) {
                                  final interest = interests.firstWhere(
                                    (item) => item.title == title,
                                    orElse: () =>
                                        ReferenceItem(id: -1, title: ''),
                                  );
                                  return interest.id != -1 ? interest.id : null;
                                })
                                .where((id) => id != null)
                                .cast<int>()
                                .toList();
                          });
                        },
                      ),
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField(
              'Interests',
              textColor,
              secondaryTextColor,
              isDark,
            ),
            error: (error, stack) => _buildErrorField(
              'Interests',
              error,
              textColor,
              secondaryTextColor,
              isDark,
            ),
          ),
          const AppGroupedRowSeparator(),
          musicGenresAsync.when(
            data: (genres) {
              final selectedGenreTitles = genres
                  .where((g) => _musicGenres.contains(g.id))
                  .map((g) => g.title)
                  .toList();

              return _buildGroupedMultiSelectPicker(
                label: 'Music Genres',
                hint: 'Select music genres',
                selectedTitles: selectedGenreTitles,
                onTap: () => _showMultiSelectBottomSheet(
                  title: 'Select Music Genres',
                  items: genres,
                  selectedIds: _musicGenres,
                  onSelected: (ids) {
                    setState(() {
                      _musicGenres = ids;
                    });
                  },
                ),
                required: true,
                showDivider: false,
              );
            },
            loading: () => _buildLoadingField(
              'Music Genres',
              textColor,
              secondaryTextColor,
              isDark,
            ),
            error: (error, stack) => _buildErrorField(
              'Music Genres',
              error,
              textColor,
              secondaryTextColor,
              isDark,
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.footnote(
        text: 'Pick at least one interest and your favorite music genres.',
      ),
    ]);
  }

  Widget _buildStep6(Color textColor, Color secondaryTextColor, bool isDark) {
    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.section(
        'Additional Photos',
        [
          ProfileWizardLayout.inset(
            child: Column(
              children: [
                Text(
                  'Add more photos to your profile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'You can add up to 6 photos. More photos help others get to know you better!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
                SizedBox(height: AppSpacing.spacingXL),
                if (_additionalImageFiles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.spacingXXL),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusMD),
                    ),
                    child: Column(
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.galleryAdd,
                          size: 60,
                          color: secondaryTextColor,
                        ),
                        SizedBox(height: AppSpacing.spacingMD),
                        Text(
                          'No additional photos yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _additionalImageFiles.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusMD),
                            child: Image.file(
                              _additionalImageFiles[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _additionalImageFiles.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: AppSvgIcon(
                                  assetPath: AppIcons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                SizedBox(height: AppSpacing.spacingLG),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _additionalImageFiles.length >= 6
                        ? null
                        : () => _showImageSourceDialog(isPrimary: false),
                    icon: AppSvgIcon(
                      assetPath: AppIcons.galleryAdd,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      _additionalImageFiles.length >= 6
                          ? 'Maximum 6 photos'
                          : 'Add Photo (${_additionalImageFiles.length}/6)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.footnote(
        text: 'Additional photos appear on your profile after setup.',
      ),
    ]);
  }

  Widget _buildStep7(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data for summary
    final countriesAsync = ref.watch(countriesProvider);
    final gendersAsync = ref.watch(gendersProvider);
    final citiesAsync = _countryId != null
        ? ref.watch(citiesProvider(_countryId!))
        : const AsyncValue<List<ReferenceItem>>.data([]);
    final educationLevelsAsync = ref.watch(educationLevelsProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final languagesAsync = ref.watch(languagesProvider);
    final preferredGendersAsync = ref.watch(preferredGendersProvider);
    final relationGoalsAsync = ref.watch(relationshipGoalsProvider);
    final musicGenresAsync = ref.watch(musicGenresProvider);

    // Get country name
    String countryName = countriesAsync.maybeWhen(
      data: (countries) {
        final country = countries.firstWhere(
          (c) => c.id == _countryId,
          orElse: () => ReferenceItem(id: -1, title: ''),
        );
        return country.id != -1 ? country.title : '';
      },
      orElse: () => '',
    );

    // Get city name
    String cityName = citiesAsync.maybeWhen(
      data: (cities) {
        final city = cities.firstWhere(
          (c) => c.id == _cityId,
          orElse: () => ReferenceItem(id: -1, title: ''),
        );
        return city.id != -1 ? city.title : '';
      },
      orElse: () => '',
    );

    // Get gender name
    String genderName = gendersAsync.maybeWhen(
      data: (genders) {
        final gender = genders.firstWhere(
          (g) => g.id == _genderId,
          orElse: () => ReferenceItem(id: -1, title: ''),
        );
        return gender.id != -1 ? gender.title : '';
      },
      orElse: () => '',
    );

    // Format birth date
    String birthDateStr = '';
    if (_birthDate != null) {
      birthDateStr = '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}';
    }

    final educationSummary = educationLevelsAsync.maybeWhen(
      data: (educations) => educations
          .where((e) => _educations.contains(e.id))
          .map((e) => e.title)
          .join(', '),
      orElse: () => '',
    );
    final jobsSummary = jobsAsync.maybeWhen(
      data: (jobs) =>
          jobs.where((j) => _jobs.contains(j.id)).map((j) => j.title).join(', '),
      orElse: () => '',
    );
    final languagesSummary = languagesAsync.maybeWhen(
      data: (languages) => languages
          .where((l) => _languages.contains(l.id))
          .map((l) => l.title)
          .join(', '),
      orElse: () => '',
    );
    final preferredGendersSummary = preferredGendersAsync.maybeWhen(
      data: (genders) => genders
          .where((g) => _preferredGenders.contains(g.id))
          .map((g) => g.title)
          .join(', '),
      orElse: () => '',
    );
    final relationGoalsSummary = relationGoalsAsync.maybeWhen(
      data: (goals) => goals
          .where((g) => _relationGoals.contains(g.id))
          .map((g) => g.title)
          .join(', '),
      orElse: () => '',
    );
    final interestsSummary = ref.watch(interestsProvider).maybeWhen(
          data: (interests) => interests
              .where((i) => _interestsIds.contains(i.id))
              .map((i) => i.title)
              .join(', '),
          orElse: () => '',
        );
    final musicGenresSummary = musicGenresAsync.maybeWhen(
      data: (genres) => genres
          .where((g) => _musicGenres.contains(g.id))
          .map((g) => g.title)
          .join(', '),
      orElse: () => '',
    );

    return ProfileWizardLayout.stepList(children: [
      ProfileWizardLayout.inset(
        child: Column(
          children: [
            AppSvgIcon(
              assetPath: AppIcons.checkCircle,
              size: 72,
              color: AppColors.onlineGreen,
            ),
            SizedBox(height: AppSpacing.spacingLG),
            Text(
              'You\'re All Set!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Review your profile before continuing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ],
        ),
      ),
      ProfileWizardLayout.section(
        'Profile Photo',
        [
          AppGroupedInfoTile(
            label: 'Profile Photo',
            value: _primaryImageFile != null ? 'Uploaded' : 'Not set',
            badge: _primaryImageFile != null ? 'Ready' : null,
          ),
          AppGroupedInfoTile(
            label: 'Additional Photos',
            value: _additionalImageFiles.isEmpty
                ? 'None added'
                : '${_additionalImageFiles.length} photos',
            showDivider: false,
          ),
        ],
        first: true,
      ),
      ProfileWizardLayout.section(
        'Basic Information & Contact',
        [
          AppGroupedInfoTile(
            label: 'Name',
            value: _name.isNotEmpty ? _name : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Phone',
            value: _phoneNumber.isNotEmpty ? _phoneNumber : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Country',
            value: countryName.isNotEmpty ? countryName : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'City',
            value: cityName.isNotEmpty ? cityName : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Gender',
            value: genderName.isNotEmpty ? genderName : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Birth Date',
            value: birthDateStr.isNotEmpty ? birthDateStr : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Age',
            value: _age != null ? '$_age years' : 'Not set',
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'About You',
        [
          AppGroupedInfoTile(
            label: 'Bio',
            value: _bio.isNotEmpty ? _bio : 'Not set',
          ),
          AppGroupedInfoTile(
            label: 'Height',
            value: '$_height cm',
          ),
          AppGroupedInfoTile(
            label: 'Weight',
            value: '$_weight kg',
          ),
          AppGroupedInfoTile(
            label: 'Education',
            value: educationSummary.isEmpty ? 'Not set' : educationSummary,
          ),
          AppGroupedInfoTile(
            label: 'Job',
            value: jobsSummary.isEmpty ? 'Not set' : jobsSummary,
          ),
          AppGroupedInfoTile(
            label: 'Languages',
            value: languagesSummary.isEmpty ? 'Not set' : languagesSummary,
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'Preferences & Lifestyle',
        [
          AppGroupedInfoTile(
            label: 'Age Preference',
            value: '$_minAgePreference-$_maxAgePreference years',
          ),
          AppGroupedInfoTile(
            label: 'Preferred Genders',
            value:
                preferredGendersSummary.isEmpty ? 'Not set' : preferredGendersSummary,
          ),
          AppGroupedInfoTile(
            label: 'Relationship Goals',
            value: relationGoalsSummary.isEmpty ? 'Not set' : relationGoalsSummary,
          ),
          AppGroupedInfoTile(
            label: 'Smoking',
            value: _smoke ? 'Yes' : 'No',
          ),
          AppGroupedInfoTile(
            label: 'Drinking',
            value: _drink ? 'Yes' : 'No',
          ),
          AppGroupedInfoTile(
            label: 'Gym',
            value: _gym ? 'Yes' : 'No',
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.section(
        'Interests & Music',
        [
          AppGroupedInfoTile(
            label: 'Interests',
            value: interestsSummary.isEmpty ? 'Not set' : interestsSummary,
          ),
          AppGroupedInfoTile(
            label: 'Music Genres',
            value: musicGenresSummary.isEmpty ? 'Not set' : musicGenresSummary,
            showDivider: false,
          ),
        ],
      ),
      ProfileWizardLayout.footnote(
        text: 'You can update any of these details later in profile settings.',
      ),
    ]);
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
    setState(() {
      _primaryImageFile = file;
      _avatarUrl = file.path;
    });
  }

  @visibleForTesting
  void testSeedStep1Phone({
    String countryCode = '+1',
    String phone = '5551234567',
  }) {
    _countryCode = countryCode;
    _countryCodeController.text = countryCode;
    _phoneNumber = phone;
    _phoneNumberController.text = phone;
  }

  @visibleForTesting
  void testSeedCompleteState(File photo) {
    testSeedPrimaryPhoto(photo);
    _name = 'Alex User';
    _nameController.text = 'Alex User';
    _countryId = 1;
    _cityId = 10;
    _genderId = 2;
    _birthDate = DateTime(1995, 6, 15);
    testSeedStep1Phone();
    _bio = 'Bio text for tests';
    _educations = [4];
    _jobs = [3];
    _languages = [5];
    _preferredGenders = [2];
    _relationGoals = [9];
    _interestsIds = [6];
    _musicGenres = [8];
    _minAgePreference = 18;
    _maxAgePreference = 30;
    testJumpToStep(6);
  }
}
