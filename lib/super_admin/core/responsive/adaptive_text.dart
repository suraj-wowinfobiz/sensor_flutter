import 'package:flutter/material.dart';

import 'responsive_extensions.dart';

class AdaptiveText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AdaptiveText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final scale = context.responsive(
      compact: 0.95,
      medium: 1.0,
      expanded: 1.02,
      large: 1.04,
    );
    final baseStyle = style;
    final adaptiveStyle = baseStyle == null || baseStyle.fontSize == null
        ? baseStyle
        : baseStyle.copyWith(fontSize: baseStyle.fontSize! * scale);

    return Text(
      data,
      style: adaptiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
