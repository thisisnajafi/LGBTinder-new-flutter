// Screen: OnboardingPreferencesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/app_list_view.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../features/onboarding/presentation/widgets/onboarding_preferences_form.dart';
import '../../features/onboarding/utils/onboarding_preferences_draft.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/reference_data/providers/reference_data_providers.dart';
import '../../shared/models/api_error.dart';
import '../../routes/app_router.dart';

/// Onboarding preferences screen - Preference selection during onboarding
class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends ConsumerState<OnboardingPreferencesScreen> {
  static const int _sectionCount = 7;

  final _loading = ValueNotifier<bool>(true);
  final _saving = ValueNotifier<bool>(false);
  final _options =
      ValueNotifier<OnboardingPreferenceOptions>(const OnboardingPreferenceOptions());
  final _preferredGenderIds = ValueNotifier<List<int>>(const []);
  final _ageRange = ValueNotifier<RangeValues>(const RangeValues(18, 100));
  final _maxDistance = ValueNotifier<double>(50);
  final _relationGoalIds = ValueNotifier<List<int>>(const []);
  final _interestIds = ValueNotifier<List<int>>(const []);

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _loading.dispose();
    _saving.dispose();
    _options.dispose();
    _preferredGenderIds.dispose();
    _ageRange.dispose();
    _maxDistance.dispose();
    _relationGoalIds.dispose();
    _interestIds.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        ref.read(preferredGendersProvider.future),
        ref.read(relationshipGoalsProvider.future),
        ref.read(interestsProvider.future),
      ]);
      if (!mounted) return;
      _options.value = OnboardingPreferenceOptions(
        preferredGenders: results[0],
        relationGoals: results[1],
        interests: results[2],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load preferences: $e'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    } finally {
      if (mounted) _loading.value = false;
    }
  }

  OnboardingPreferencesDraft _draft() {
    return OnboardingPreferencesDraft(
      preferredGenderIds: _preferredGenderIds.value,
      ageRange: _ageRange.value,
      maxDistance: _maxDistance.value,
      relationGoalIds: _relationGoalIds.value,
      interestIds: _interestIds.value,
    );
  }

  Future<void> _savePreferences() async {
    if (_saving.value) return;
    final draft = _draft();
    if (!draft.hasMinimumInterests) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 3 interests'),
          backgroundColor: AppColors.feedbackWarning,
        ),
      );
      return;
    }

    _saving.value = true;
    try {
      await ref.read(profileServiceProvider).updateProfile(
            draft.toUpdateProfileRequest(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
      context.go(AppRoutes.home);
    } on ApiError catch (e) {
      if (!mounted) return;
      final errorMessage =
          e.errors != null && e.errors!.isNotEmpty ? e.getAllErrors() : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $errorMessage'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $e'),
          backgroundColor: AppColors.feedbackError,
        ),
      );
    } finally {
      if (mounted) _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return AppPageScaffold(
      title: 'Set Your Preferences',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ValueListenableBuilder<bool>(
        valueListenable: _loading,
        builder: (context, loading, _) {
          if (loading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
              ),
            );
          }
          return ValueListenableBuilder<OnboardingPreferenceOptions>(
            valueListenable: _options,
            builder: (context, options, _) {
              return AppListView.builder(
                key: const ValueKey('onboarding_preferences_list'),
                padding: ResponsivePadding.page(context),
                itemCount: _sectionCount,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return const OnboardingPreferencesHeader();
                    case 1:
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacingXXL),
                        child: OnboardingChipSection(
                          title: 'Looking For',
                          items: options.preferredGenders,
                          selectedIds: _preferredGenderIds,
                        ),
                      );
                    case 2:
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacingXL),
                        child: OnboardingAgeRangeSection(ageRange: _ageRange),
                      );
                    case 3:
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacingXL),
                        child: OnboardingDistanceSection(
                          maxDistance: _maxDistance,
                        ),
                      );
                    case 4:
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacingXL),
                        child: OnboardingChipSection(
                          title: 'Relationship Goals',
                          items: options.relationGoals,
                          selectedIds: _relationGoalIds,
                        ),
                      );
                    case 5:
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.spacingXL),
                        child: OnboardingChipSection(
                          title: 'Interests',
                          caption: 'Select at least 3 interests',
                          items: options.interests,
                          selectedIds: _interestIds,
                        ),
                      );
                    case 6:
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacingXXL,
                        ),
                        child: OnboardingPreferencesSaveRow(
                          saving: _saving,
                          onSave: _savePreferences,
                        ),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
