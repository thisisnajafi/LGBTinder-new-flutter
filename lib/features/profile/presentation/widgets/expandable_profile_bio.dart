import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';

/// Collapsible bio text. Expand/collapse stays in this [State] so the parent
/// profile page does not rebuild (PERF-COMP-PROF-006).
class ExpandableProfileBio extends StatefulWidget {
  const ExpandableProfileBio({
    super.key,
    required this.text,
    this.style,
    this.quote = false,
    this.collapsedMaxLines = 4,
    this.collapseAfterChars = 140,
  });

  final String text;
  final TextStyle? style;
  final bool quote;
  final int collapsedMaxLines;
  final int collapseAfterChars;

  @override
  State<ExpandableProfileBio> createState() => _ExpandableProfileBioState();
}

class _ExpandableProfileBioState extends State<ExpandableProfileBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trim();
    final display = widget.quote ? '"$trimmed"' : trimmed;
    final needsCollapse = trimmed.length > widget.collapseAfterChars;
    final duration = AppAnimations.pageTransitionDuration(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: duration,
          curve: AppAnimations.curveDefault,
          alignment: Alignment.topCenter,
          child: AppText(
            display,
            style: widget.style,
            maxLines: !needsCollapse || _expanded
                ? null
                : widget.collapsedMaxLines,
            overflow: !needsCollapse || _expanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        ),
        if (needsCollapse)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Read less' : 'Read more',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accentPurple,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
