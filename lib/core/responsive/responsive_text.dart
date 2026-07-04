import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// Text wrapper with optional auto-sizing for tight layouts.
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final double? minFontSize;

  const AppText(
    this.text, {
    this.style,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.minFontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (minFontSize != null) {
      return AutoSizeText(
        text,
        style: style,
        maxLines: maxLines,
        minFontSize: minFontSize!,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.ellipsis,
      );
    }

    return Text(
      text,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}
