import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/widgets/universal_table.dart';

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
      child: UniversalTableText(
        text,
        color: color,
        bold: bold,
        maxLines: maxLines,
        textAlign: center ? TextAlign.center : TextAlign.start,
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
          child: UniversalTableFrame(
            width: tableWidth,
            child: Column(
              children: [
                Container(
                  height: headerHeight,
                  color: UniversalTablePalette.of(context).headerSurface,
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
                  final palette = UniversalTablePalette.of(context);
                  return Container(
                    height: rowHeight,
                    padding: horizontalPadding,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: index == rows.length - 1
                              ? Colors.transparent
                              : palette.border,
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
      child: UniversalTableHeaderText(
        column.title,
        maxLines: column.maxLines,
        textAlign: column.center ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}
