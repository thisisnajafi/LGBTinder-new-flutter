// Screen: ProfileWizardScreen
// Multi-step profile setup wizard matching backend structure
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/profile/avatar_upload.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import '../../widgets/common/selection_bottom_sheet.dart';
import '../../features/reference_data/data/models/reference_item.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/profile/data/models/update_profile_request.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../core/utils/app_icons.dart';

/// Profile wizard screen - Multi-step profile setup wizard
/// Steps match backend: basic_info, preferences, interests, photos, final
class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5; // basic_info, preferences, interests, photos, final
  bool _isSaving = false;

  // Step 1: Basic Information (basic_info)
  String? _avatarUrl;
  ReferenceItem? _selectedGender;
  DateTime? _birthDate;
  final _phoneController = TextEditingController();
  String? _countryCode;
  ReferenceItem? _selectedCountry;
  ReferenceItem? _selectedCity;

  // Step 2: Preferences
  List<ReferenceItem> _selectedPreferredGenders = [];
  List<ReferenceItem> _selectedRelationGoals = [];
  int _minAgePreference = 18;
  int _maxAgePreference = 100;

  // Step 3: Interests & Lifestyle
  final _bioController = TextEditingController();
  int? _height;
  int? _weight;
  bool? _smoke;
  bool? _drink;
  bool? _gym;
  List<ReferenceItem> _selectedMusicGenres = [];
  List<ReferenceItem> _selectedEducations = [];
  List<ReferenceItem> _selectedJobs = [];
  List<ReferenceItem> _selectedLanguages = [];
  List<ReferenceItem> _selectedInterests = [];

  // Step 4: Photos (placeholder for now)
  List<String> _photos = [];

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
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
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeWizard() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final profileNotifier = ref.read(profileProvider.notifier);
      final request = UpdateProfileRequest(
        profileBio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        preferredGenders: _selectedPreferredGenders.map((item) => item.id).toList(),
        relationGoals: _selectedRelationGoals.map((item) => item.id).toList(),
        minAgePreference: _minAgePreference,
        maxAgePreference: _maxAgePreference,
        musicGenres: _selectedMusicGenres.map((item) => item.id).toList(),
        educations: _selectedEducations.map((item) => item.id).toList(),
        jobs: _selectedJobs.map((item) => item.id).toList(),
        languages: _selectedLanguages.map((item) => item.id).toList(),
        interests: _selectedInterests.map((item) => item.id).toList(),
      );

      await profileNotifier.updateProfile(request);

      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Profile Complete!',
          message: 'Your profile has been set up successfully. Start discovering matches!',
          icon: AppSvgIcon(
            assetPath: AppIcons.checkCircle,
            size: 24,
            color: AppColors.onlineGreen,
          ),
          iconColor: AppColors.onlineGreen,
        ).then((_) {
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go('/home');
          }
        });
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
        title: 'Setup Profile',
        showBackButton: false,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                'Back',
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: AppTypography.body.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.spacingSM),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1BasicInfo(textColor, secondaryTextColor, surfaceColor, borderColor),
                _buildStep2Preferences(textColor, secondaryTextColor, surfaceColor, borderColor),
                _buildStep3Interests(textColor, secondaryTextColor, surfaceColor, borderColor),
                _buildStep4Photos(textColor, secondaryTextColor, surfaceColor, borderColor),
                _buildStep5Final(textColor, secondaryTextColor, surfaceColor, borderColor),
              ],
            ),
          ),
          // Navigation buttons
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
              child: GradientButton(
                text: _currentStep == _totalSteps - 1
                    ? (_isSaving ? 'Completing...' : 'Complete Profile')
                    : 'Next',
                onPressed: _isSaving ? null : _nextStep,
                isLoading: _isSaving && _currentStep == _totalSteps - 1,
                isFullWidth: true,
                icon: AppSvgIcon(
                  assetPath: _currentStep == _totalSteps - 1 ? AppIcons.checkCircle : AppIcons.forward,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Basic Information (gender, birth_date, phone_number, city, country, country_code)
  Widget _buildStep1BasicInfo(
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final gendersAsync = ref.watch(gendersProvider);
    final countriesAsync = ref.watch(countriesProvider);
    final citiesAsync = _selectedCountry != null
        ? ref.watch(citiesProvider(_selectedCountry!.id))
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Basic Information',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Tell us about yourself',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Gender selection
          gendersAsync.when(
            data: (genders) => _buildSelectField<ReferenceItem>(
              label: 'Gender *',
              value: _selectedGender,
              items: genders,
              getTitle: (item) => item.title,
              onSelect: (item) => setState(() => _selectedGender = item),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading genders...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load genders', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Birth date selection
          _buildDateField(
            label: 'Birth Date *',
            value: _birthDate,
            onSelect: (date) => setState(() => _birthDate = date),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Phone number
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: '+1234567890',
              prefixIcon: AppSvgIcon(
                assetPath: AppIcons.phone,
                size: 20,
                color: secondaryTextColor,
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            style: AppTypography.body.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Country selection (with search)
          countriesAsync.when(
            data: (countries) => _buildSelectField<ReferenceItem>(
              label: 'Country *',
              value: _selectedCountry,
              items: countries,
              getTitle: (item) => item.title,
              onSelect: (item) {
                setState(() {
                  _selectedCountry = item;
                  _selectedCity = null; // Reset city when country changes
                  _countryCode = item.code;
                });
              },
              searchable: true,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading countries...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load countries', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // City selection (with search, only if country is selected)
          if (_selectedCountry != null)
            citiesAsync != null
                ? citiesAsync.when(
                    data: (cities) => _buildSelectField<ReferenceItem>(
                      label: 'City *',
                      value: _selectedCity,
                      items: cities,
                      getTitle: (item) => item.title,
                      onSelect: (item) => setState(() => _selectedCity = item),
                      searchable: true,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                    loading: () => _buildLoadingField('Loading cities...', textColor, surfaceColor, borderColor),
                    error: (error, stack) => _buildErrorField('Failed to load cities', textColor, surfaceColor, borderColor),
                  )
                : SizedBox.shrink(),
        ],
      ),
    );
  }

  // Step 2: Preferences (preferred_genders, relation_goals, min_age_preference, max_age_preference)
  Widget _buildStep2Preferences(
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final preferredGendersAsync = ref.watch(preferredGendersProvider);
    final relationGoalsAsync = ref.watch(relationshipGoalsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preferences',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Set your dating preferences',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Preferred Genders (multi-select)
          preferredGendersAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Preferred Genders *',
              selectedItems: _selectedPreferredGenders,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedPreferredGenders = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading preferred genders...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load preferred genders', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Relation Goals (multi-select)
          relationGoalsAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Relationship Goals *',
              selectedItems: _selectedRelationGoals,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedRelationGoals = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading relationship goals...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load relationship goals', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Age Range
          Text(
            'Age Range *',
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          RangeSlider(
            values: RangeValues(_minAgePreference.toDouble(), _maxAgePreference.toDouble()),
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              _minAgePreference.toString(),
              _maxAgePreference.toString(),
            ),
            activeColor: AppColors.accentPurple,
            onChanged: (RangeValues values) {
              setState(() {
                _minAgePreference = values.start.round();
                _maxAgePreference = values.end.round();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: $_minAgePreference',
                style: AppTypography.body.copyWith(color: textColor),
              ),
              Text(
                'Max: $_maxAgePreference',
                style: AppTypography.body.copyWith(color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Interests & Lifestyle (music_genres, educations, jobs, languages, interests, profile_bio, height, weight, smoke, drink, gym)
  Widget _buildStep3Interests(
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final musicGenresAsync = ref.watch(musicGenresProvider);
    final educationsAsync = ref.watch(educationLevelsProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final languagesAsync = ref.watch(languagesProvider);
    final interestsAsync = ref.watch(interestsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Interests & Lifestyle',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Share your interests and lifestyle',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Bio
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Profile Bio *',
              hintText: 'Tell us about yourself...',
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            style: AppTypography.body.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Height and Weight
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Height (cm) *',
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  style: AppTypography.body.copyWith(color: textColor),
                  onChanged: (value) {
                    setState(() {
                      _height = value.isEmpty ? null : int.tryParse(value);
                    });
                  },
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg) *',
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  style: AppTypography.body.copyWith(color: textColor),
                  onChanged: (value) {
                    setState(() {
                      _weight = value.isEmpty ? null : int.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Lifestyle choices
          _buildTriStateField(
            label: 'Smoking *',
            value: _smoke,
            onChanged: (value) => setState(() => _smoke = value),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildTriStateField(
            label: 'Drinking *',
            value: _drink,
            onChanged: (value) => setState(() => _drink = value),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildTriStateField(
            label: 'Gym *',
            value: _gym,
            onChanged: (value) => setState(() => _gym = value),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Music Genres (multi-select)
          musicGenresAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Music Genres *',
              selectedItems: _selectedMusicGenres,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedMusicGenres = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading music genres...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load music genres', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Education (multi-select)
          educationsAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Education *',
              selectedItems: _selectedEducations,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedEducations = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading education levels...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load education levels', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Jobs (multi-select)
          jobsAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Jobs *',
              selectedItems: _selectedJobs,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedJobs = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading jobs...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load jobs', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Languages (multi-select)
          languagesAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Languages *',
              selectedItems: _selectedLanguages,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedLanguages = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading languages...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load languages', textColor, surfaceColor, borderColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          // Interests (multi-select)
          interestsAsync.when(
            data: (items) => _buildMultiSelectField<ReferenceItem>(
              label: 'Interests *',
              selectedItems: _selectedInterests,
              items: items,
              getTitle: (item) => item.title,
              onSelect: (items) => setState(() => _selectedInterests = items),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            loading: () => _buildLoadingField('Loading interests...', textColor, surfaceColor, borderColor),
            error: (error, stack) => _buildErrorField('Failed to load interests', textColor, surfaceColor, borderColor),
          ),
        ],
      ),
    );
  }

  // Step 4: Photos
  Widget _buildStep4Photos(
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Photos',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Add your best photos',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          Center(
            child: AvatarUpload(
              imageUrl: _avatarUrl,
              name: 'You',
              size: 120.0,
              onUpload: () {
                // Open image picker - implementation needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image picker coming soon')),
                );
              },
              onEdit: () {
                // Open image picker - implementation needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image picker coming soon')),
                );
              },
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          Text(
            'Photo upload functionality will be implemented here',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Step 5: Final Review
  Widget _buildStep5Final(
    Color textColor,
    Color secondaryTextColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review & Complete',
            style: AppTypography.h1.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Review your profile and complete setup',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          // Summary of selections
          _buildSummaryItem('Gender', _selectedGender?.title ?? 'Not selected', textColor),
          _buildSummaryItem('Country', _selectedCountry?.title ?? 'Not selected', textColor),
          _buildSummaryItem('City', _selectedCity?.title ?? 'Not selected', textColor),
          _buildSummaryItem('Preferred Genders', '${_selectedPreferredGenders.length} selected', textColor),
          _buildSummaryItem('Relationship Goals', '${_selectedRelationGoals.length} selected', textColor),
          _buildSummaryItem('Age Range', '$_minAgePreference - $_maxAgePreference', textColor),
          _buildSummaryItem('Music Genres', '${_selectedMusicGenres.length} selected', textColor),
          _buildSummaryItem('Education', '${_selectedEducations.length} selected', textColor),
          _buildSummaryItem('Jobs', '${_selectedJobs.length} selected', textColor),
          _buildSummaryItem('Languages', '${_selectedLanguages.length} selected', textColor),
          _buildSummaryItem('Interests', '${_selectedInterests.length} selected', textColor),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSelectField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) getTitle,
    required Function(T) onSelect,
    bool searchable = false,
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
        onTap: () async {
          final selected = await SelectionBottomSheet.showSingleSelect<T>(
            context: context,
            title: label,
            items: items,
            getTitle: getTitle,
            selectedItem: value,
            searchable: searchable,
          );
          if (selected != null) {
            onSelect(selected);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (value != null) ...[
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      getTitle(value),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentPurple,
                      ),
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
            AppSvgIcon(
              assetPath: AppIcons.chevronRight,
              size: 20,
              color: secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectField<T>({
    required String label,
    required List<T> selectedItems,
    required List<T> items,
    required String Function(T) getTitle,
    required Function(List<T>) onSelect,
    bool searchable = false,
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
        onTap: () async {
          final selected = await SelectionBottomSheet.showMultiSelect<T>(
            context: context,
            title: label,
            items: items,
            getTitle: getTitle,
            selectedItems: selectedItems,
            searchable: searchable,
          );
          if (selected != null) {
            onSelect(selected);
          }
        },
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
                AppSvgIcon(
              assetPath: AppIcons.chevronRight,
              size: 20,
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
                      getTitle(item),
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

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime) onSelect,
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
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now().subtract(Duration(days: 365 * 25)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
            builder: (context, child) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return Theme(
                data: theme.copyWith(
                  colorScheme: ColorScheme.dark(
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
          if (date != null) {
            onSelect(date);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (value != null) ...[
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      '${value.day}/${value.month}/${value.year}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentPurple,
                      ),
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
            AppSvgIcon(
              assetPath: AppIcons.calendarToday,
              size: 20,
              color: secondaryTextColor,
            ),
          ],
        ),
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
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              _buildTriStateOption(
                label: 'Sometimes',
                isSelected: value == null,
                onTap: () => onChanged(null),
                textColor: textColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              _buildTriStateOption(
                label: 'Yes',
                isSelected: value == true,
                onTap: () => onChanged(true),
                textColor: textColor,
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
          color: isSelected ? AppColors.accentPurple : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : borderColor,
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

  Widget _buildLoadingField(String message, Color textColor, Color surfaceColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Text(
            message,
            style: AppTypography.body.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorField(String message, Color textColor, Color surfaceColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: AppIcons.errorOutline,
            size: 20,
            color: Colors.red,
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: textColor),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.accentPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
