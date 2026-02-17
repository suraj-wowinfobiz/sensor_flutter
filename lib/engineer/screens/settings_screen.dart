import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/config.dart';
import '../providers/engineer_database_provider.dart';
import '../widgets/crud_modal.dart';

class EngineerSettingsScreen extends StatefulWidget {
  const EngineerSettingsScreen({super.key});

  @override
  State<EngineerSettingsScreen> createState() => _EngineerSettingsScreenState();
}

class _EngineerSettingsScreenState extends State<EngineerSettingsScreen> {
  late double _globalThreshold;
  late double _warningThreshold;
  late double _criticalThreshold;
  late int _retentionDays;
  late bool _alertNotification;
  late bool _backupEnabled;
  late String _backupFrequency;
  late int _apiRateLimit;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<EngineerDatabaseProvider>(context, listen: false);
    _loadConfig(db.config);
  }

  void _loadConfig(Config config) {
    _globalThreshold = config.globalThreshold;
    _warningThreshold = config.warningThreshold;
    _criticalThreshold = config.criticalThreshold;
    _retentionDays = config.retentionDays;
    _alertNotification = config.alertNotification;
    _backupEnabled = config.backupEnabled;
    _backupFrequency = config.backupFrequency;
    _apiRateLimit = config.apiRateLimit;
  }

  void _showConfigModal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return EngineerCrudModal(
            title: 'Edit Configuration',
            fields: [
              {
                'label': 'Global Threshold',
                'value': _globalThreshold.toString(),
                'onChanged': (String value) => setState(
                    () => _globalThreshold = double.tryParse(value) ?? 3.0),
                'keyboardType':
                    const TextInputType.numberWithOptions(decimal: true),
              },
              {
                'label': 'Warning Threshold',
                'value': _warningThreshold.toString(),
                'onChanged': (String value) => setState(
                    () => _warningThreshold = double.tryParse(value) ?? 2.6),
                'keyboardType':
                    const TextInputType.numberWithOptions(decimal: true),
              },
              {
                'label': 'Critical Threshold',
                'value': _criticalThreshold.toString(),
                'onChanged': (String value) => setState(
                    () => _criticalThreshold = double.tryParse(value) ?? 4.2),
                'keyboardType':
                    const TextInputType.numberWithOptions(decimal: true),
              },
              {
                'label': 'Retention Days',
                'value': _retentionDays.toString(),
                'onChanged': (String value) =>
                    setState(() => _retentionDays = int.tryParse(value) ?? 90),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'Alert Notifications',
                'type': 'select',
                'value': _alertNotification ? 'true' : 'false',
                'onChanged': (String? value) =>
                    setState(() => _alertNotification = value == 'true'),
                'options': const [
                  {'label': 'Enabled', 'value': 'true'},
                  {'label': 'Disabled', 'value': 'false'},
                ],
              },
              {
                'label': 'Backup Frequency',
                'type': 'select',
                'value': _backupFrequency,
                'onChanged': (String? value) => setState(
                    () => _backupFrequency = value ?? _backupFrequency),
                'options': const [
                  {'label': 'Daily', 'value': 'daily'},
                  {'label': 'Weekly', 'value': 'weekly'},
                  {'label': 'Monthly', 'value': 'monthly'},
                ],
              },
            ],
            onSave: () {
              final db =
                  Provider.of<EngineerDatabaseProvider>(context, listen: false);
              db.update('config', '', {
                'global_threshold': _globalThreshold,
                'warning_threshold': _warningThreshold,
                'critical_threshold': _criticalThreshold,
                'retention_days': _retentionDays,
                'alert_notification': _alertNotification,
                'backup_enabled': _backupEnabled,
                'backup_frequency': _backupFrequency,
                'api_rate_limit': _apiRateLimit,
              });
              Navigator.pop(context);
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFf0f5fd)
            : const Color(0xFF203a54),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF1e3a5a)
                        : const Color(0xFFc0d6f0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF4a6b8a)
                        : const Color(0xFF8aaac9),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EngineerDatabaseProvider>(
      builder: (context, db, child) {
        _loadConfig(db.config);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isSmall = width < 640;
              final crossAxisCount = width >= 1100
                  ? 2
                  : width >= 700
                      ? 2
                      : 1;

              return Container(
                padding: EdgeInsets.all(isSmall ? 18 : 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'System Configuration',
                              style: TextStyle(
                                fontSize: isSmall ? 17 : 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? const Color(0xFF1e3a5a)
                                    : const Color(0xFFc0d6f0),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showConfigModal,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 14 : 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                                if (!isSmall) const SizedBox(width: 8),
                                Text(
                                  isSmall ? 'Edit' : 'Edit Configuration',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: crossAxisCount == 1 ? 2.6 : 2,
                      children: [
                        _buildConfigCard('Thresholds', Icons.trending_up, [
                          'Global: ${db.config.globalThreshold}°',
                          'Warning: ${db.config.warningThreshold}°',
                          'Critical: ${db.config.criticalThreshold}°',
                        ]),
                        _buildConfigCard('Data Retention', Icons.storage, [
                          'Retention Days: ${db.config.retentionDays}',
                          'Backup: ${db.config.backupEnabled ? 'Enabled' : 'Disabled'}',
                          'Frequency: ${db.config.backupFrequency}',
                        ]),
                        _buildConfigCard('Notifications', Icons.notifications, [
                          'Alert Notifications: ${db.config.alertNotification ? 'On' : 'Off'}',
                        ]),
                        _buildConfigCard('API', Icons.api, [
                          'Rate Limit: ${db.config.apiRateLimit} req/min',
                        ]),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
