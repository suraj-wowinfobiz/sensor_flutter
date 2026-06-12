import 'package:flutter/material.dart';

import '../../core/theme/ops_theme.dart';
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
    const cardRadius = 8.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(outerGap),
        padding: EdgeInsets.all(outerGap * 1.4),
        decoration: BoxDecoration(
          color: OpsColors.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: OpsColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: OpsColors.text,
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
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: OpsColors.border),
                              borderRadius: BorderRadius.circular(cardRadius),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                  decoration: const BoxDecoration(
                                    color: OpsColors.surfaceLow,
                                    border: Border(
                                      bottom:
                                          BorderSide(color: OpsColors.border),
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
                                                child: Text(
                                                  column.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    height: 16 / 12,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: .45,
                                                    color: OpsColors.outline,
                                                  ),
                                                ),
                                              )),
                                      const SizedBox(
                                        child: SizedBox.shrink(),
                                      ),
                                      SizedBox(
                                        width: actionsWidth,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(
                                            'ACTIONS',
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: .45,
                                              color: OpsColors.outline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...List.generate(widget.data.length, (index) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: OpsColors.border,
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
                                                  : Text(
                                                      cell.toString(),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        height: 20 / 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: OpsColors.text,
                                                      ),
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
                                                            color: Theme.of(
                                                                    context)
                                                                .dividerColor),
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
                                                        child: const Text(
                                                          'Resolve',
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
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
