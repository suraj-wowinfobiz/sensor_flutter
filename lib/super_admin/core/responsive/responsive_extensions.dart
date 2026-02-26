import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

extension ResponsiveContextX on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  AppBreakpoint get breakpoint => AppBreakpoints.fromWidth(screenWidth);

  bool get isCompact => breakpoint == AppBreakpoint.compact;
  bool get isMedium => breakpoint == AppBreakpoint.medium;
  bool get isExpanded => breakpoint == AppBreakpoint.expanded;
  bool get isLarge => breakpoint == AppBreakpoint.large;

  bool get isDesktopLayout => screenWidth >= AppBreakpoints.desktopLayoutMin;
  bool narrowerThan(double width) => screenWidth < width;
  bool widerThanOrEqualTo(double width) => screenWidth >= width;

  double responsive({
    required double compact,
    double? medium,
    double? expanded,
    double? large,
  }) {
    final m = medium ?? compact;
    final e = expanded ?? m;
    final l = large ?? e;
    switch (breakpoint) {
      case AppBreakpoint.compact:
        return compact;
      case AppBreakpoint.medium:
        return m;
      case AppBreakpoint.expanded:
        return e;
      case AppBreakpoint.large:
        return l;
    }
  }
}
