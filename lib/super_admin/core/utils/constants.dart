import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Industrial Tilt Admin';

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const List<Color> chartColors = [
    Color(0xFF1f7bcf),
    Color(0xFFe68a2e),
    Color(0xFF27a36a),
    Color(0xFFd64545),
    Color(0xFF9b59b6),
  ];

  static const double defaultGlobalThreshold = 3.0;
  static const double defaultWarningThreshold = 2.6;
  static const double defaultCriticalThreshold = 4.2;
}
