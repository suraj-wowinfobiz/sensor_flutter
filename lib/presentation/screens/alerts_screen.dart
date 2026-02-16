import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/alert_model.dart';
import '../providers/database_provider.dart';
import '../widgets/animated/data_table.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        return AnimatedDataTable(
          title: 'Alerts',
          icon: Icons.notifications,
          columns: const ['Message', 'Sensor', 'Level', 'Status'],
          data: db.alerts
              .map((a) => [
                    a.message,
                    a.sensorId,
                    a.alertLevel,
                    a.isResolved ? 'resolved' : 'active'
                  ])
              .toList(),
          onAdd: () => _showAlertDialog(context, db),
          onEdit: (index) =>
              _showAlertDialog(context, db, alert: db.alerts[index]),
          onDelete: (index) => db.deleteAlert(db.alerts[index].id),
        );
      },
    );
  }

  Future<void> _showAlertDialog(BuildContext context, DatabaseProvider db,
      {AlertModel? alert}) async {
    final messageCtrl = TextEditingController(
        text: alert?.message ?? 'Tilt threshold exceeded');
    final sensorCtrl =
        TextEditingController(text: alert?.sensorId ?? 'sensor-1');
    String level = alert?.alertLevel ?? 'warning';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alert == null ? 'Add Alert' : 'Edit Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: messageCtrl,
                decoration: const InputDecoration(labelText: 'Message')),
            TextField(
                controller: sensorCtrl,
                decoration: const InputDecoration(labelText: 'Sensor ID')),
            DropdownButtonFormField<String>(
              initialValue: level,
              items: const [
                DropdownMenuItem(value: 'warning', child: Text('warning')),
                DropdownMenuItem(value: 'critical', child: Text('critical')),
                DropdownMenuItem(value: 'info', child: Text('info')),
              ],
              onChanged: (v) => level = v ?? level,
              decoration: const InputDecoration(labelText: 'Level'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (alert == null) {
                await db.addAlert(
                  AlertModel(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    sensorId: sensorCtrl.text.trim(),
                    sensorParameterId: 'tilt',
                    alertLevel: level,
                    message: messageCtrl.text.trim(),
                    triggeredAt: DateTime.now(),
                  ),
                );
              } else {
                await db.updateAlert(alert.copyWith(
                    message: messageCtrl.text.trim(),
                    alertLevel: level,
                    resolvedAt: alert.resolvedAt));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
