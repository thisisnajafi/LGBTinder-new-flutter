// Screen: ProfileWizardPage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/app_theme.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/profile/avatar_upload.dart';
import '../widgets/profile/edit/profile_field_editor.dart';
import '../features/profile/data/models/user_image.dart';
import '../widgets/profile/edit/profile_section_editor.dart';
import '../widgets/common/section_header.dart';
import '../core/utils/app_icons.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/common/reference_dropdown.dart';
import '../widgets/common/selection_bottom_sheet.dart';
import '../widgets/common/reference_bottom_sheet_field.dart';
import '../widgets/buttons/gradient_button.dart';
import '../features/auth/providers/auth_service_provider.dart';
import '../features/auth/data/models/complete_registration_request.dart';
import '../features/profile/providers/profile_providers.dart';
import '../features/profile/data/models/user_image.dart';
import '../features/profile/data/models/user_profile.dart';
import '../shared/models/api_error.dart';
import '../shared/services/error_handler_service.dart';
import 'package:go_router/go_router.dart';
import '../pages/onboarding_page.dart';
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
            _educations = profile.educations!;
          }
          if (profile.jobs != null && profile.jobs!.isNotEmpty) {
            _jobs = profile.jobs!;
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
            content: Text('Please select at least one education level'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_jobs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one job'),
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWizard();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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

  Future<void> _completeWizard() async {
    // Validate phone form first (if it exists)
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
    
    // Check educations
    if (errorMessage == null && _educations.isEmpty) {
      errorMessage = 'Please select at least one education level';
    }
    
    // Check jobs
    if (errorMessage == null && _jobs.isEmpty) {
      errorMessage = 'Please select at least one job';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );

        // Navigate to onboarding page (not home page)
        if (mounted) {
          context.go('/onboarding');
        }
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
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Setup Profile',
        showBackButton: _currentStep > 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              children: List.generate(7, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.accentPurple
                          : (isDark
                              ? AppColors.borderMediumDark
                              : AppColors.borderMediumLight),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
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
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        children: [
          SectionHeader(
            title: 'Profile Photo',
            iconPath: AppIcons.userOutline,
          ),
          SizedBox(height: AppSpacing.spacingXL),
          AvatarUpload(
            imageUrl: _avatarUrl,
            name: _name.isNotEmpty ? _name : 'User',
            size: 150.0,
            onUpload: () => _showImageSourceDialog(isPrimary: true),
            onEdit: () => _showImageSourceDialog(isPrimary: true),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          Text(
            'Add a profile photo',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Choose a clear photo that shows your face',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          if (_primaryImageFile != null) ...[
            SizedBox(height: AppSpacing.spacingLG),
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.onlineGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.checkCircle,
                    size: 20,
                    color: AppColors.onlineGreen,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Text(
                      'Profile photo selected',
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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

  // Helper method to show country/city bottom sheet
  Future<void> _showCountryBottomSheet(List<ReferenceItem> countries) async {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final selected = await SelectionBottomSheet.showSingleSelect<ReferenceItem>(
      context: context,
      title: 'Select Country',
      items: countries,
      getTitle: (item) => item.title,
      selectedItem: countries.firstWhere(
        (c) => c.id == _countryId,
        orElse: () => ReferenceItem(id: -1, title: ''),
      ),
      searchable: true,
    );
    
    if (selected != null && selected.id != -1) {
      setState(() {
        _countryId = selected.id;
        _cityId = null; // Reset city when country changes
      });
    }
  }

  // Helper method to show city bottom sheet
  Future<void> _showCityBottomSheet(List<ReferenceItem> cities) async {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final selected = await SelectionBottomSheet.showSingleSelect<ReferenceItem>(
      context: context,
      title: 'Select City',
      items: cities,
      getTitle: (item) => item.title,
      selectedItem: cities.firstWhere(
        (c) => c.id == _cityId,
        orElse: () => ReferenceItem(id: -1, title: ''),
      ),
      searchable: true,
    );
    
    if (selected != null && selected.id != -1) {
      setState(() {
        _cityId = selected.id;
      });
    }
  }

  // Helper method to show gender bottom sheet with images
  Future<void> _showGenderBottomSheet(List<ReferenceItem> genders) async {
    // Dismiss keyboard and unfocus any text fields
    FocusScope.of(context).unfocus();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    await showModalBottomSheet<ReferenceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  Text(
                    'Select Gender',
                    style: AppTypography.h2.copyWith(color: textColor),
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
            ),
            // Gender list with images
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: genders.length,
                itemBuilder: (context, index) {
                  final gender = genders[index];
                  final isSelected = gender.id == _genderId;

                  return InkWell(
                    onTap: () => Navigator.of(context).pop(gender),
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
                          // Gender image
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
                          if (isSelected)
                            AppSvgIcon(
                              assetPath: AppIcons.checkCircle,
                              size: 24,
                              color: AppColors.accentPurple,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((selected) {
      if (selected != null) {
        setState(() {
          _genderId = selected.id;
        });
      }
    });
  }

  Widget _buildStep2(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data
    final countriesAsync = ref.watch(countriesProvider);
    final gendersAsync = ref.watch(gendersProvider);
    final citiesAsync = _countryId != null
        ? ref.watch(citiesProvider(_countryId!))
        : const AsyncValue<List<ReferenceItem>>.data([]);
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Basic Information & Contact',
            iconPath: AppIcons.info,
          ),
          SizedBox(height: AppSpacing.spacingLG),
          // Name Field (auto-save, no save button)
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Name',
                  style: AppTypography.h3.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.body.copyWith(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
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
                    contentPadding: EdgeInsets.all(AppSpacing.spacingMD),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _name = value; // Auto-save on change
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Phone Number Field
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
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Phone Number',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Form(
                      key: _phoneFormKey,
                      child: Container(
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
                              width: 90,
                              child: TextFormField(
                                controller: _countryCodeController,
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.center,
                                style: AppTypography.body.copyWith(color: textColor),
                                decoration: InputDecoration(
                                  hintText: defaultCountryCode,
                                  hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.spacingMD,
                                  ),
                                  errorStyle: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                  ),
                                ),
                                validator: _validateCountryCode,
                                onChanged: (value) {
                                  var normalized = value.trim();
                                  if (normalized.isNotEmpty && !normalized.startsWith('+')) {
                                    normalized = '+$normalized';
                                  }
                                  setState(() {
                                    _countryCode = normalized.isNotEmpty ? normalized : defaultCountryCode;
                                  });
                                },
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: isDark
                                  ? AppColors.borderMediumDark
                                  : AppColors.borderMediumLight,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneNumberController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.body.copyWith(color: textColor),
                                decoration: InputDecoration(
                                  hintText: 'Enter phone number',
                                  hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(AppSpacing.spacingMD),
                                  errorStyle: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                  ),
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
                    ),
                  ],
                ),
              );
            },
            loading: () => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone Number *',
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
            ),
            error: (error, stack) => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone Number *',
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
                      'Failed to load countries: ${error.toString()}',
                      style: AppTypography.body.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Country Bottom Sheet Field
          countriesAsync.when(
            data: (countries) => ReferenceBottomSheetField(
              label: 'Country',
              hint: 'Select your country',
              selectedId: _countryId,
              items: countries,
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
            loading: () => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Country *',
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
                          'Loading countries...',
                          style: AppTypography.body.copyWith(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            error: (error, stack) => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Country *',
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
                      'Failed to load countries: ${error.toString()}',
                      style: AppTypography.body.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // City Bottom Sheet Field (depends on country)
          if (_countryId != null)
            citiesAsync.when(
              data: (cities) => ReferenceBottomSheetField(
                label: 'City',
                hint: 'Select your city',
                selectedId: _cityId,
                items: cities,
                onChanged: (value) {
                  setState(() {
                    _cityId = value;
                  });
                },
                required: true,
                enabled: cities.isNotEmpty,
                searchable: true,
              ),
              loading: () => Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City *',
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
                            'Loading cities...',
                            style: AppTypography.body.copyWith(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City *',
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
                        'Failed to load cities: ${error.toString()}',
                        style: AppTypography.body.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: AppSpacing.spacingMD),
          // Gender Bottom Sheet Field
          gendersAsync.when(
            data: (genders) {
              // Find selected gender
              final selectedGender = genders.firstWhere(
                (g) => g.id == _genderId,
                orElse: () => ReferenceItem(id: -1, title: ''),
              );

              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Gender',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
                      onTap: () => _showGenderBottomSheet(genders),
                      child: Container(
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
                            // Gender image if selected
                            if (selectedGender.id != -1 && selectedGender.imageUrl != null)
                              Container(
                                width: 32,
                                height: 32,
                                margin: EdgeInsets.only(right: AppSpacing.spacingMD),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderMediumDark
                                        : AppColors.borderMediumLight,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                  child: CachedNetworkImage(
                                    imageUrl: selectedGender.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.surfaceLight,
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.surfaceLight,
                                      child: AppSvgIcon(
                                        assetPath: AppIcons.userOutline,
                                        size: 16,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                selectedGender.id != -1
                                    ? selectedGender.title
                                    : 'Select your gender',
                                style: AppTypography.body.copyWith(
                                  color: selectedGender.id != -1
                                      ? textColor
                                      : secondaryTextColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gender *',
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
                          'Loading genders...',
                          style: AppTypography.body.copyWith(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            error: (error, stack) => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gender *',
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
                      'Failed to load genders: ${error.toString()}',
                      style: AppTypography.body.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Birth Date Picker
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Birth Date',
                      style: AppTypography.h3.copyWith(color: textColor),
                    ),
                    Text(
                      ' *',
                      style: AppTypography.h3.copyWith(color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be 18+
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
                        // Calculate age from birth date
                        final today = DateTime.now();
                        _age = today.year - picked.year;
                        if (today.month < picked.month ||
                            (today.month == picked.month && today.day < picked.day)) {
                          _age = _age! - 1;
                        }
                      });
                    }
                  },
                  child: Container(
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
                        AppSvgIcon(
                          assetPath: AppIcons.calendar,
                          size: 20,
                          color: secondaryTextColor,
                        ),
                        SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Text(
                            _birthDate != null
                                ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                : 'Select your birth date',
                            style: AppTypography.body.copyWith(
                              color: _birthDate != null ? textColor : secondaryTextColor,
                            ),
                          ),
                        ),
                        AppSvgIcon(
                          assetPath: AppIcons.arrowDown,
                          size: 20,
                          color: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
        ],
      ),
    );
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
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'About You',
            iconPath: AppIcons.userOutline,
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bio',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              TextFormField(
            initialValue: _bio,
            maxLines: 5,
            maxLength: 500,
                style: AppTypography.body.copyWith(color: textColor),
                decoration: InputDecoration(
            hintText: 'Tell us about yourself...',
                  hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
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
                  contentPadding: EdgeInsets.all(AppSpacing.spacingMD),
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
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Height Slider
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Height',
                      style: AppTypography.h3.copyWith(color: textColor),
                    ),
                    Text(
                      ' *',
                      style: AppTypography.h3.copyWith(color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  '${_height} cm',
                  style: AppTypography.h2.copyWith(color: AppColors.accentPurple),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Slider(
                  value: _height.toDouble(),
                  min: 100,
                  max: 250,
                  divisions: 150,
                  label: '${_height} cm',
                  activeColor: AppColors.accentPurple,
                  onChanged: (value) {
                    setState(() {
                      _height = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Weight Slider
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Weight',
                      style: AppTypography.h3.copyWith(color: textColor),
                    ),
                    Text(
                      ' *',
                      style: AppTypography.h3.copyWith(color: Colors.red),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  '${_weight} kg',
                  style: AppTypography.h2.copyWith(color: AppColors.accentPurple),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Slider(
                  value: _weight.toDouble(),
                  min: 30,
                  max: 200,
                  divisions: 170,
                  label: '${_weight} kg',
                  activeColor: AppColors.accentPurple,
                  onChanged: (value) {
                    setState(() {
                      _weight = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Education Multi-Select
          educationLevelsAsync.when(
            data: (educations) {
              final selectedEducationItems = educations
                  .where((e) => _educations.contains(e.id))
                  .toList();
              final selectedEducationTitles =
                  selectedEducationItems.map((e) => e.title).toList();
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Education',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
                      onTap: () => _showMultiSelectBottomSheet(
                        title: 'Select Education',
                        items: educations,
                        selectedIds: _educations,
                        onSelected: (ids) {
                          setState(() {
                            _educations = ids;
                          });
                        },
                      ),
                      child: Container(
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
                            Expanded(
                              child: Text(
                                selectedEducationTitles.isEmpty
                                    ? 'Select education levels'
                                    : '${selectedEducationTitles.length} selected',
                                style: AppTypography.body.copyWith(
                                  color: selectedEducationTitles.isEmpty
                                      ? secondaryTextColor
                                      : textColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedEducationItems.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: selectedEducationItems.map((item) {
                          return InputChip(
                            label: Text(item.title),
                            onDeleted: () {
                              setState(() {
                                _educations.remove(item.id);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            labelStyle: AppTypography.caption.copyWith(
                              color: textColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField('Education', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Education', error, textColor, secondaryTextColor, isDark),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Jobs Multi-Select
          jobsAsync.when(
            data: (jobs) {
              final selectedJobItems = jobs
                  .where((j) => _jobs.contains(j.id))
                  .toList();
              final selectedJobTitles = selectedJobItems.map((j) => j.title).toList();
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Jobs',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
                      onTap: () => _showMultiSelectBottomSheet(
                        title: 'Select Jobs',
                        items: jobs,
                        selectedIds: _jobs,
                        onSelected: (ids) {
                          setState(() {
                            _jobs = ids;
                          });
                        },
                      ),
                      child: Container(
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
                            Expanded(
                              child: Text(
                                selectedJobTitles.isEmpty
                                    ? 'Select jobs'
                                    : '${selectedJobTitles.length} selected',
                                style: AppTypography.body.copyWith(
                                  color: selectedJobTitles.isEmpty
                                      ? secondaryTextColor
                                      : textColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedJobItems.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: selectedJobItems.map((item) {
                          return InputChip(
                            label: Text(item.title),
                            onDeleted: () {
                              setState(() {
                                _jobs.remove(item.id);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            labelStyle: AppTypography.caption.copyWith(
                              color: textColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField('Jobs', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Jobs', error, textColor, secondaryTextColor, isDark),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Languages Multi-Select
          languagesAsync.when(
            data: (languages) {
              final selectedLanguageItems = languages
                  .where((l) => _languages.contains(l.id))
                  .toList();
              final selectedLanguageTitles = selectedLanguageItems.map((l) => l.title).toList();
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Languages',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
                      onTap: () => _showLanguagesBottomSheet(languages),
                      child: Container(
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
                            Expanded(
                              child: Text(
                                selectedLanguageTitles.isEmpty
                                    ? 'Select languages'
                                    : '${selectedLanguageTitles.length} selected',
                                style: AppTypography.body.copyWith(
                                  color: selectedLanguageTitles.isEmpty
                                      ? secondaryTextColor
                                      : textColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedLanguageItems.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: selectedLanguageItems.map((item) {
                          return InputChip(
                            label: Text(item.title),
                            onDeleted: () {
                              setState(() {
                                _languages.remove(item.id);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            labelStyle: AppTypography.caption.copyWith(
                              color: textColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField('Languages', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Languages', error, textColor, secondaryTextColor, isDark),
          ),
        ],
      ),
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Preferences & Lifestyle',
            iconPath: AppIcons.heartOutline,
          ),
          SizedBox(height: AppSpacing.spacingLG),
          // Age Preferences
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Age Preference',
                      style: AppTypography.h3.copyWith(color: textColor),
                    ),
                    Text(
                      ' *',
                      style: AppTypography.h3.copyWith(color: Colors.red),
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
          SizedBox(height: AppSpacing.spacingMD),
          // Preferred Genders Multi-Select
          preferredGendersAsync.when(
            data: (genders) {
              final selectedGenderItems = genders
                  .where((g) => _preferredGenders.contains(g.id))
                  .toList();
              final selectedGenderTitles = selectedGenderItems.map((g) => g.title).toList();
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Preferred Genders',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
                      onTap: () => _showPreferredGendersBottomSheet(genders),
                      child: Container(
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
                            Expanded(
                              child: Text(
                                selectedGenderTitles.isEmpty
                                    ? 'Select preferred genders'
                                    : '${selectedGenderTitles.length} selected',
                                style: AppTypography.body.copyWith(
                                  color: selectedGenderTitles.isEmpty
                                      ? secondaryTextColor
                                      : textColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedGenderItems.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: selectedGenderItems.map((item) {
                          return InputChip(
                            label: Text(item.title),
                            onDeleted: () {
                              setState(() {
                                _preferredGenders.remove(item.id);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            labelStyle: AppTypography.caption.copyWith(
                              color: textColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField('Preferred Genders', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Preferred Genders', error, textColor, secondaryTextColor, isDark),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Relation Goals Multi-Select
          relationGoalsAsync.when(
            data: (goals) {
              final selectedGoalItems = goals
                  .where((g) => _relationGoals.contains(g.id))
                  .toList();
              final selectedGoalTitles = selectedGoalItems.map((g) => g.title).toList();
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Relationship Goals',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
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
                      child: Container(
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
                            Expanded(
                              child: Text(
                                selectedGoalTitles.isEmpty
                                    ? 'Select relationship goals'
                                    : '${selectedGoalTitles.length} selected',
                                style: AppTypography.body.copyWith(
                                  color: selectedGoalTitles.isEmpty
                                      ? secondaryTextColor
                                      : textColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedGoalItems.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: selectedGoalItems.map((item) {
                          return InputChip(
                            label: Text(item.title),
                            onDeleted: () {
                              setState(() {
                                _relationGoals.remove(item.id);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            labelStyle: AppTypography.caption.copyWith(
                              color: textColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField('Relationship Goals', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Relationship Goals', error, textColor, secondaryTextColor, isDark),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Lifestyle Choices
          _buildLifestyleChoice('Smoke', _smoke, (value) {
            setState(() {
              _smoke = value;
            });
          }, textColor, secondaryTextColor, isDark),
          SizedBox(height: AppSpacing.spacingMD),
          _buildLifestyleChoice('Drink', _drink, (value) {
            setState(() {
              _drink = value;
            });
          }, textColor, secondaryTextColor, isDark),
          SizedBox(height: AppSpacing.spacingMD),
          _buildLifestyleChoice('Gym', _gym, (value) {
            setState(() {
              _gym = value;
            });
          }, textColor, secondaryTextColor, isDark),
        ],
      ),
    );
  }

  Widget _buildLifestyleChoice(String label, bool value, Function(bool) onChanged, Color textColor, Color secondaryTextColor, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              Text(
                ' *',
                style: AppTypography.h3.copyWith(color: Colors.red),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(true),
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: value
                          ? AppColors.accentPurple
                          : (isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.surfaceElevatedLight),
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      border: Border.all(
                        color: value
                            ? AppColors.accentPurple
                            : (isDark
                                ? AppColors.borderMediumDark
                                : AppColors.borderMediumLight),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Yes',
                        style: AppTypography.body.copyWith(
                          color: value ? Colors.white : textColor,
                          fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(false),
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: !value
                          ? AppColors.accentPurple
                          : (isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.surfaceElevatedLight),
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      border: Border.all(
                        color: !value
                            ? AppColors.accentPurple
                            : (isDark
                                ? AppColors.borderMediumDark
                                : AppColors.borderMediumLight),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No',
                        style: AppTypography.body.copyWith(
                          color: !value ? Colors.white : textColor,
                          fontWeight: !value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildStep5(Color textColor, Color secondaryTextColor, bool isDark) {
    // Load reference data
    final interestsAsync = ref.watch(interestsProvider);
    final musicGenresAsync = ref.watch(musicGenresProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Interests & Music',
            iconPath: AppIcons.heartOutline,
          ),
          SizedBox(height: AppSpacing.spacingLG),
          // Interests
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
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _interestSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search interests',
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
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderMediumDark
                              : AppColors.borderMediumLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderMediumDark
                              : AppColors.borderMediumLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                        borderSide: const BorderSide(
                          color: AppColors.accentPurple,
                          width: 2,
                        ),
                      ),
                    ),
                    style: AppTypography.body.copyWith(color: textColor),
                  ),
                  SizedBox(height: AppSpacing.spacingLG),
                  if (interestTitles.isEmpty)
                    Text(
                      'No interests found',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
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
                            orElse: () => ReferenceItem(id: -1, title: ''),
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
              );
            },
            loading: () => Container(
              padding: EdgeInsets.all(AppSpacing.spacingXXL),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentPurple,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    Text(
                      'Loading interests...',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => Container(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.errorOutline,
                    size: 48,
                    color: Colors.red,
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    'Failed to load interests',
                    style: AppTypography.h3.copyWith(color: textColor),
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  Text(
                    error.toString(),
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingLG),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(interestsProvider);
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingXL),
          // Music Genres
          musicGenresAsync.when(
            data: (genres) {
              final selectedGenreItems = genres
                  .where((g) => _musicGenres.contains(g.id))
                  .toList();
              final selectedGenreTitles = selectedGenreItems.map((g) => g.title).toList();
              
              return Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Music Genres',
                          style: AppTypography.h3.copyWith(color: textColor),
                        ),
                        Text(
                          ' *',
                          style: AppTypography.h3.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    InkWell(
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
                      child: Container(
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
                            Expanded(
                              child: Text(
                                selectedGenreTitles.isEmpty
                                    ? 'Select music genres'
                                    : '${selectedGenreTitles.length} selected',
                                style: AppTypography.body.copyWith(
                                  color: selectedGenreTitles.isEmpty
                                      ? secondaryTextColor
                                      : textColor,
                                ),
                              ),
                            ),
                            AppSvgIcon(
                              assetPath: AppIcons.arrowDown,
                              size: 20,
                              color: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedGenreItems.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: selectedGenreItems.map((item) {
                          return InputChip(
                            label: Text(item.title),
                            onDeleted: () {
                              setState(() {
                                _musicGenres.remove(item.id);
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            labelStyle: AppTypography.caption.copyWith(
                              color: textColor,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => _buildLoadingField('Music Genres', textColor, secondaryTextColor, isDark),
            error: (error, stack) => _buildErrorField('Music Genres', error, textColor, secondaryTextColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6(Color textColor, Color secondaryTextColor, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        children: [
          SectionHeader(
            title: 'Additional Photos',
            iconPath: AppIcons.gallery,
          ),
          SizedBox(height: AppSpacing.spacingXL),
          Text(
            'Add more photos to your profile',
            style: AppTypography.h3.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            'You can add up to 6 photos. More photos help others get to know you better!',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Photo grid
          if (_additionalImageFiles.isEmpty)
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingXXL),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
                ),
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
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: _additionalImageFiles.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                  child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
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
                              color: Colors.black.withOpacity(0.6),
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
                  ),
                );
              },
            ),
          SizedBox(height: AppSpacing.spacingLG),
          OutlinedButton.icon(
            onPressed: _additionalImageFiles.length >= 6
                ? null
                : () => _showImageSourceDialog(isPrimary: false),
            icon: AppSvgIcon(
              assetPath: AppIcons.galleryAdd,
              size: 20,
              color: AppColors.accentPurple,
            ),
            label: Text(
              _additionalImageFiles.length >= 6
                  ? 'Maximum 6 photos'
                  : 'Add Photo (${_additionalImageFiles.length}/6)',
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.spacingMD,
                horizontal: AppSpacing.spacingLG,
              ),
              side: BorderSide(color: AppColors.accentPurple),
            ),
          ),
        ],
      ),
    );
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        children: [
          AppSvgIcon(
            assetPath: AppIcons.checkCircle,
            size: 80,
            color: AppColors.onlineGreen,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          Text(
            'You\'re All Set!',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Your profile is ready. Let\'s learn about the app!',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Step 1: Profile Photo
          _buildSummaryCard(
            'Profile Photo',
            [
              if (_primaryImageFile != null)
                _buildSummaryItem('Profile Photo', 'Uploaded', Colors.white70),
              if (_additionalImageFiles.isNotEmpty)
                _buildSummaryItem('Additional Photos', '${_additionalImageFiles.length} photos', Colors.white70),
            ],
            isDark,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Step 2: Basic Information & Contact
          _buildSummaryCard(
            'Basic Information & Contact',
            [
              if (_name.isNotEmpty)
                _buildSummaryItem('Name', _name, Colors.white70),
              if (_phoneNumber.isNotEmpty)
                _buildSummaryItem('Phone', _phoneNumber, Colors.white70),
              if (countryName.isNotEmpty)
                _buildSummaryItem('Country', countryName, Colors.white70),
              if (cityName.isNotEmpty)
                _buildSummaryItem('City', cityName, Colors.white70),
              if (genderName.isNotEmpty)
                _buildSummaryItem('Gender', genderName, Colors.white70),
              if (_birthDate != null)
                _buildSummaryItem('Birth Date', birthDateStr, Colors.white70),
              if (_age != null)
                _buildSummaryItem('Age', '${_age} years', Colors.white70),
            ],
            isDark,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Step 3: About You
          _buildSummaryCard(
            'About You',
            [
              if (_bio.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingXS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bio',
                        style: AppTypography.body.copyWith(color: Colors.white70),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        _bio,
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildSummaryItem('Height', '${_height} cm', Colors.white70),
              _buildSummaryItem('Weight', '${_weight} kg', Colors.white70),
              educationLevelsAsync.maybeWhen(
                data: (educations) {
                  final selected = educations.where((e) => _educations.contains(e.id)).map((e) => e.title).join(', ');
                  return _buildSummaryItem('Education', selected.isEmpty ? 'Not selected' : selected, Colors.white70, isMultiLine: true);
                },
                orElse: () => const SizedBox.shrink(),
              ),
              jobsAsync.maybeWhen(
                data: (jobs) {
                  final selected = jobs.where((j) => _jobs.contains(j.id)).map((j) => j.title).join(', ');
                  return _buildSummaryItem('Jobs', selected.isEmpty ? 'Not selected' : selected, Colors.white70, isMultiLine: true);
                },
                orElse: () => const SizedBox.shrink(),
              ),
              languagesAsync.maybeWhen(
                data: (languages) {
                  final selected = languages.where((l) => _languages.contains(l.id)).map((l) => l.title).join(', ');
                  return _buildSummaryItem('Languages', selected.isEmpty ? 'Not selected' : selected, Colors.white70, isMultiLine: true);
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
            isDark,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Step 4: Preferences & Lifestyle
          _buildSummaryCard(
            'Preferences & Lifestyle',
            [
              _buildSummaryItem('Age Preference', '${_minAgePreference}-${_maxAgePreference} years', Colors.white70),
              preferredGendersAsync.maybeWhen(
                data: (genders) {
                  final selected = genders.where((g) => _preferredGenders.contains(g.id)).map((g) => g.title).join(', ');
                  return _buildSummaryItem('Preferred Genders', selected.isEmpty ? 'Not selected' : selected, Colors.white70, isMultiLine: true);
                },
                orElse: () => const SizedBox.shrink(),
              ),
              relationGoalsAsync.maybeWhen(
                data: (goals) {
                  final selected = goals.where((g) => _relationGoals.contains(g.id)).map((g) => g.title).join(', ');
                  return _buildSummaryItem('Relationship Goals', selected.isEmpty ? 'Not selected' : selected, Colors.white70, isMultiLine: true);
                },
                orElse: () => const SizedBox.shrink(),
              ),
              _buildSummaryItem('Smoke', _smoke ? 'Yes' : 'No', Colors.white70),
              _buildSummaryItem('Drink', _drink ? 'Yes' : 'No', Colors.white70),
              _buildSummaryItem('Gym', _gym ? 'Yes' : 'No', Colors.white70),
            ],
            isDark,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Step 5: Interests & Music
          _buildSummaryCard(
            'Interests & Music',
            [
              ref.watch(interestsProvider).maybeWhen(
                data: (interests) {
                  final selectedTitles = interests
                      .where((i) => _interestsIds.contains(i.id))
                      .map((i) => i.title)
                      .toList();
                  if (selectedTitles.isEmpty) {
                    return _buildSummaryItem('Interests', 'Not selected', Colors.white70);
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingXS),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interests',
                          style: AppTypography.body.copyWith(color: Colors.white70),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Wrap(
                          spacing: AppSpacing.spacingXS,
                          runSpacing: AppSpacing.spacingXS,
                          children: selectedTitles.map((title) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacingSM,
                                vertical: AppSpacing.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                              ),
                              child: Text(
                                title,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => _buildSummaryItem('Interests', 'Not selected', Colors.white70),
              ),
              musicGenresAsync.maybeWhen(
                data: (genres) {
                  final selected = genres.where((g) => _musicGenres.contains(g.id)).map((g) => g.title).join(', ');
                  return _buildSummaryItem('Music Genres', selected.isEmpty ? 'Not selected' : selected, Colors.white70, isMultiLine: true);
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, {bool isMultiLine = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingXS),
      child: isMultiLine
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: AppTypography.body.copyWith(color: color),
          ),
                SizedBox(height: AppSpacing.spacingXS),
                Wrap(
                  spacing: AppSpacing.spacingXS,
                  runSpacing: AppSpacing.spacingXS,
                  children: value.split(', ').map((item) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingSM,
                        vertical: AppSpacing.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      child: Text(
                        item.trim(),
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    '$label : ',
                    style: AppTypography.body.copyWith(color: color),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: Text(
            value,
            style: AppTypography.body.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
