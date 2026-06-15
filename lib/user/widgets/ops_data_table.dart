import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/ops_theme.dart';

class OpsTableColumnSpec {
  final String title;
  final int flex;
  final bool center;
  final int maxLines;

  const OpsTableColumnSpec(
    this.title, {
    this.flex = 1,
    this.center = false,
    this.maxLines = 2,
  });
}

class OpsTableCellSpec {
  final Widget child;
  final bool? center;

  const OpsTableCellSpec({
    required this.child,
    this.center,
  });

  factory OpsTableCellSpec.text(
    String text, {
    bool center = false,
    bool bold = false,
    Color? color,
    int maxLines = 1,
  }) {
    return OpsTableCellSpec(
      center: center,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: color ?? OpsColors.text,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class OpsTableRowSpec {
  final List<OpsTableCellSpec> cells;

  const OpsTableRowSpec(this.cells);
}

class OpsDataTable extends StatelessWidget {
  final List<OpsTableColumnSpec> columns;
  final List<OpsTableRowSpec> rows;
  final double minWidth;
  final double headerHeight;
  final double rowHeight;
  final EdgeInsetsGeometry horizontalPadding;

  const OpsDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 760,
    this.headerHeight = 48,
    this.rowHeight = 58,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(minWidth, constraints.maxWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: OpsColors.surface,
                border: Border.all(color: OpsColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    Container(
                      height: headerHeight,
                      color: OpsColors.surfaceLow,
                      padding: horizontalPadding,
                      child: Row(
                        children: List.generate(
                          columns.length,
                          (index) => _HeaderCell(
                            column: columns[index],
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(rows.length, (index) {
                      final row = rows[index];
                      return Container(
                        height: rowHeight,
                        padding: horizontalPadding,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: index == rows.length - 1
                                  ? Colors.transparent
                                  : OpsColors.border,
                            ),
                          ),
                        ),
                        child: Row(
                          children: List.generate(columns.length, (cellIndex) {
                            final column = columns[cellIndex];
                            final cell = row.cells[cellIndex];
                            final center = cell.center ?? column.center;
                            return Expanded(
                              flex: column.flex,
                              child: Align(
                                alignment: center
                                    ? Alignment.center
                                    : Alignment.centerLeft,
                                child: cell.child,
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final OpsTableColumnSpec column;

  const _HeaderCell({required this.column});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: column.flex,
      child: Text(
        column.title,
        maxLines: column.maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: column.center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          color: OpsColors.outline,
          fontSize: 11,
          height: 14 / 11,
          letterSpacing: .45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
