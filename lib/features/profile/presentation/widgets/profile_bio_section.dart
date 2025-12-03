import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

/// Profile bio section widget
/// Displays user's profile bio with proper formatting
class ProfileBioSection extends ConsumerWidget {
  final String? bio;
  final bool isEditable;
  final VoidCallback? onEdit;

  const ProfileBioSection({
    Key? key,
    this.bio,
    this.isEditable = false,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'About Me',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isEditable && onEdit != null) ...[
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Edit bio',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (bio != null && bio!.isNotEmpty)
            Text(
              bio!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            )
          else
            Text(
              isEditable
                  ? 'Tell others about yourself... Tap to add your bio'
                  : 'No bio available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
