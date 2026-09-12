import 'package:flutter/material.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_list_view.dart';
import '../../core/widgets/app_settings_detail.dart';
import '../../core/widgets/premium/premium_design_system.dart';

class LegalDocumentSection {
  const LegalDocumentSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// Virtualized legal copy with selectable rich text (PERF-SCR-LEGAL-001/002).
class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    super.key,
    required this.lastUpdated,
    required this.sections,
  });

  final String lastUpdated;
  final List<LegalDocumentSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final titleStyle = AppTypography.h2.copyWith(
      color: textColor,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = AppTypography.body.copyWith(
      color: secondaryTextColor,
      height: 1.6,
    );

    return AppListView.builder(
      physics: AppScroll.bouncing,
      padding: const EdgeInsets.fromLTRB(
        AppSettingsLayout.horizontalPadding,
        0,
        AppSettingsLayout.horizontalPadding,
        AppSpacing.spacingXXL,
      ),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingXL),
            child: SelectableText(
              'Last Updated: $lastUpdated',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
          );
        }

        final section = sections[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spacingXL),
          child: SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(text: section.title, style: titleStyle),
                const TextSpan(text: '\n\n'),
                TextSpan(text: section.body, style: bodyStyle),
              ],
            ),
          ),
        );
      },
    );
  }
}
