import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../../../shared/widgets/universal_table.dart';
import '../api/alerts_api.dart';
import '../api/sensor_api.dart';
import '../models/alert.dart';
import '../providers/super_admin_api_riverpod_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../widgets/crud_modal.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _isPrimingThresholds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeThresholdData();
    });
  }

  Future<void> _primeThresholdData() async {
    if (_isPrimingThresholds || !mounted) return;
    _isPrimingThresholds = true;
    final db = ref.read(superAdminBackendChangeNotifierProvider);

    Future<void> safe(Future<void> future) async {
      try {
        await future;
      } catch (_) {
        // Keep alerts page resilient if one endpoint fails.
      }
    }

    try {
      await Future.wait([
        safe(db.loadThresholdProfiles()),
        safe(db.loadThresholdValues()),
        safe(db.loadSensors()),
        safe(db.loadSensorTypes()),
        safe(db.loadSensorParameters()),
      ]);
    } finally {
      _isPrimingThresholds = false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:00';
  }

  void _showDetails(BuildContext context, Alert alert) {
    String fmtDate(DateTime? value) => value == null ? '-' : _formatDate(value);
    String fmtText(String value) => value.trim().isEmpty ? '-' : value.trim();
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Alert Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alert ID: ${fmtText(alert.id)}'),
              const SizedBox(height: 8),
              Text('Status: ${fmtText(alert.status)}'),
              const SizedBox(height: 8),
              Text('Level: ${fmtText(alert.alertLevel)}'),
              const SizedBox(height: 8),
              Text('Message: ${fmtText(alert.message)}'),
              const SizedBox(height: 8),
              Text('Sensor ID: ${fmtText(alert.sensorId)}'),
              const SizedBox(height: 8),
              Text('Sensor Parameter ID: ${fmtText(alert.sensorParameterId)}'),
              const SizedBox(height: 8),
              Text('Assigned To: ${fmtText(alert.assignedTo)}'),
              const SizedBox(height: 8),
              Text('Triggered: ${fmtDate(alert.triggeredAt)}'),
              const SizedBox(height: 8),
              Text('Acknowledged: ${fmtDate(alert.acknowledgedAt)}'),
              const SizedBox(height: 8),
              Text('Resolved: ${fmtDate(alert.resolvedAt)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateAlertDialog(BuildContext context) async {
    final sensors = await SensorApi.getAllSensors();
    if (!context.mounted) return;
    final sensorOptions = <Map<String, String>>[];
    final sensorParameterBySensorId = <String, String>{};
    for (final sensor in sensors) {
      final id = (sensor['sensorId'] ?? sensor['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      final label =
          (sensor['name'] ?? sensor['serialNumber'] ?? id).toString().trim();
      sensorOptions.add({'value': id, 'label': label.isEmpty ? id : label});
      sensorParameterBySensorId[id] = (sensor['sensorParameterId'] ??
              sensor['sensor_parameter_id'] ??
              sensor['parameterId'] ??
              id)
          .toString()
          .trim();
    }

    String sensorId = '';
    String alertLevel = '';
    String message = '';
    String assignedTo = '';
    if (sensorOptions.isNotEmpty) {
      sensorId = sensorOptions.first['value']!;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return CrudModal(
            title: 'Add Alert',
            fields: [
              if (sensorOptions.isNotEmpty)
                {
                  'label': 'sensor',
                  'type': 'select',
                  'value': sensorId.isEmpty ? null : sensorId,
                  'options': sensorOptions,
                  'onChanged': (String? value) =>
                      setDialogState(() => sensorId = value ?? ''),
                }
              else
                {
                  'label': 'sensor',
                  'value': sensorId,
                  'onChanged': (String value) =>
                      setDialogState(() => sensorId = value),
                  'keyboardType': TextInputType.text,
                },
              {
                'label': 'alertLevel',
                'value': alertLevel,
                'onChanged': (String value) =>
                    setDialogState(() => alertLevel = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'message',
                'value': message,
                'onChanged': (String value) =>
                    setDialogState(() => message = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'assignedTo',
                'value': assignedTo,
                'onChanged': (String value) =>
                    setDialogState(() => assignedTo = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () async {
              final sensorParameterId =
                  sensorParameterBySensorId[sensorId]?.trim() ?? '';
              if (sensorId.trim().isEmpty ||
                  sensorParameterId.trim().isEmpty ||
                  alertLevel.trim().isEmpty ||
                  message.trim().isEmpty ||
                  assignedTo.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('All alert fields are required'),
                  ),
                );
                return;
              }
              try {
                await AlertsApi.createAlert(
                  sensorId: sensorId,
                  sensorParameterId: sensorParameterId,
                  alertLevel: alertLevel,
                  message: message,
                  assignedTo: assignedTo,
                );
                ref.invalidate(superAdminAlertsApiProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to create alert: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(dialogContext),
          );
        },
      ),
    );
  }

  Future<void> _showEditAlertDialog(
    BuildContext context,
    Alert alert,
  ) async {
    final sensors = await SensorApi.getAllSensors();
    if (!context.mounted) return;
    final sensorOptions = <Map<String, String>>[];
    final sensorParameterBySensorId = <String, String>{};
    for (final sensor in sensors) {
      final id = (sensor['sensorId'] ?? sensor['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      final label =
          (sensor['name'] ?? sensor['serialNumber'] ?? id).toString().trim();
      sensorOptions.add({'value': id, 'label': label.isEmpty ? id : label});
      sensorParameterBySensorId[id] = (sensor['sensorParameterId'] ??
              sensor['sensor_parameter_id'] ??
              sensor['parameterId'] ??
              id)
          .toString()
          .trim();
    }

    String sensorId = alert.sensorId.trim();
    String alertLevel = alert.alertLevel.trim();
    String message = alert.message.trim();
    String assignedTo = alert.assignedTo.trim();
    if (sensorId.isEmpty && sensorOptions.isNotEmpty) {
      sensorId = sensorOptions.first['value']!;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return CrudModal(
            title: 'Edit Alert',
            fields: [
              if (sensorOptions.isNotEmpty)
                {
                  'label': 'sensor',
                  'type': 'select',
                  'value': sensorId.isEmpty ? null : sensorId,
                  'options': sensorOptions,
                  'onChanged': (String? value) =>
                      setDialogState(() => sensorId = value ?? ''),
                }
              else
                {
                  'label': 'sensor',
                  'value': sensorId,
                  'onChanged': (String value) =>
                      setDialogState(() => sensorId = value),
                  'keyboardType': TextInputType.text,
                },
              {
                'label': 'alertLevel',
                'value': alertLevel,
                'onChanged': (String value) =>
                    setDialogState(() => alertLevel = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'message',
                'value': message,
                'onChanged': (String value) =>
                    setDialogState(() => message = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'assignedTo',
                'value': assignedTo,
                'onChanged': (String value) =>
                    setDialogState(() => assignedTo = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () async {
              final sensorParameterId =
                  sensorParameterBySensorId[sensorId]?.trim() ?? '';
              if (alert.id.trim().isEmpty ||
                  sensorId.trim().isEmpty ||
                  sensorParameterId.isEmpty ||
                  alertLevel.trim().isEmpty ||
                  message.trim().isEmpty ||
                  assignedTo.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('All alert fields are required'),
                  ),
                );
                return;
              }
              try {
                await AlertsApi.updateAlert(
                  id: alert.id,
                  sensorId: sensorId,
                  sensorParameterId: sensorParameterId,
                  alertLevel: alertLevel,
                  message: message,
                  assignedTo: assignedTo,
                );
                ref.invalidate(superAdminAlertsApiProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to update alert: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(dialogContext),
          );
        },
      ),
    );
  }

  Future<void> _deleteAlert(
    BuildContext context,
    Alert alert,
  ) async {
    if (alert.id.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlertsApi.deleteAlert(alert.id);
      ref.invalidate(superAdminAlertsApiProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete alert: $e')),
      );
    }
  }

  Future<void> _showCreateThresholdProfileDialog(BuildContext context) async {
    String name = '';
    String description = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return CrudModal(
            title: 'Add Threshold Profile',
            fields: [
              {
                'label': 'name',
                'value': name,
                'onChanged': (String value) =>
                    setDialogState(() => name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'description',
                'value': description,
                'onChanged': (String value) =>
                    setDialogState(() => description = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () async {
              if (name.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Profile name is required')),
                );
                return;
              }
              try {
                final db = ref.read(superAdminBackendChangeNotifierProvider);
                await db.create('thresholds', {
                  'name': name.trim(),
                  'description': description.trim(),
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create threshold profile: $e'),
                    ),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(dialogContext),
          );
        },
      ),
    );
  }

  Future<void> _showCreateThresholdValueDialog(BuildContext context) async {
    final db = ref.read(superAdminBackendChangeNotifierProvider);
    await _primeThresholdData();
    if (!context.mounted) return;

    if (db.thresholdProfiles.isEmpty ||
        db.sensorParameters.isEmpty ||
        db.sensors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one sensor, threshold profile, and sensor parameter first',
          ),
        ),
      );
      return;
    }

    String sensorId = db.sensors.first.id;
    String thresholdProfileId = db.thresholdProfiles.first.id;
    String sensorParameterId = '';
    String minThresholdValue = '0';
    String maxThresholdValue = '0';
    String warningLevel = '0';
    String criticalLevel = '0';

    String sensorLabel(dynamic sensor) {
      final name = sensor.name.trim();
      if (name.isNotEmpty) return name;
      final serial = sensor.serialNumber.trim();
      if (serial.isNotEmpty) return serial;
      return sensor.id;
    }

    String parameterLabel(dynamic parameter) {
      final base =
          parameter.name.trim().isEmpty ? parameter.id : parameter.name;
      final calc = parameter.calculationName.trim();
      final unit = parameter.unit.trim();
      final label = calc.isNotEmpty && calc != base ? '$base ($calc)' : base;
      return unit.isEmpty ? label : '$label [$unit]';
    }

    void applyParameterDefaults(String parameterId) {
      var parameter = db.sensorParameters.first;
      var found = false;
      for (final item in db.sensorParameters) {
        if (item.id == parameterId) {
          parameter = item;
          found = true;
          break;
        }
      }
      if (!found) return;
      final minValue = parameter.minValue;
      final maxValue = parameter.maxValue;
      minThresholdValue = minValue.toStringAsFixed(2);
      maxThresholdValue = maxValue.toStringAsFixed(2);
      warningLevel =
          (minValue + ((maxValue - minValue) * 0.75)).toStringAsFixed(2);
      criticalLevel =
          (minValue + ((maxValue - minValue) * 0.9)).toStringAsFixed(2);
    }

    String sensorTypeForSelection(String selectedSensorId) {
      for (final sensor in db.sensors) {
        if (sensor.id == selectedSensorId) {
          return sensor.sensorTypeId;
        }
      }
      return '';
    }

    List<Map<String, String>> parameterOptionsForSensor(
        String selectedSensorId) {
      final typeId = sensorTypeForSelection(selectedSensorId).trim();
      var filtered = db.sensorParameters
          .where((parameter) => parameter.id.trim().isNotEmpty)
          .toList();
      if (typeId.isNotEmpty) {
        filtered = filtered
            .where((parameter) => parameter.sensorTypeId.trim() == typeId)
            .toList();
      }
      if (filtered.isEmpty) {
        filtered = db.sensorParameters
            .where((parameter) => parameter.id.trim().isNotEmpty)
            .toList();
      }
      return filtered
          .map(
            (parameter) => {
              'value': parameter.id,
              'label': parameterLabel(parameter),
            },
          )
          .toList();
    }

    var sensorParameterOptions = parameterOptionsForSensor(sensorId);
    if (sensorParameterOptions.isNotEmpty) {
      sensorParameterId = sensorParameterOptions.first['value']!;
      applyParameterDefaults(sensorParameterId);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return CrudModal(
            title: 'Add Threshold Value',
            fields: [
              {
                'label': 'sensorId',
                'type': 'select',
                'value': sensorId.isEmpty ? null : sensorId,
                'options': db.sensors
                    .where((sensor) => sensor.id.trim().isNotEmpty)
                    .map(
                      (sensor) => {
                        'value': sensor.id,
                        'label': sensorLabel(sensor),
                      },
                    )
                    .toList(),
                'onChanged': (String? value) => setDialogState(() {
                      sensorId = value ?? '';
                      sensorParameterOptions =
                          parameterOptionsForSensor(sensorId);
                      if (sensorParameterOptions.isEmpty) {
                        sensorParameterId = '';
                      } else {
                        sensorParameterId =
                            sensorParameterOptions.first['value']!;
                        applyParameterDefaults(sensorParameterId);
                      }
                    }),
              },
              {
                'label': 'sensorParameterId',
                'type': 'select',
                'value': sensorParameterId.isEmpty ? null : sensorParameterId,
                'options': sensorParameterOptions,
                'onChanged': (String? value) => setDialogState(() {
                      sensorParameterId = value ?? '';
                      applyParameterDefaults(sensorParameterId);
                    }),
              },
              {
                'label': 'thresholdProfileId',
                'type': 'select',
                'value': thresholdProfileId.isEmpty ? null : thresholdProfileId,
                'options': db.thresholdProfiles
                    .map(
                      (profile) => {
                        'value': profile.id,
                        'label': profile.description.trim().isEmpty
                            ? profile.name
                            : '${profile.name} - ${profile.description}',
                      },
                    )
                    .toList(),
                'onChanged': (String? value) => setDialogState(() {
                      thresholdProfileId = value ?? '';
                    }),
              },
              {
                'label': 'minThresholdValue',
                'value': minThresholdValue,
                'onChanged': (String value) =>
                    setDialogState(() => minThresholdValue = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'maxThresholdValue',
                'value': maxThresholdValue,
                'onChanged': (String value) =>
                    setDialogState(() => maxThresholdValue = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'warningLevel',
                'value': warningLevel,
                'onChanged': (String value) =>
                    setDialogState(() => warningLevel = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'criticalLevel',
                'value': criticalLevel,
                'onChanged': (String value) =>
                    setDialogState(() => criticalLevel = value),
                'keyboardType': TextInputType.number,
              },
            ],
            onSave: () async {
              if (thresholdProfileId.trim().isEmpty ||
                  sensorParameterId.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Threshold profile and sensor parameter are required',
                    ),
                  ),
                );
                return;
              }

              final minValue = double.tryParse(minThresholdValue.trim());
              final maxValue = double.tryParse(maxThresholdValue.trim());
              final warningValue = double.tryParse(warningLevel.trim());
              final criticalValue = double.tryParse(criticalLevel.trim());

              if (minValue == null ||
                  maxValue == null ||
                  warningValue == null ||
                  criticalValue == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Threshold values must be valid numbers'),
                  ),
                );
                return;
              }

              try {
                await db.create('threshold_values', {
                  'minThresholdValue': minValue,
                  'sensorId': sensorId.trim(),
                  'sensorParameterId': sensorParameterId.trim(),
                  'thresholdProfileId': thresholdProfileId.trim(),
                  'maxThresholdValue': maxValue,
                  'warningLevel': warningValue,
                  'criticalLevel': criticalValue,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create threshold value: $e'),
                    ),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(dialogContext),
          );
        },
      ),
    );
  }

  Future<void> _deleteThresholdProfile(
    BuildContext context,
    String profileId,
  ) async {
    if (profileId.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Threshold Profile'),
        content: const Text(
          'Are you sure you want to delete this threshold profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final db = ref.read(superAdminBackendChangeNotifierProvider);
      await db.delete('thresholds', profileId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete threshold profile: $e')),
      );
    }
  }

  Future<void> _deleteThresholdValue(
    BuildContext context,
    String thresholdValueId,
  ) async {
    if (thresholdValueId.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Threshold Value'),
        content: const Text(
          'Are you sure you want to delete this threshold value?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final db = ref.read(superAdminBackendChangeNotifierProvider);
      await db.delete('threshold_values', thresholdValueId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete threshold value: $e')),
      );
    }
  }

  Widget _buildThresholdManagementSection(BuildContext context, dynamic db) {
    final profileNameById = <String, String>{
      for (final profile in db.thresholdProfiles) profile.id: profile.name,
    };
    final sensorNameById = <String, String>{
      for (final sensor in db.sensors)
        sensor.id: sensor.name.trim().isEmpty
            ? (sensor.serialNumber.trim().isEmpty
                ? sensor.id
                : sensor.serialNumber)
            : sensor.name,
    };
    final sensorParameterLabelById = <String, String>{
      for (final parameter in db.sensorParameters)
        parameter.id: (() {
          final base =
              parameter.name.trim().isEmpty ? parameter.id : parameter.name;
          final calc = parameter.calculationName.trim();
          final unit = parameter.unit.trim();
          final label =
              calc.isNotEmpty && calc != base ? '$base ($calc)' : base;
          return unit.isEmpty ? label : '$label [$unit]';
        })(),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Threshold Management',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: OpsColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${db.thresholdProfiles.length} profiles · ${db.thresholdValues.length} values',
                    style: const TextStyle(
                      fontSize: 13,
                      color: OpsColors.muted,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showCreateThresholdProfileDialog(context),
                    icon: const Icon(Icons.add_chart_outlined),
                    label: const Text('Add Profile'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateThresholdValueDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Threshold'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Profiles',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpsColors.text,
            ),
          ),
          const SizedBox(height: 8),
          if (db.thresholdProfiles.isEmpty)
            Text(
              'No threshold profiles available',
              style: const TextStyle(color: OpsColors.muted),
            )
          else
            UniversalDataTable(
              minWidth: 680,
              columns: const [
                DataColumn(label: UniversalTableHeaderText('NAME')),
                DataColumn(label: UniversalTableHeaderText('DESCRIPTION')),
                DataColumn(label: UniversalTableHeaderText('ACTIONS')),
              ],
              rows: db.thresholdProfiles.map<DataRow>((profile) {
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: UniversalTableText(profile.name),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: UniversalTableText(
                          profile.description.trim().isEmpty
                              ? '--'
                              : profile.description,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Delete profile',
                        onPressed: () =>
                            _deleteThresholdProfile(context, profile.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 18),
          Text(
            'Threshold Values',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: OpsColors.text,
            ),
          ),
          const SizedBox(height: 8),
          if (db.thresholdValues.isEmpty)
            Text(
              'No threshold values configured',
              style: const TextStyle(color: OpsColors.muted),
            )
          else
            UniversalDataTable(
              minWidth: 1180,
              columns: const [
                DataColumn(label: UniversalTableHeaderText('SENSOR')),
                DataColumn(label: UniversalTableHeaderText('PROFILE')),
                DataColumn(label: UniversalTableHeaderText('SENSOR PARAMETER')),
                DataColumn(label: UniversalTableHeaderText('MIN')),
                DataColumn(label: UniversalTableHeaderText('MAX')),
                DataColumn(label: UniversalTableHeaderText('WARNING')),
                DataColumn(label: UniversalTableHeaderText('CRITICAL')),
                DataColumn(label: UniversalTableHeaderText('ACTIONS')),
              ],
              rows: db.thresholdValues.map<DataRow>((value) {
                final sensorName = value.sensorId.trim().isEmpty
                    ? 'All Sensors'
                    : (sensorNameById[value.sensorId] ?? value.sensorId);
                final profileName = profileNameById[value.thresholdProfileId] ??
                    value.thresholdProfileId;
                final parameterName =
                    sensorParameterLabelById[value.sensorParameterId] ??
                        value.sensorParameterId;
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: UniversalTableText(sensorName),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: UniversalTableText(profileName),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: UniversalTableText(parameterName),
                      ),
                    ),
                    DataCell(
                      UniversalTableText(value.minThreshold.toStringAsFixed(2)),
                    ),
                    DataCell(
                      UniversalTableText(value.maxThreshold.toStringAsFixed(2)),
                    ),
                    DataCell(
                      UniversalTableText(value.warningLevel.toStringAsFixed(2)),
                    ),
                    DataCell(
                      UniversalTableText(
                          value.criticalLevel.toStringAsFixed(2)),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Delete value',
                        onPressed: () =>
                            _deleteThresholdValue(context, value.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final alertsAsync = ref.watch(superAdminAlertsApiProvider);
    final apiAlerts = alertsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <Alert>[],
    );
    final allAlerts = apiAlerts;
    final activeCount = allAlerts
        .where((a) => a.status.trim().toUpperCase() == 'ACTIVE')
        .length;
    final criticalCount = allAlerts
        .where((a) => a.alertLevel.trim().toLowerCase() == 'critical')
        .length;
    final warningCount = allAlerts
        .where((a) => a.alertLevel.trim().toLowerCase() != 'critical')
        .length;

    return OpsPage(
      title: 'Alert Management',
      subtitle:
          'Monitor active warnings, critical incidents, ownership, and threshold activity across the platform',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(superAdminAlertsApiProvider),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh Alerts'),
        ),
        ElevatedButton.icon(
          onPressed: () => _showCreateAlertDialog(context),
          icon: const Icon(Icons.add_alert),
          label: const Text('Add Alert'),
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
                value: '$activeCount',
                helper: 'Unresolved',
                icon: Icons.notifications_active_rounded,
                color: OpsColors.danger,
              ),
              OpsKpiCard(
                label: 'Critical',
                value: '$criticalCount',
                helper: 'Immediate response',
                icon: Icons.priority_high_rounded,
                color: OpsColors.danger,
              ),
              OpsKpiCard(
                label: 'Warning',
                value: '$warningCount',
                helper: 'Monitoring required',
                icon: Icons.warning_amber_rounded,
                color: OpsColors.warning,
              ),
              OpsKpiCard(
                label: 'Sensor Sources',
                value:
                    '${allAlerts.map((a) => a.sensorId).where((id) => id.trim().isNotEmpty).toSet().length}',
                helper: 'Distinct sensors',
                icon: Icons.sensors_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          OpsPanel(
            title: 'Active Alerts',
            subtitle:
                'Severity, source, trigger time, ownership, and response state',
            child: _buildActiveAlertsPanel(
              context,
              allAlerts,
              onAcknowledge: (alertId) async {
                await AlertsApi.resolveAlert(alertId);
                ref.invalidate(superAdminAlertsApiProvider);
              },
              onEdit: (alert) => _showEditAlertDialog(context, alert),
              onDelete: (alert) => _deleteAlert(context, alert),
            ),
          ),
          const SizedBox(height: 16),
          OpsPanel(
            title: 'Threshold Management',
            subtitle:
                'Review threshold profiles, parameters, and value ranges used by alerting',
            child: _buildThresholdManagementSection(context, db),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int activeCount,
    required int criticalCount,
    required int warningCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(
              1.0,
              1.35,
            );
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 700
                ? 2
                : 1;
        final baseCardHeight = crossAxisCount == 3
            ? 96.0
            : crossAxisCount == 2
                ? 92.0
                : 88.0;
        final cardHeight = (baseCardHeight * textScale).clamp(88.0, 132.0);

        final cards = [
          _summaryCard(
            context,
            'Active Alerts',
            '$activeCount',
            Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF071d28)
                : const Color(0xFFD8E8F5),
          ),
          _summaryCard(
            context,
            'Critical',
            '$criticalCount',
            const Color(0xFFef2e38),
          ),
          _summaryCard(
            context,
            'Warnings',
            '$warningCount',
            const Color(0xFFd39a00),
          ),
        ];

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final veryCompact = constraints.maxHeight < 68;
        final compact = constraints.maxHeight < 78;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: veryCompact ? 6 : (compact ? 8 : 12),
          ),
          decoration: BoxDecoration(
            color: OpsColors.surface,
            borderRadius: BorderRadius.circular(8),
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: veryCompact ? 12 : (compact ? 13 : 15),
                  fontWeight: FontWeight.w700,
                  color: OpsColors.muted,
                ),
              ),
              SizedBox(height: veryCompact ? 1 : (compact ? 2 : 4)),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: veryCompact ? 17 : (compact ? 20 : 28),
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveAlertsPanel(
    BuildContext context,
    List<Alert> alerts, {
    required Future<void> Function(String alertId) onAcknowledge,
    required Future<void> Function(Alert alert) onEdit,
    required Future<void> Function(Alert alert) onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: OpsColors.text,
            ),
          ),
          const SizedBox(height: 14),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No alerts found',
                style: const TextStyle(color: OpsColors.muted),
              ),
            ),
          ...alerts.map((alert) {
            final isCritical =
                alert.alertLevel.trim().toLowerCase() == 'critical';
            final messageText =
                alert.message.trim().isEmpty ? '-' : alert.message.trim();
            final statusText =
                alert.status.trim().isEmpty ? '-' : alert.status.trim();
            final sensorText =
                alert.sensorId.trim().isEmpty ? '-' : alert.sensorId.trim();
            final sensorParameterText = alert.sensorParameterId.trim().isEmpty
                ? '-'
                : alert.sensorParameterId.trim();
            final assignedToText =
                alert.assignedTo.trim().isEmpty ? '-' : alert.assignedTo.trim();
            final acknowledgedText = alert.acknowledgedAt == null
                ? '-'
                : _formatDate(alert.acknowledgedAt!);
            final resolvedText =
                alert.resolvedAt == null ? '-' : _formatDate(alert.resolvedAt!);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OpsColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OpsColors.border),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final badge = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? const Color(0xFFef2e38)
                          : const Color(0xFFd39a00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.alertLevel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                isCritical
                                    ? Icons.cancel
                                    : Icons.warning_amber_rounded,
                                color: isCritical
                                    ? const Color(0xFFef2e38)
                                    : const Color(0xFFd39a00),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                messageText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: OpsColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Triggered: ${_formatDate(alert.triggeredAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Status: $statusText',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sensor: $sensorText | Parameter: $sensorParameterText',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Assigned To: $assignedToText',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Acknowledged: $acknowledgedText | Resolved: $resolvedText',
                          style: TextStyle(
                            fontSize: 13,
                            color: OpsColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _actionButton(
                              context,
                              label: 'Acknowledge',
                              onTap: alert.id.trim().isEmpty
                                  ? () {}
                                  : () => onAcknowledge(alert.id),
                            ),
                            _actionButton(
                              context,
                              label: 'View Details',
                              onTap: () => _showDetails(context, alert),
                            ),
                            _actionButton(
                              context,
                              label: 'Edit',
                              onTap: () => onEdit(alert),
                            ),
                            _actionButton(
                              context,
                              label: 'Delete',
                              onTap: () => onDelete(alert),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        badge,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isCritical
                              ? Icons.cancel
                              : Icons.warning_amber_rounded,
                          color: isCritical
                              ? const Color(0xFFef2e38)
                              : const Color(0xFFd39a00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OpsColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Triggered: ${_formatDate(alert.triggeredAt)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: OpsColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Status: $statusText',
                              style: TextStyle(
                                fontSize: 13,
                                color: OpsColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Sensor: $sensorText | Parameter: $sensorParameterText',
                              style: TextStyle(
                                fontSize: 13,
                                color: OpsColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Assigned To: $assignedToText',
                              style: TextStyle(
                                fontSize: 13,
                                color: OpsColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Acknowledged: $acknowledgedText | Resolved: $resolvedText',
                              style: TextStyle(
                                fontSize: 13,
                                color: OpsColors.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _actionButton(
                                  context,
                                  label: 'Acknowledge',
                                  onTap: alert.id.trim().isEmpty
                                      ? () {}
                                      : () => onAcknowledge(alert.id),
                                ),
                                _actionButton(
                                  context,
                                  label: 'View Details',
                                  onTap: () => _showDetails(context, alert),
                                ),
                                _actionButton(
                                  context,
                                  label: 'Edit',
                                  onTap: () => onEdit(alert),
                                ),
                                _actionButton(
                                  context,
                                  label: 'Delete',
                                  onTap: () => onDelete(alert),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      badge,
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _actionButton(
    context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: OpsColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OpsColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: OpsColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
