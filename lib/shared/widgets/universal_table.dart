import 'dart:math' as math;

import 'package:flutter/material.dart';

@immutable
class UniversalTablePalette {
  final Color surface;
  final Color headerSurface;
  final Color headerAccent;
  final Color border;
  final Color text;
  final Color muted;
  final Color actionTint;
  final Color shadow;
  final Gradient frameGlow;
  final double radius;

  const UniversalTablePalette({
    required this.surface,
    required this.headerSurface,
    required this.headerAccent,
    required this.border,
    required this.text,
    required this.muted,
    required this.actionTint,
    required this.shadow,
    required this.frameGlow,
    this.radius = 24,
  });

  factory UniversalTablePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final baseSurface = Color.alphaBlend(
      scheme.surface.withValues(alpha: isLight ? 0.92 : 0.98),
      theme.scaffoldBackgroundColor,
    );
    return UniversalTablePalette(
      surface: baseSurface,
      headerSurface: Color.alphaBlend(
        scheme.primary.withValues(alpha: isLight ? 0.06 : 0.16),
        baseSurface,
      ),
      headerAccent: isLight
          ? const Color(0xFFE9F0FF)
          : scheme.primary.withValues(alpha: 0.24),
      border: theme.dividerColor.withValues(alpha: isLight ? 0.92 : 0.72),
      text: theme.textTheme.bodyMedium?.color ?? scheme.onSurface,
      muted: theme.textTheme.bodySmall?.color ??
          scheme.onSurface.withValues(alpha: 0.68),
      actionTint: scheme.primary,
      shadow: Colors.black.withValues(alpha: isLight ? 0.05 : 0.18),
      frameGlow: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withValues(alpha: isLight ? 0.05 : 0.14),
          Colors.transparent,
          scheme.primary.withValues(alpha: isLight ? 0.015 : 0.06),
        ],
      ),
    );
  }
}

class UniversalTableFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const UniversalTableFrame({
    super.key,
    required this.child,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final palette = UniversalTablePalette.of(context);
    final body = Container(
      width: width,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(palette.radius),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: palette.frameGlow,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    if (padding == null) return body;
    return Padding(padding: padding!, child: body);
  }
}

class UniversalTableHeaderText extends StatelessWidget {
  final String label;
  final TextAlign textAlign;
  final int maxLines;

  const UniversalTableHeaderText(
    this.label, {
    super.key,
    this.textAlign = TextAlign.start,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final palette = UniversalTablePalette.of(context);
    return Text(
      label,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        color: palette.muted,
        fontSize: 11,
        height: 14 / 11,
        letterSpacing: .45,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class UniversalTableText extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final TextAlign textAlign;
  final int maxLines;

  const UniversalTableText(
    this.text, {
    super.key,
    this.bold = false,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final palette = UniversalTablePalette.of(context);
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        color: color ?? palette.text,
        fontSize: 12.5,
        height: 18 / 12.5,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class UniversalDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;
  final EdgeInsetsGeometry? padding;

  const UniversalDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 760,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final palette = UniversalTablePalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(minWidth, constraints.maxWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: UniversalTableFrame(
            width: tableWidth,
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingRowColor: WidgetStatePropertyAll<Color>(
                      Color.alphaBlend(
                        palette.headerAccent.withValues(alpha: 0.55),
                        palette.headerSurface,
                      ),
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return palette.headerSurface.withValues(alpha: 0.75);
                      }
                      return palette.surface;
                    }),
                    headingTextStyle: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .45,
                    ),
                    dataTextStyle: TextStyle(
                      color: palette.text,
                      fontSize: 12.5,
                      height: 18 / 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerThickness: 1,
                    horizontalMargin: 20,
                    columnSpacing: 28,
                    headingRowHeight: 50,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 64,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(palette.radius),
                      border: Border.all(color: palette.border),
                    ),
                  ),
                ),
                child: DataTable(columns: columns, rows: rows),
              ),
            ),
          ),
        );
      },
    );
  }
}
