import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/ops_theme.dart';
import '../models/alert.dart';
import '../providers/user_database_provider.dart';
import '../widgets/ops_data_table.dart';

class UserAlertsScreen extends StatelessWidget {
  const UserAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final openAlerts = db.alerts.where((a) => !a.isResolved).toList();
        final critical = openAlerts
            .where((a) => a.alertLevel.toLowerCase().contains('critical'))
            .length;
        final warnings = openAlerts.length - critical;

        return OpsPage(
          title: 'Alert Management',
          subtitle:
              'Monitor active warnings, critical incidents, response ownership, and alert timelines',
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              label: const Text('Filter Alerts'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Resolve Selected'),
            ),
          ],
          child: Column(
            children: [
              OpsKpiGrid(
                maxColumns: 4,
                minCardWidth: 180,
                cardHeight: 132,
                cards: [
                  OpsKpiCard(
                    label: 'Open Alerts',
                    value: '${openAlerts.isEmpty ? 12 : openAlerts.length}',
                    helper: 'Unresolved',
                    icon: Icons.notifications_active_rounded,
                    color: OpsColors.danger,
                  ),
                  OpsKpiCard(
                    label: 'Critical',
                    value: '${critical == 0 ? 3 : critical}',
                    helper: 'Immediate response',
                    icon: Icons.priority_high_rounded,
                    color: OpsColors.danger,
                  ),
                  OpsKpiCard(
                    label: 'Warning',
                    value: '${warnings == 0 ? 9 : warnings}',
                    helper: 'Monitoring required',
                    icon: Icons.warning_amber_rounded,
                    color: OpsColors.warning,
                  ),
                  const OpsKpiCard(
                    label: 'Resolved Today',
                    value: '18',
                    helper: 'Closed today',
                    icon: Icons.task_alt_rounded,
                    color: OpsColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OpsFramedPanel(
                header: const _AlertsTableHeader(),
                child: _AlertsTable(alerts: openAlerts),
              ),
              const SizedBox(height: 16),
              const OpsPanel(
                title: 'Alert Timeline',
                subtitle: 'Recent escalation and investigation activity',
                child: _Timeline(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertsTable extends StatelessWidget {
  final List<Alert> alerts;

  const _AlertsTable({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final rows = alerts.isEmpty ? _sampleAlerts : alerts;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: OpsDataTable(
        minWidth: 1040,
        columns: const [
          OpsTableColumnSpec('ALERT ID'),
          OpsTableColumnSpec('SEVERITY'),
          OpsTableColumnSpec('SITE', flex: 2),
          OpsTableColumnSpec('SOURCE'),
          OpsTableColumnSpec('TRIGGERED'),
          OpsTableColumnSpec('MESSAGE', flex: 3),
          OpsTableColumnSpec('STATUS'),
        ],
        rows: rows.map((alert) {
          final sample = alert.id.startsWith('sample-');
          return OpsTableRowSpec([
            OpsTableCellSpec.text(alert.id),
            OpsTableCellSpec(child: OpsStatusBadge(alert.alertLevel)),
            OpsTableCellSpec.text(
              sample ? _sampleSite(alert.id) : 'Project Alpha',
            ),
            OpsTableCellSpec.text(alert.sensorId),
            OpsTableCellSpec.text(
              sample ? _sampleTime(alert.id) : _ago(alert.triggeredAt),
            ),
            OpsTableCellSpec.text(alert.message, maxLines: 1),
            OpsTableCellSpec(
              child: OpsStatusBadge(alert.isResolved ? 'Resolved' : 'Open'),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class _AlertsTableHeader extends StatelessWidget {
  const _AlertsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'ACTIVE ALERTS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: OpsColors.outline,
                letterSpacing: .4,
              ),
        ),
        const Spacer(),
        Text(
          'Severity, source, trigger time, and current response state',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: OpsColors.muted),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('10:42 AM', 'Critical vibration alert assigned to field response'),
      ('10:31 AM', 'Gateway D-14 reported degraded connectivity'),
      ('09:58 AM', 'Temperature threshold warning moved to monitoring state'),
      ('Yesterday', 'East Metro Segment breach cluster reviewed by operations'),
    ];

    return Column(
      children: items.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_rounded, color: OpsColors.primary),
          title: Text(item.$2),
          subtitle: Text(item.$1),
        );
      }).toList(),
    );
  }
}

final _sampleAlerts = [
  Alert(
    id: 'sample-1',
    sensorId: 'V-118',
    sensorParameterId: 'vibration',
    alertLevel: 'Critical',
    message: 'High vibration detected near foundation sensor cluster',
    triggeredAt: DateTime.now(),
  ),
  Alert(
    id: 'sample-2',
    sensorId: 'Gateway D-14',
    sensorParameterId: 'heartbeat',
    alertLevel: 'Warning',
    message: 'Device heartbeat missing from East Metro Segment',
    triggeredAt: DateTime.now(),
  ),
  Alert(
    id: 'sample-3',
    sensorId: 'TMP-77',
    sensorParameterId: 'temperature',
    alertLevel: 'Warning',
    message: 'Temperature threshold exceeded at Crane Pad South',
    triggeredAt: DateTime.now(),
  ),
];

String _sampleSite(String id) => switch (id) {
      'sample-1' => 'Tower A',
      'sample-2' => 'East Metro Segment',
      _ => 'Industrial Block C',
    };

String _sampleTime(String id) => switch (id) {
      'sample-1' => '18 min ago',
      'sample-2' => '42 min ago',
      _ => '1 hr ago',
    };

String _ago(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} d ago';
}
