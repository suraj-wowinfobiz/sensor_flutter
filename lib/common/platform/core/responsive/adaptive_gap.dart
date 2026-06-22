import 'package:flutter/widgets.dart';

import 'responsive_extensions.dart';

class AdaptiveGap extends StatelessWidget {
  final Axis axis;
  final double compact;
  final double? medium;
  final double? expanded;
  final double? large;

  const AdaptiveGap({
    super.key,
    this.axis = Axis.vertical,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    final value = context.responsive(
      compact: compact,
      medium: medium,
      expanded: expanded,
      large: large,
    );
    return SizedBox(
      width: axis == Axis.horizontal ? value : 0,
      height: axis == Axis.vertical ? value : 0,
    );
  }
}
