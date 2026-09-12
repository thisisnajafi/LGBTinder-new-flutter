import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/metric_slider_tile.dart';
import '../../../core/widgets/premium/premium_design_system.dart';

/// Mutable about-me values owned by [ProfileEditAboutMeSection].
/// The parent reads this on save instead of rebuilding on every slider tick.
class ProfileEditAboutMeValues {
  ProfileEditAboutMeValues({
    this.height,
    this.weight,
    this.smoke = false,
    this.drink = false,
    this.gym = false,
  });

  int? height;
  int? weight;
  bool smoke;
  bool drink;
  bool gym;
}

/// Height / weight / lifestyle toggles with local [setState] only
/// (PERF-PAGE-PROFILEEDIT-002).
class ProfileEditAboutMeSection extends StatefulWidget {
  const ProfileEditAboutMeSection({
    super.key,
    required this.values,
  });

  static const sectionKey = ValueKey<String>('profile-edit-about-me');

  final ProfileEditAboutMeValues values;

  @override
  State<ProfileEditAboutMeSection> createState() =>
      _ProfileEditAboutMeSectionState();
}

class _ProfileEditAboutMeSectionState extends State<ProfileEditAboutMeSection> {
  late int _height;
  late int _weight;
  late bool _smoke;
  late bool _drink;
  late bool _gym;

  @override
  void initState() {
    super.initState();
    _syncFromValues();
  }

  @override
  void didUpdateWidget(covariant ProfileEditAboutMeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.values, widget.values)) {
      _syncFromValues();
    }
  }

  void _syncFromValues() {
    _height = widget.values.height ?? 170;
    _weight = widget.values.weight ?? 70;
    _smoke = widget.values.smoke;
    _drink = widget.values.drink;
    _gym = widget.values.gym;
  }

  void _setHeight(int value) {
    widget.values.height = value;
    setState(() => _height = value);
  }

  void _setWeight(int value) {
    widget.values.weight = value;
    setState(() => _weight = value);
  }

  void _setSmoke(bool value) {
    widget.values.smoke = value;
    setState(() => _smoke = value);
  }

  void _setDrink(bool value) {
    widget.values.drink = value;
    setState(() => _drink = value);
  }

  void _setGym(bool value) {
    widget.values.gym = value;
    setState(() => _gym = value);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsGroup(
      key: ProfileEditAboutMeSection.sectionKey,
      title: 'About me',
      subtitle: 'The details that help you match better',
      children: [
        PremiumInsetCard(
          child: HeightSliderTile(
            value: _height,
            onChanged: _setHeight,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        PremiumInsetCard(
          child: WeightSliderTile(
            value: _weight,
            onChanged: _setWeight,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
        PremiumToggleRow(
          title: 'Smoking',
          subtitle: _smoke ? 'Yes' : 'No',
          iconPath: AppIcons.getIconPath('cloud'),
          value: _smoke,
          onChanged: _setSmoke,
        ),
        PremiumToggleRow(
          title: 'Drinking',
          subtitle: _drink ? 'Yes' : 'No',
          iconPath: AppIcons.getIconPath('glass'),
          value: _drink,
          onChanged: _setDrink,
        ),
        PremiumToggleRow(
          title: 'Gym',
          subtitle: _gym ? 'Active' : 'Sometimes',
          iconPath: AppIcons.getIconPath('weight'),
          accent: AppColors.warningYellow,
          value: _gym,
          onChanged: _setGym,
        ),
      ],
    );
  }
}
