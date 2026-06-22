import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/super_admin_api_riverpod_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../widgets/crud_table.dart';

class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final apiLogs = ref.watch(superAdminAuditLogsApiProvider).valueOrNull;
    final data = apiLogs != null
        ? apiLogs
            .map(
              (log) => [
                _formatDate(
                  DateTime.tryParse((log['timestamp'] ?? '').toString()) ??
                      DateTime.now(),
                ),
                (log['userName'] ?? log['userId'] ?? '-').toString(),
                (log['action'] ?? '-').toString(),
                (log['resource'] ?? '-').toString(),
                (log['ip'] ?? '-').toString(),
              ],
            )
            .toList()
        : db.auditLogs
            .map((log) => [
                  _formatDate(log.timestamp),
                  db.users.firstWhere((u) => u.id == log.userId).name,
                  log.action,
                  log.resource,
                  log.ip,
                ])
            .toList();

    return CrudTable(
      title: 'Audit Logs',
      icon: Icons.history,
      columns: const ['Timestamp', 'User', 'Action', 'Resource', 'IP'],
      data: data,
    );
  }
}
