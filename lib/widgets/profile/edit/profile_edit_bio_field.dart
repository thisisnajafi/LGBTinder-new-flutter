import 'package:flutter/material.dart';

import '../../../core/widgets/premium/premium_design_system.dart';

/// Bio editor that talks only to [controller] — typing never calls parent
/// `setState` (PERF-PAGE-PROFILEEDIT-002).
class ProfileEditBioField extends StatelessWidget {
  const ProfileEditBioField({
    super.key,
    required this.controller,
  });

  static const fieldKey = ValueKey<String>('profile-edit-bio-field');

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PremiumTextField(
      key: fieldKey,
      controller: controller,
      label: 'Bio',
      hintText: 'Tell others about yourself',
      maxLines: 5,
      minLines: 4,
      maxLength: 500,
    );
  }
}
