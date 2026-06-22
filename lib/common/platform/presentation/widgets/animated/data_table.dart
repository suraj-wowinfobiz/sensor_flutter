import 'package:flutter/material.dart';

import '../../../../../shared/widgets/universal_table.dart';

class AnimatedDataTable extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> columns;
  final List<List<dynamic>> data;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onEdit;
  final ValueChanged<int>? onDelete;

  const AnimatedDataTable({
    super.key,
    required this.title,
    required this.icon,
    required this.columns,
    required this.data,
    this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: UniversalDataTable(
        columns: [
          ...columns.map((c) => DataColumn(label: UniversalTableHeaderText(c))),
          const DataColumn(label: UniversalTableHeaderText('Actions')),
        ],
        rows: [
          for (int i = 0; i < data.length; i++)
            DataRow(
              cells: [
                ...data[i].map(
                  (e) => DataCell(
                    e is Widget ? e : UniversalTableText(e.toString()),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          onPressed: () => onEdit!(i),
                          icon: const Icon(Icons.edit, size: 18),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: () => onDelete!(i),
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
