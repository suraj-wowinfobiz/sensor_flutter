import 'package:flutter/material.dart';

@immutable
class CustomThemeTokens extends ThemeExtension<CustomThemeTokens> {
  final Color heading;
  final Color subheading;
  final Color mutedText;
  final Color softPanel;
  final Color softButton;
  final Color chartGrid;
  final Color statusCritical;
  final Color statusWarning;
  final Color statusNormal;

  const CustomThemeTokens({
    required this.heading,
    required this.subheading,
    required this.mutedText,
    required this.softPanel,
    required this.softButton,
    required this.chartGrid,
    required this.statusCritical,
    required this.statusWarning,
    required this.statusNormal,
  });

  static const light = CustomThemeTokens(
    heading: Color(0xFF132733),
    subheading: Color(0xFF4e6473),
    mutedText: Color(0xFF60717c),
    softPanel: Color(0xFFF2F6F8),
    softButton: Color(0xFFE7EFF3),
    chartGrid: Color(0xFFD2DBE0),
    statusCritical: Color(0xFFef2e38),
    statusWarning: Color(0xFFd39a00),
    statusNormal: Color(0xFF0ca15f),
  );

  static const dark = CustomThemeTokens(
    heading: Color(0xFFD8E8F5),
    subheading: Color(0xFF9db7d2),
    mutedText: Color(0xFF9FB4C6),
    softPanel: Color(0xFF223B4E),
    softButton: Color(0xFF243E52),
    chartGrid: Color(0xFF315a7a),
    statusCritical: Color(0xFFef2e38),
    statusWarning: Color(0xFFd39a00),
    statusNormal: Color(0xFF0ca15f),
  );

  @override
  CustomThemeTokens copyWith({
    Color? heading,
    Color? subheading,
    Color? mutedText,
    Color? softPanel,
    Color? softButton,
    Color? chartGrid,
    Color? statusCritical,
    Color? statusWarning,
    Color? statusNormal,
  }) {
    return CustomThemeTokens(
      heading: heading ?? this.heading,
      subheading: subheading ?? this.subheading,
      mutedText: mutedText ?? this.mutedText,
      softPanel: softPanel ?? this.softPanel,
      softButton: softButton ?? this.softButton,
      chartGrid: chartGrid ?? this.chartGrid,
      statusCritical: statusCritical ?? this.statusCritical,
      statusWarning: statusWarning ?? this.statusWarning,
      statusNormal: statusNormal ?? this.statusNormal,
    );
  }

  @override
  CustomThemeTokens lerp(ThemeExtension<CustomThemeTokens>? other, double t) {
    if (other is! CustomThemeTokens) return this;
    return CustomThemeTokens(
      heading: Color.lerp(heading, other.heading, t) ?? heading,
      subheading: Color.lerp(subheading, other.subheading, t) ?? subheading,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      softPanel: Color.lerp(softPanel, other.softPanel, t) ?? softPanel,
      softButton: Color.lerp(softButton, other.softButton, t) ?? softButton,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t) ?? chartGrid,
      statusCritical:
          Color.lerp(statusCritical, other.statusCritical, t) ?? statusCritical,
      statusWarning:
          Color.lerp(statusWarning, other.statusWarning, t) ?? statusWarning,
      statusNormal:
          Color.lerp(statusNormal, other.statusNormal, t) ?? statusNormal,
    );
  }
}
