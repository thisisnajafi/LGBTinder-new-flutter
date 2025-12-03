import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';

/// Report category tile widget
/// Displays report reason categories with icons and descriptions
class ReportCategoryTile extends ConsumerWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const ReportCategoryTile({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? AppColors.primaryLight.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _getCategoryColor(),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected) ...[
                const SizedBox(width: 12),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    // Return different colors based on category type
    switch (title.toLowerCase()) {
      case 'harassment':
      case 'bullying':
        return AppColors.feedbackError;
      case 'inappropriate content':
      case 'spam':
        return Colors.orange;
      case 'fake profile':
        return Colors.purple;
      case 'safety concern':
        return Colors.red;
      default:
        return AppColors.primaryLight;
    }
  }
}

/// Report categories data
class ReportCategories {
  static const List<Map<String, dynamic>> categories = [
    {
      'title': 'Harassment',
      'description': 'Threatening, abusive, or harassing behavior',
      'icon': Icons.warning,
    },
    {
      'title': 'Inappropriate Content',
      'description': 'Nudity, sexual content, or offensive material',
      'icon': Icons.visibility_off,
    },
    {
      'title': 'Spam',
      'description': 'Unsolicited messages or promotional content',
      'icon': Icons.report,
    },
    {
      'title': 'Fake Profile',
      'description': 'Suspicious account or impersonation',
      'icon': Icons.person_off,
    },
    {
      'title': 'Underage',
      'description': 'Profile appears to be underage',
      'icon': Icons.child_care,
    },
    {
      'title': 'Scam or Fraud',
      'description': 'Attempting to scam or fraudulent behavior',
      'icon': Icons.security,
    },
    {
      'title': 'Other',
      'description': 'Something else not listed above',
      'icon': Icons.more_horiz,
    },
  ];

  static List<ReportCategoryTile> buildCategoryTiles({
    String? selectedCategory,
    Function(String)? onCategorySelected,
  }) {
    return categories.map((category) {
      return ReportCategoryTile(
        title: category['title'] as String,
        description: category['description'] as String,
        icon: category['icon'] as IconData,
        isSelected: selectedCategory == category['title'],
        onTap: () => onCategorySelected?.call(category['title'] as String),
      );
    }).toList();
  }
}
