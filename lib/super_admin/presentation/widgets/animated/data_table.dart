import 'package:flutter/material.dart';

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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            columns: [
              ...columns.map((c) => DataColumn(label: Text(c))),
              const DataColumn(label: Text('Actions')),
            ],
            rows: [
              for (int i = 0; i < data.length; i++)
                DataRow(
                  cells: [
                    ...data[i].map(
                        (e) => DataCell(e is Widget ? e : Text(e.toString()))),
                    DataCell(
                      Row(
                        children: [
                          if (onEdit != null)
                            IconButton(
                                onPressed: () => onEdit!(i),
                                icon: const Icon(Icons.edit, size: 18)),
                          if (onDelete != null)
                            IconButton(
                                onPressed: () => onDelete!(i),
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
