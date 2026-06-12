import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OpsColors {
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const background = Color(0xFFF7F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF2F4F6);
  static const surfaceHigh = Color(0xFFE6E8EA);
  static const border = Color(0xFFC3C6D7);
  static const outline = Color(0xFF737686);
  static const text = Color(0xFF191C1E);
  static const muted = Color(0xFF505F76);
  static const danger = Color(0xFFBA1A1A);
  static const warning = Color(0xFFBC4800);
  static const success = Color(0xFF16803A);
  static const amber = Color(0xFFF59E0B);
}

class OpsTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: OpsColors.primary,
        primaryContainer: OpsColors.primaryContainer,
        secondary: OpsColors.muted,
        surface: OpsColors.surface,
        onSurface: OpsColors.text,
        error: OpsColors.danger,
        outline: OpsColors.border,
      ),
      scaffoldBackgroundColor: OpsColors.background,
      dividerColor: OpsColors.border,
      cardColor: OpsColors.surface,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final text = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayMedium: const TextStyle(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w700,
        color: OpsColors.text,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: OpsColors.text,
      ),
      titleMedium: const TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        color: OpsColors.text,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: OpsColors.text,
      ),
      bodySmall: const TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: OpsColors.muted,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        height: 12 / 11,
        fontWeight: FontWeight.w700,
        color: OpsColors.outline,
      ),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: OpsColors.surface,
        foregroundColor: OpsColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: OpsColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: OpsColors.border),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(OpsColors.surfaceLow),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return OpsColors.surfaceLow.withValues(alpha: .65);
          }
          return OpsColors.surface;
        }),
        headingTextStyle: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w800,
          letterSpacing: .45,
          color: OpsColors.outline,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: OpsColors.text,
        ),
        dividerThickness: 1,
        horizontalMargin: 24,
        columnSpacing: 40,
        headingRowHeight: 56,
        dataRowMinHeight: 62,
        dataRowMaxHeight: 74,
        checkboxHorizontalMargin: 12,
        decoration: BoxDecoration(
          color: OpsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OpsColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OpsColors.surfaceLow,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OpsColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OpsColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OpsColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OpsColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OpsColors.text,
          side: const BorderSide(color: OpsColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OpsColors.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class OpsPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;

  const OpsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 34, 36, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: OpsColors.muted),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(spacing: 10, runSpacing: 10, children: actions),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  if (actions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: actions,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class OpsPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  const OpsPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: OpsColors.outline,
                        letterSpacing: .4,
                      ),
                ),
              ),
              if (subtitle != null)
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: OpsColors.muted),
                  ),
                ),
              if (trailing != null) Flexible(child: trailing!),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class OpsFramedPanel extends StatelessWidget {
  final Widget header;
  final Widget child;

  const OpsFramedPanel({
    super.key,
    required this.header,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: OpsColors.border)),
            ),
            child: header,
          ),
          child,
        ],
      ),
    );
  }
}

class OpsKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final String? valueSuffix;

  const OpsKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    this.color = OpsColors.primary,
    this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 140;
          final padding = compact ? 16.0 : 24.0;
          final iconSize = compact ? 34.0 : 40.0;
          final gap = compact ? 10.0 : 16.0;
          final valueSize = compact ? 26.0 : 28.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: compact ? 19 : 22),
                    ),
                    const Spacer(),
                    if (helper.isNotEmpty)
                      Flexible(
                        child: Text(
                          helper,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color == OpsColors.primary
                                        ? OpsColors.muted
                                        : color,
                                    letterSpacing: .2,
                                  ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: gap),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: OpsColors.muted,
                      ),
                ),
                const SizedBox(height: 2),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: valueSize,
                          height: 32 / valueSize,
                          fontWeight: FontWeight.w700,
                          color: OpsColors.text,
                        ),
                      ),
                      if (valueSuffix != null) const TextSpan(text: ' '),
                      if (valueSuffix != null)
                        TextSpan(
                          text: valueSuffix,
                          style: TextStyle(
                            fontSize: compact ? 12 : 13,
                            height: 18 / (compact ? 12 : 13),
                            fontWeight: FontWeight.w400,
                            color: OpsColors.text,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OpsStatusBadge extends StatelessWidget {
  final String label;

  const OpsStatusBadge(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = lower.contains('critical') ||
            lower.contains('offline') ||
            lower.contains('high')
        ? OpsColors.danger
        : lower.contains('warning') ||
                lower.contains('weak') ||
                lower.contains('attention')
            ? OpsColors.warning
            : OpsColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .24)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class OpsEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const OpsEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: OpsColors.outline, size: 32),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: OpsColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
