enum AppBreakpoint { compact, medium, expanded, large }

class AppBreakpoints {
  static const double compactMax = 599;
  static const double mediumMin = 600;
  static const double mediumMax = 1023;
  static const double expandedMin = 1024;
  static const double expandedMax = 1439;
  static const double largeMin = 1440;

  // Kept for compatibility with existing shell layouts.
  static const double desktopLayoutMin = 1100;

  static AppBreakpoint fromWidth(double width) {
    if (width <= compactMax) return AppBreakpoint.compact;
    if (width <= mediumMax) return AppBreakpoint.medium;
    if (width <= expandedMax) return AppBreakpoint.expanded;
    return AppBreakpoint.large;
  }
}
