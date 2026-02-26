import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        final config = db.config;
        if (config.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('System Configuration',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      FilledButton.icon(
                        onPressed: () => _showConfigDialog(context, db, config),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _configTile('Thresholds', [
                    'Global: ${config['global_threshold']}°',
                    'Warning: ${config['warning_threshold']}°',
                    'Critical: ${config['critical_threshold']}°',
                  ]),
                  _configTile('Data Retention', [
                    'Retention Days: ${config['retention_days']}',
                    'Backup: ${config['backup_enabled'] ? 'Enabled' : 'Disabled'}',
                    'Frequency: ${config['backup_frequency']}',
                  ]),
                  _configTile('Notifications', [
                    'Alert Notifications: ${config['alert_notification'] ? 'On' : 'Off'}',
                  ]),
                  _configTile('API', [
                    'Rate Limit: ${config['api_rate_limit']} req/min',
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _configTile(String title, List<String> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFd0dce9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...rows.map((r) => Text(r)),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfigDialog(BuildContext context, DatabaseProvider db,
      Map<String, dynamic> config) async {
    final globalCtrl =
        TextEditingController(text: config['global_threshold'].toString());
    final warningCtrl =
        TextEditingController(text: config['warning_threshold'].toString());
    final criticalCtrl =
        TextEditingController(text: config['critical_threshold'].toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: globalCtrl,
                decoration:
                    const InputDecoration(labelText: 'Global Threshold'),
                keyboardType: TextInputType.number),
            TextField(
                controller: warningCtrl,
                decoration:
                    const InputDecoration(labelText: 'Warning Threshold'),
                keyboardType: TextInputType.number),
            TextField(
                controller: criticalCtrl,
                decoration:
                    const InputDecoration(labelText: 'Critical Threshold'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final updated = Map<String, dynamic>.from(config)
                ..['global_threshold'] =
                    double.tryParse(globalCtrl.text.trim()) ??
                        config['global_threshold']
                ..['warning_threshold'] =
                    double.tryParse(warningCtrl.text.trim()) ??
                        config['warning_threshold']
                ..['critical_threshold'] =
                    double.tryParse(criticalCtrl.text.trim()) ??
                        config['critical_threshold'];
              await db.updateConfig(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
