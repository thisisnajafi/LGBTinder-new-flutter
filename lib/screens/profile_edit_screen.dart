// Screen: ProfileEditScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/profile/avatar_upload.dart';
import '../widgets/profile/photo_gallery.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/alert_dialog_custom.dart';
import '../features/reference_data/providers/reference_data_providers.dart';
import '../features/reference_data/data/models/reference_item.dart';

/// Profile edit screen - Full profile editing interface
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Basic info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  DateTime? _birthDate;
  int? _age;

  // Images
  List<String> _imageUrls = [];
  String? _avatarUrl;

  // Preferences
  List<String> _selectedInterests = [];
  List<String> _selectedJobs = [];
  List<String> _selectedEducations = [];
  List<String> _selectedLanguages = [];
  List<String> _selectedMusicGenres = [];
  List<String> _selectedRelationGoals = [];
  String? _selectedGender;
  List<String> _selectedPreferredGenders = [];

  // Details
  int? _height; // in cm
  int? _weight; // in kg
  bool? _smoke;
  bool? _drink;
  bool? _gym;

  // Age preferences
  int? _minAgePreference;
  int? _maxAgePreference;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load profile from API
      // GET /api/profile
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _firstNameController.text = 'John';
          _lastNameController.text = 'Doe';
          _bioController.text = 'Love music and travel';
          _cityController.text = 'New York';
          _countryController.text = 'United States';
          _birthDate = DateTime(1990, 1, 1);
          _age = 34;
          _avatarUrl = null;
          _imageUrls = [];
          _selectedInterests = ['Music', 'Travel'];
          _selectedJobs = ['Software Engineer'];
          _selectedEducations = ['University'];
          _selectedLanguages = ['English', 'Spanish'];
          _selectedMusicGenres = ['Pop', 'Rock'];
          _selectedRelationGoals = ['Long-term'];
          _selectedGender = 'Male';
          _selectedPreferredGenders = ['Male', 'Female'];
          _height = 180;
          _weight = 75;
          _smoke = false;
          _drink = true;
          _gym = true;
          _minAgePreference = 25;
          _maxAgePreference = 40;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
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

  // Helper methods to convert selected string titles to IDs
  List<int> _convertTitlesToIds(List<String> selectedTitles, List<ReferenceItem> referenceItems) {
    return selectedTitles.map((title) {
      final item = referenceItems.firstWhere(
        (item) => item.title == title,
        orElse: () => ReferenceItem(id: 0, title: ''),
      );
      return item.id;
    }).where((id) => id != 0).toList();
  }

  int? _convertTitleToId(String? selectedTitle, List<ReferenceItem> referenceItems) {
    if (selectedTitle == null || selectedTitle.isEmpty) return null;

    final item = referenceItems.firstWhere(
      (item) => item.title == selectedTitle,
      orElse: () => ReferenceItem(id: 0, title: ''),
    );
    return item.id == 0 ? null : item.id;
  }

  List<String> _convertIdsToTitles(List<int> ids, List<ReferenceItem> referenceItems) {
    return ids.map((id) {
      final item = referenceItems.firstWhere(
        (item) => item.id == id,
        orElse: () => ReferenceItem(id: 0, title: ''),
      );
      return item.title.isNotEmpty ? item.title : '';
    }).where((title) => title.isNotEmpty).toList();
  }

  String? _convertIdToTitle(int? id, List<ReferenceItem> referenceItems) {
    if (id == null) return null;

    final item = referenceItems.firstWhere(
      (item) => item.id == id,
      orElse: () => ReferenceItem(id: 0, title: ''),
    );
    return item.title.isNotEmpty ? item.title : null;
  }

  Future<void> _loadProfileFromApi() async {
    // TODO: Load profile from API and convert IDs to titles
    // GET /api/profile
    // This method will load profile data and convert IDs back to display titles

    // Load all reference data
    final interestsAsync = ref.read(interestsProvider);
    final jobsAsync = ref.read(jobsProvider);
    final educationAsync = ref.read(educationLevelsProvider);
    final languagesAsync = ref.read(languagesProvider);
    final musicGenresAsync = ref.read(musicGenresProvider);
    final relationshipGoalsAsync = ref.read(relationshipGoalsProvider);
    final gendersAsync = ref.read(gendersProvider);
    final preferredGendersAsync = ref.read(preferredGendersProvider);

    // Wait for all data to load
    final results = await Future.wait([
      interestsAsync,
      jobsAsync,
      educationAsync,
      languagesAsync,
      musicGenresAsync,
      relationshipGoalsAsync,
      gendersAsync,
      preferredGendersAsync,
    ]);

    final interests = results[0] as List<ReferenceItem>;
    final jobs = results[1] as List<ReferenceItem>;
    final educationLevels = results[2] as List<ReferenceItem>;
    final languages = results[3] as List<ReferenceItem>;
    final musicGenres = results[4] as List<ReferenceItem>;
    final relationshipGoals = results[5] as List<ReferenceItem>;
    final genders = results[6] as List<ReferenceItem>;
    final preferredGenders = results[7] as List<ReferenceItem>;

    // TODO: Fetch profile data from API
    // For now, simulate API response with IDs
    final apiProfileData = {
      'first_name': 'John',
      'last_name': 'Doe',
      'profile_bio': 'Love music and travel',
      'city': 'New York',
      'country': 'United States',
      'birth_date': '1990-01-01',
      'interest_ids': [1, 2], // IDs from API
      'job_ids': [1], // IDs from API
      'education_ids': [1], // IDs from API
      'language_ids': [1, 2], // IDs from API
      'music_genre_ids': [1, 2], // IDs from API
      'relationship_goal_ids': [1], // IDs from API
      'gender_id': 1, // ID from API
      'preferred_gender_ids': [1, 2], // IDs from API
      'height': 180,
      'weight': 75,
    };

    // Convert IDs back to titles for display
    final interestTitles = _convertIdsToTitles(apiProfileData['interest_ids'] as List<int>, interests);
    final jobTitles = _convertIdsToTitles(apiProfileData['job_ids'] as List<int>, jobs);
    final educationTitles = _convertIdsToTitles(apiProfileData['education_ids'] as List<int>, educationLevels);
    final languageTitles = _convertIdsToTitles(apiProfileData['language_ids'] as List<int>, languages);
    final musicGenreTitles = _convertIdsToTitles(apiProfileData['music_genre_ids'] as List<int>, musicGenres);
    final relationshipGoalTitles = _convertIdsToTitles(apiProfileData['relationship_goal_ids'] as List<int>, relationshipGoals);
    final genderTitle = _convertIdToTitle(apiProfileData['gender_id'] as int?, genders);
    final preferredGenderTitles = _convertIdsToTitles(apiProfileData['preferred_gender_ids'] as List<int>, preferredGenders);

    // Update state with converted titles
    setState(() {
      _firstNameController.text = apiProfileData['first_name'] as String? ?? '';
      _lastNameController.text = apiProfileData['last_name'] as String? ?? '';
      _bioController.text = apiProfileData['profile_bio'] as String? ?? '';
      _cityController.text = apiProfileData['city'] as String? ?? '';
      _countryController.text = apiProfileData['country'] as String? ?? '';
      _birthDate = apiProfileData['birth_date'] != null
          ? DateTime.parse(apiProfileData['birth_date'] as String)
          : null;
      _selectedInterests = interestTitles;
      _selectedJobs = jobTitles;
      _selectedEducations = educationTitles;
      _selectedLanguages = languageTitles;
      _selectedMusicGenres = musicGenreTitles;
      _selectedRelationGoals = relationshipGoalTitles;
      _selectedGender = genderTitle;
      _selectedPreferredGenders = preferredGenderTitles;
      _height = apiProfileData['height'] as int?;
      _weight = apiProfileData['weight'] as int?;
    });
  }

  Future<Map<String, dynamic>> _prepareProfileData() async {
    // Load all reference data
    final interestsAsync = ref.read(interestsProvider);
    final jobsAsync = ref.read(jobsProvider);
    final educationAsync = ref.read(educationLevelsProvider);
    final languagesAsync = ref.read(languagesProvider);
    final musicGenresAsync = ref.read(musicGenresProvider);
    final relationshipGoalsAsync = ref.read(relationshipGoalsProvider);
    final gendersAsync = ref.read(gendersProvider);
    final preferredGendersAsync = ref.read(preferredGendersProvider);

    // Wait for all data to load
    final results = await Future.wait([
      interestsAsync,
      jobsAsync,
      educationAsync,
      languagesAsync,
      musicGenresAsync,
      relationshipGoalsAsync,
      gendersAsync,
      preferredGendersAsync,
    ]);

    final interests = results[0] as List<ReferenceItem>;
    final jobs = results[1] as List<ReferenceItem>;
    final educationLevels = results[2] as List<ReferenceItem>;
    final languages = results[3] as List<ReferenceItem>;
    final musicGenres = results[4] as List<ReferenceItem>;
    final relationshipGoals = results[5] as List<ReferenceItem>;
    final genders = results[6] as List<ReferenceItem>;
    final preferredGenders = results[7] as List<ReferenceItem>;

    // Convert selected titles to IDs
    final interestIds = _convertTitlesToIds(_selectedInterests, interests);
    final jobIds = _convertTitlesToIds(_selectedJobs, jobs);
    final educationIds = _convertTitlesToIds(_selectedEducations, educationLevels);
    final languageIds = _convertTitlesToIds(_selectedLanguages, languages);
    final musicGenreIds = _convertTitlesToIds(_selectedMusicGenres, musicGenres);
    final relationshipGoalIds = _convertTitlesToIds(_selectedRelationGoals, relationshipGoals);
    final genderId = _convertTitleToId(_selectedGender, genders);
    final preferredGenderIds = _convertTitlesToIds(_selectedPreferredGenders, preferredGenders);

    return {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'profile_bio': _bioController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'birth_date': _birthDate?.toIso8601String().split('T')[0],
      'interest_ids': interestIds,
      'job_ids': jobIds,
      'education_ids': educationIds,
      'language_ids': languageIds,
      'music_genre_ids': musicGenreIds,
      'relationship_goal_ids': relationshipGoalIds,
      'gender_id': genderId,
      'preferred_gender_ids': preferredGenderIds,
      'height': _height,
      'weight': _weight,
      'smoke': _smoke,
      'drink': _drink,
      'exercise': _exercise,
      'religion': _religion,
      'political_views': _politicalViews,
      'zodiac_sign': _zodiacSign,
      'education_level': _educationLevel,
      'work_status': _workStatus,
      'income_range': _incomeRange,
      'relationship_status': _relationshipStatus,
    };
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare profile data with proper ID conversions
      final profileData = await _prepareProfileData();

      // TODO: Save profile via API
      // PUT /api/profile
      // For now, just show success message
        'height': _height,
        'weight': _weight,
        'smoke': _smoke,
        'drink': _drink,
        'gym': _gym,
        'min_age_preference': _minAgePreference,
        'max_age_preference': _maxAgePreference,
      };

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Profile Updated',
          message: 'Your profile has been successfully updated!',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _age = DateTime.now().difference(picked).inDays ~/ 365;
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBarCustom(
          title: 'Edit Profile',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Edit Profile',
        showBackButton: true,
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          children: [
            // Avatar
            SectionHeader(
              title: 'Profile Photo',
              icon: Icons.camera_alt,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Center(
              child: AvatarUpload(
                imageUrl: _avatarUrl,
                name: '${_firstNameController.text} ${_lastNameController.text}',
                size: 120.0,
                onUpload: () {
                  // TODO: Open image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker coming soon')),
                  );
                },
                onEdit: () {
                  // TODO: Open image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image picker coming soon')),
                  );
                },
              ),
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Basic Information
            SectionHeader(
              title: 'Basic Information',
              icon: Icons.person,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildDateField(
              label: 'Birth Date',
              value: _birthDate,
              age: _age,
              onTap: _selectBirthDate,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.description,
              maxLines: 4,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Location
            SectionHeader(
              title: 'Location',
              icon: Icons.location_on,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTextField(
              controller: _cityController,
              label: 'City',
              icon: Icons.location_city,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTextField(
              controller: _countryController,
              label: 'Country',
              icon: Icons.public,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Photos
            SectionHeader(
              title: 'Photos',
              icon: Icons.photo_library,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            PhotoGallery(
              imageUrls: _imageUrls,
              isEditable: true,
              onAddPhoto: () {
                // TODO: Open image picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image picker coming soon')),
                );
              },
              onImageTap: (index, url) {
                // TODO: Open image viewer/editor
              },
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Interests
            SectionHeader(
              title: 'Interests',
              icon: Icons.favorite,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildMultiSelectField(
              label: 'Select Interests',
              selectedItems: _selectedInterests,
              onTap: () {
                // TODO: Open interests selection screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Interests selection coming soon')),
                );
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Details
            SectionHeader(
              title: 'Details',
              icon: Icons.info,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildNumberField(
              label: 'Height (cm)',
              value: _height,
              onChanged: (value) {
                setState(() {
                  _height = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildNumberField(
              label: 'Weight (kg)',
              value: _weight,
              onChanged: (value) {
                setState(() {
                  _weight = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTriStateField(
              label: 'Smoking',
              value: _smoke,
              onChanged: (value) {
                setState(() {
                  _smoke = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTriStateField(
              label: 'Drinking',
              value: _drink,
              onChanged: (value) {
                setState(() {
                  _drink = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildTriStateField(
              label: 'Gym',
              value: _gym,
              onChanged: (value) {
                setState(() {
                  _gym = value;
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Age Preferences
            SectionHeader(
              title: 'Age Preferences',
              icon: Icons.filter_list,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    label: 'Min Age',
                    value: _minAgePreference,
                    onChanged: (value) {
                      setState(() {
                        _minAgePreference = value;
                      });
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: _buildNumberField(
                    label: 'Max Age',
                    value: _maxAgePreference,
                    onChanged: (value) {
                      setState(() {
                        _maxAgePreference = value;
                      });
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacingXXL),
            GradientButton(
              text: 'Save Profile',
              onPressed: _isSaving ? null : _saveProfile,
              isLoading: _isSaving,
              isFullWidth: true,
              icon: Icons.save,
            ),
            SizedBox(height: AppSpacing.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
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
          prefixIcon: icon != null ? Icon(icon, color: secondaryTextColor) : null,
        ),
        style: AppTypography.body.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    int? age,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
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
            prefixIcon: Icon(Icons.calendar_today, color: secondaryTextColor),
            suffixIcon: value != null
                ? Text(
                    age != null ? '$age years old' : '',
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  )
                : null,
          ),
          child: Text(
            value != null
                ? '${value.day}/${value.month}/${value.year}'
                : 'Select date',
            style: AppTypography.body.copyWith(
              color: value != null ? textColor : secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int? value,
    required Function(int?) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: TextFormField(
        initialValue: value?.toString(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
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
        ),
        style: AppTypography.body.copyWith(color: textColor),
        onChanged: (value) {
          onChanged(value.isEmpty ? null : int.tryParse(value));
        },
      ),
    );
  }

  Widget _buildTriStateField({
    required String label,
    required bool? value,
    required Function(bool?) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _buildTriStateOption(
                label: 'No',
                isSelected: value == false,
                onTap: () => onChanged(false),
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              _buildTriStateOption(
                label: 'Sometimes',
                isSelected: value == null,
                onTap: () => onChanged(null),
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              _buildTriStateOption(
                label: 'Yes',
                isSelected: value == true,
                onTap: () => onChanged(true),
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriStateOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPurple
              : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPurple
                : borderColor,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required List<String> selectedItems,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: secondaryTextColor,
                ),
              ],
            ),
            if (selectedItems.isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacingMD),
              Wrap(
                spacing: AppSpacing.spacingSM,
                runSpacing: AppSpacing.spacingSM,
                children: selectedItems.map((item) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      border: Border.all(
                        color: AppColors.accentPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      item,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentPurple,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                'Tap to select',
                style: AppTypography.caption.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
