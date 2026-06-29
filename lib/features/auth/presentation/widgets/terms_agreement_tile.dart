import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';

/// Styled terms & privacy consent row for registration.
class TermsAgreementTile extends StatelessWidget {
  const TermsAgreementTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final shellColor = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.55)
        : AppColors.cardBackgroundLight;
    final borderColor = isDark
        ? AppColors.borderMediumDark.withValues(alpha: 0.7)
        : AppColors.borderMediumLight;

    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: mutedColor,
      height: 1.45,
      fontSize: 13.5,
    );
    final linkColor = isDark ? AppColors.accentPink : AppColors.primaryLight;
    final linkStyle = theme.textTheme.bodyMedium?.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w700,
      height: 1.45,
      fontSize: 13.5,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationThickness: 1.25,
      decorationColor: linkColor,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingMD,
        vertical: AppSpacing.spacingMD,
      ),
      decoration: BoxDecoration(
        color: shellColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: value
              ? AppColors.accentPurple.withValues(alpha: 0.45)
              : borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppSvgIcon(
            assetPath: AppIcons.shieldTick,
            size: 20,
            color: value
                ? AppColors.accentPurple
                : mutedColor.withValues(alpha: 0.85),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onChanged(!value),
              child: Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: [
                    TextSpan(
                      text: 'I agree to the ',
                      style: bodyStyle?.copyWith(color: textColor),
                    ),
                    TextSpan(
                      text: 'Terms of Service',
                      style: linkStyle,
                      recognizer: termsRecognizer,
                    ),
                    TextSpan(
                      text: ' and ',
                      style: bodyStyle?.copyWith(color: textColor),
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: linkStyle,
                      recognizer: privacyRecognizer,
                    ),
                    TextSpan(
                      text: '.',
                      style: bodyStyle?.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingSM),
          _TermsCheckbox(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleBorder = isDark
        ? AppColors.borderMediumDark
        : AppColors.borderMediumLight;

    return Semantics(
      checked: value,
      label: 'Agree to terms and privacy policy',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: value ? AppColors.brandGradient : null,
            color: value ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: value ? Colors.transparent : idleBorder,
              width: 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: value ? const Center(child: _CheckboxCheckMark()) : null,
        ),
      ),
    );
  }
}

/// Compact check mark drawn for the consent checkbox (no outer square).
class _CheckboxCheckMark extends StatelessWidget {
  const _CheckboxCheckMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 10),
      painter: _CheckboxCheckMarkPainter(),
    );
  }
}

class _CheckboxCheckMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.9, size.height * 0.18);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
