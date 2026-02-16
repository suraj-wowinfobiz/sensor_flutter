import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';
import '../widgets/crud_table.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        return CrudTable(
          title: 'Audit Logs',
          icon: Icons.history,
          columns: const ['Timestamp', 'User', 'Action', 'Resource', 'IP'],
          data: db.auditLogs
              .map((log) => [
                    _formatDate(log.timestamp),
                    db.users.firstWhere((u) => u.id == log.userId).name,
                    log.action,
                    log.resource,
                    log.ip,
                  ])
              .toList(),
        );
      },
    );
  }
}
