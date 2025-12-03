import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../providers/onboarding_provider.dart';

/// Onboarding preferences screen
/// Allows users to set and update their onboarding preferences
class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() => _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState extends ConsumerState<OnboardingPreferencesScreen> {
  final TextEditingController _ageMinController = TextEditingController();
  final TextEditingController _ageMaxController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load preferences when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).loadOnboardingData();
    });
  }

  @override
  void dispose() {
    _ageMinController.dispose();
    _ageMaxController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Preferences'),
        actions: [
          TextButton(
            onPressed: () => _savePreferences(onboardingNotifier),
            child: const Text('Save'),
          ),
        ],
      ),
      body: onboardingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: onboardingState.completionPercentage,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${(onboardingState.completionPercentage * 100).round()}% Complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Relationship goal
                  _buildSection(
                    title: 'What are you looking for?',
                    icon: Icons.favorite,
                    child: _buildRelationshipGoalSelector(onboardingState, onboardingNotifier),
                  ),

                  const SizedBox(height: 24),

                  // Interests
                  _buildSection(
                    title: 'Your interests',
                    icon: Icons.interests,
                    child: _buildInterestsSelector(onboardingState, onboardingNotifier),
                  ),

                  const SizedBox(height: 24),

                  // Who to meet
                  _buildSection(
                    title: 'Who do you want to meet?',
                    icon: Icons.people,
                    child: _buildGenderSelector(onboardingState, onboardingNotifier),
                  ),

                  const SizedBox(height: 24),

                  // Age preferences
                  _buildSection(
                    title: 'Age preferences',
                    icon: Icons.calendar_today,
                    child: _buildAgeSelector(onboardingState, onboardingNotifier),
                  ),

                  const SizedBox(height: 24),

                  // Distance preferences
                  _buildSection(
                    title: 'Distance preferences',
                    icon: Icons.location_on,
                    child: _buildDistanceSelector(onboardingState, onboardingNotifier),
                  ),

                  const SizedBox(height: 24),

                  // Notifications
                  _buildSection(
                    title: 'Notifications',
                    icon: Icons.notifications,
                    child: _buildNotificationSettings(onboardingState, onboardingNotifier),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _savePreferences(onboardingNotifier),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Save Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRelationshipGoalSelector(OnboardingState state, OnboardingNotifier notifier) {
    final goals = [
      'Friendship',
      'Dating',
      'Relationship',
      'Networking',
      'Just exploring',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = state.preferences.relationshipGoal == goal;
        return FilterChip(
          label: Text(goal),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              notifier.updateRelationshipGoal(goal);
            }
          },
          selectedColor: AppColors.primaryLight.withOpacity(0.2),
          checkmarkColor: AppColors.primaryLight,
        );
      }).toList(),
    );
  }

  Widget _buildInterestsSelector(OnboardingState state, OnboardingNotifier notifier) {
    final allInterests = [
      'Music', 'Sports', 'Travel', 'Food', 'Art', 'Technology',
      'Books', 'Movies', 'Gaming', 'Fitness', 'Nature', 'Photography',
      'Cooking', 'Dancing', 'Theater', 'Volunteering', 'Pets', 'Fashion',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allInterests.map((interest) {
            final isSelected = state.preferences.interests?.contains(interest) ?? false;
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                final currentInterests = List<String>.from(state.preferences.interests ?? []);
                if (selected) {
                  currentInterests.add(interest);
                } else {
                  currentInterests.remove(interest);
                }
                notifier.updateInterests(currentInterests);
              },
              selectedColor: AppColors.primaryLight.withOpacity(0.2),
              checkmarkColor: AppColors.primaryLight,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least 3 interests',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(OnboardingState state, OnboardingNotifier notifier) {
    final genders = [
      'Men',
      'Women',
      'Non-binary',
      'Everyone',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genders.map((gender) {
        final isSelected = state.preferences.preferredGender == gender;
        return FilterChip(
          label: Text(gender),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              notifier.updatePreferredGender(gender);
            }
          },
          selectedColor: AppColors.primaryLight.withOpacity(0.2),
          checkmarkColor: AppColors.primaryLight,
        );
      }).toList(),
    );
  }

  Widget _buildAgeSelector(OnboardingState state, OnboardingNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ageMinController,
            decoration: const InputDecoration(
              labelText: 'Min Age',
              hintText: '18',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final minAge = int.tryParse(value);
              if (minAge != null && minAge >= 18) {
                notifier.updateAgeRange(minAge, state.preferences.ageRangeMax ?? 99);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _ageMaxController,
            decoration: const InputDecoration(
              labelText: 'Max Age',
              hintText: '99',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final maxAge = int.tryParse(value);
              if (maxAge != null && maxAge <= 99) {
                notifier.updateAgeRange(state.preferences.ageRangeMin ?? 18, maxAge);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSelector(OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      children: [
        Slider(
          value: state.preferences.maxDistance ?? 50,
          min: 1,
          max: 100,
          divisions: 99,
          label: '${state.preferences.maxDistance?.round() ?? 50} km',
          onChanged: (value) {
            notifier.updateMaxDistance(value);
          },
          activeColor: AppColors.primaryLight,
        ),
        Text(
          '${state.preferences.maxDistance?.round() ?? 50} kilometers',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNotificationSettings(OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Receive notifications'),
          subtitle: const Text('Get notified about matches and messages'),
          value: state.preferences.receiveNotifications ?? true,
          onChanged: (value) {
            notifier.updateReceiveNotifications(value);
          },
          activeColor: AppColors.primaryLight,
        ),
      ],
    );
  }

  void _savePreferences(OnboardingNotifier notifier) async {
    final success = await notifier.completeOnboarding();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to discover
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
