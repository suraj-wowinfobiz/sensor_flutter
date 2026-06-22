import 'package:flutter/material.dart';

import '../../../shared/widgets/universal_table.dart';
import '../core/responsive/adaptive_text.dart';
import '../core/responsive/responsive_extensions.dart';
import '../core/responsive/responsive_values.dart';

class CrudTable extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<String> columns;
  final List<List<dynamic>> data;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onEdit;
  final ValueChanged<int>? onDelete;
  final bool showResolve;
  final ValueChanged<int>? onResolve;

  const CrudTable({
    super.key,
    required this.title,
    required this.icon,
    required this.columns,
    required this.data,
    this.onAdd,
    this.onEdit,
    this.onDelete,
    this.showResolve = false,
    this.onResolve,
  });

  @override
  State<CrudTable> createState() => _CrudTableState();
}

class _CrudTableState extends State<CrudTable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final tableColumnWidth = context.responsive(
      compact: 120,
      medium: 136,
      expanded: 150,
      large: 168,
    );
    final actionsWidth = context.responsive(
      compact: 130,
      medium: 140,
      expanded: 150,
      large: 164,
    );
    final outerGap = ResponsiveValues.gap(context);
    final palette = UniversalTablePalette.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: UniversalTableFrame(
        padding: EdgeInsets.all(outerGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon,
                        color: Theme.of(context).colorScheme.primary, size: 22),
                    SizedBox(width: outerGap),
                    AdaptiveText(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                  ],
                ),
                if (widget.onAdd != null)
                  GestureDetector(
                    onTap: widget.onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          AdaptiveText(
                            'Add New',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: outerGap),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minTableWidth = constraints.maxWidth;
                  return Scrollbar(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: minTableWidth),
                          child: UniversalTableFrame(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: palette.headerSurface,
                                    border: Border(
                                      bottom: BorderSide(color: palette.border),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ...widget.columns
                                          .map((column) => Container(
                                                width: tableColumnWidth,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                child: UniversalTableHeaderText(
                                                  column.toUpperCase(),
                                                ),
                                              )),
                                      const SizedBox(
                                        child: SizedBox.shrink(),
                                      ),
                                      SizedBox(
                                        width: actionsWidth,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: UniversalTableHeaderText(
                                            'ACTIONS',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...List.generate(widget.data.length, (index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: palette.border,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ...widget.data[index].map((cell) {
                                          return SizedBox(
                                            width: tableColumnWidth,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: cell is Widget
                                                  ? cell
                                                  : UniversalTableText(
                                                      cell.toString(),
                                                    ),
                                            ),
                                          );
                                        }),
                                        SizedBox(
                                          width: actionsWidth,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                if (widget.onEdit != null)
                                                  GestureDetector(
                                                    onTap: () =>
                                                        widget.onEdit!(index),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                        border: Border.all(
                                                          color: palette.border,
                                                        ),
                                                      ),
                                                      child: Icon(
                                                        Icons.edit,
                                                        size: 16,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                if (widget.onDelete != null)
                                                  GestureDetector(
                                                    onTap: () =>
                                                        widget.onDelete!(index),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withValues(
                                                                alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                        border: Border.all(
                                                          color: Colors.red
                                                              .withValues(
                                                                  alpha: 0.3),
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                          Icons.delete,
                                                          size: 16,
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                if (widget.showResolve &&
                                                    widget.onResolve != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8),
                                                    child: GestureDetector(
                                                      onTap: () => widget
                                                          .onResolve!(index),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green
                                                              .withValues(
                                                                  alpha: 0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          border: Border.all(
                                                            color: Colors.green
                                                                .withValues(
                                                                    alpha: 0.3),
                                                          ),
                                                        ),
                                                        child:
                                                            const UniversalTableText(
                                                          'Resolve',
                                                          bold: true,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
