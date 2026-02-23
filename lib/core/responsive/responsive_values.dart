import 'package:flutter/widgets.dart';

import 'responsive_extensions.dart';

class ResponsiveValues {
  static EdgeInsets pagePadding(BuildContext context) {
    final horizontal = context.responsive(
      compact: 12,
      medium: 16,
      expanded: 20,
      large: 24,
    );
    final vertical = context.responsive(
      compact: 10,
      medium: 12,
      expanded: 14,
      large: 16,
    );
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static double cardRadius(BuildContext context) {
    return context.responsive(compact: 12, medium: 14, expanded: 16, large: 18);
  }

  static double gap(BuildContext context) {
    return context.responsive(compact: 8, medium: 10, expanded: 12, large: 14);
  }
}
