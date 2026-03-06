import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/threshold_profile.dart';
import '../providers/super_admin_backend_provider.dart';
import '../widgets/crud_modal.dart';
import '../widgets/crud_table.dart';

class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  String? _editingId;
  String _name = '';
  String _description = '';
  bool _showProfiles = true;

  String _sensorParameterId = '';
  String _thresholdProfileId = '';
  String _minThresholdValue = '0';
  String _maxThresholdValue = '0';
  String _warningLevel = '0';
  String _criticalLevel = '0';
  String _warrningLevel = '0';
  String _sensorParamterId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
      await db.loadSensors();
      await db.loadThresholdProfiles();
      await db.loadThresholdValues();
    });
  }

  void _showThresholdModal({ThresholdProfile? profile}) {
    if (profile != null) {
      _editingId = profile.id;
      _name = profile.name;
      _description = profile.description;
    } else {
      _editingId = null;
      _name = '';
      _description = '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: profile == null
                ? 'Add Threshold Profile'
                : 'Edit Threshold Profile',
            fields: [
              {
                'label': 'Name',
                'value': _name,
                'onChanged': (String value) => setState(() => _name = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Description',
                'value': _description,
                'onChanged': (String value) =>
                    setState(() => _description = value),
                'keyboardType': TextInputType.text,
              },
            ],
            onSave: () async {
              final db = Provider.of<SuperAdminBackendProvider>(context,
                  listen: false);
              try {
                if (_editingId == null) {
                  await db.create('thresholds', {
                    'name': _name,
                    'description': _description,
                  });
                } else {
                  await db.update('thresholds', _editingId!, {
                    'name': _name,
                    'description': _description,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save threshold: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _showThresholdValueModal() {
    final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
    final sensorOptions = db.sensors
        .where((sensor) => sensor.id.trim().isNotEmpty)
        .map((sensor) => {
              'value': sensor.id,
              'label':
                  sensor.serialNumber.isEmpty ? sensor.id : sensor.serialNumber,
            })
        .toList();
    if (sensorOptions.isEmpty) {
      sensorOptions.addAll(
        db.sensorParameters
            .where((param) => param.id.trim().isNotEmpty)
            .map((param) => {
                  'value': param.id,
                  'label': param.name.isEmpty ? param.id : param.name,
                }),
      );
    }

    _sensorParameterId =
        sensorOptions.isNotEmpty ? sensorOptions.first['value']! : '';
    _thresholdProfileId = db.thresholdProfiles.isNotEmpty
        ? db.thresholdProfiles.first.id
        : '';
    _minThresholdValue = '0';
    _maxThresholdValue = '0';
    _warningLevel = '0';
    _criticalLevel = '0';
    _warrningLevel = '0';
    _sensorParamterId = _sensorParameterId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: 'Add Threshold Value',
            fields: [
              {
                'label': 'minThresholdValue',
                'value': _minThresholdValue,
                'onChanged': (String value) =>
                    setState(() => _minThresholdValue = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'sensorParameterId',
                'type': 'select',
                'value':
                    _sensorParameterId.isEmpty ? null : _sensorParameterId,
                'options': sensorOptions,
                'onChanged': (String? value) => setState(() {
                  _sensorParameterId = value ?? '';
                  if (_sensorParamterId.isEmpty) {
                    _sensorParamterId = _sensorParameterId;
                  }
                }),
              },
              {
                'label': 'thresholdProfileId',
                'type': 'select',
                'value':
                    _thresholdProfileId.isEmpty ? null : _thresholdProfileId,
                'options': db.thresholdProfiles
                    .map((profile) => {
                          'value': profile.id,
                          'label': profile.name,
                        })
                    .toList(),
                'onChanged': (String? value) =>
                    setState(() => _thresholdProfileId = value ?? ''),
              },
              {
                'label': 'maxThresholdValue',
                'value': _maxThresholdValue,
                'onChanged': (String value) =>
                    setState(() => _maxThresholdValue = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'warningLevel',
                'value': _warningLevel,
                'onChanged': (String value) =>
                    setState(() => _warningLevel = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'criticalLevel',
                'value': _criticalLevel,
                'onChanged': (String value) =>
                    setState(() => _criticalLevel = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'warrningLevel',
                'value': _warrningLevel,
                'onChanged': (String value) =>
                    setState(() => _warrningLevel = value),
                'keyboardType': TextInputType.number,
              },
              {
                'label': 'sensorParamterId',
                'type': 'select',
                'value': _sensorParamterId.isEmpty ? null : _sensorParamterId,
                'options': sensorOptions,
                'onChanged': (String? value) =>
                    setState(() => _sensorParamterId = value ?? ''),
              },
            ],
            onSave: () async {
              if (_thresholdProfileId.trim().isEmpty ||
                  _sensorParameterId.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Threshold profile and sensor parameter are required'),
                  ),
                );
                return;
              }
              final minValue = int.tryParse(_minThresholdValue.trim());
              final maxValue = int.tryParse(_maxThresholdValue.trim());
              final warning = int.tryParse(_warningLevel.trim());
              final critical = int.tryParse(_criticalLevel.trim());
              final warrning = int.tryParse(_warrningLevel.trim());
              if (minValue == null ||
                  maxValue == null ||
                  warning == null ||
                  critical == null ||
                  warrning == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Threshold values must be integer numbers'),
                  ),
                );
                return;
              }

              final db = Provider.of<SuperAdminBackendProvider>(
                context,
                listen: false,
              );
              try {
                await db.create('threshold_values', {
                  'minThresholdValue': minValue,
                  'sensorParameterId': _sensorParameterId.trim(),
                  'thresholdProfileId': _thresholdProfileId.trim(),
                  'maxThresholdValue': maxValue,
                  'warningLevel': warning,
                  'criticalLevel': critical,
                  'warrningLevel': warrning,
                  'sensorParamterId': _sensorParamterId.trim().isEmpty
                      ? _sensorParameterId.trim()
                      : _sensorParamterId.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save threshold: $e')),
                  );
                }
              }
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        final profileNameById = <String, String>{
          for (final profile in db.thresholdProfiles) profile.id: profile.name,
        };
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Profiles'),
                    selected: _showProfiles,
                    onSelected: (_) => setState(() => _showProfiles = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Threshold Values'),
                    selected: !_showProfiles,
                    onSelected: (_) => setState(() => _showProfiles = false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showProfiles
                  ? CrudTable(
                      title: 'Threshold Profiles',
                      icon: Icons.settings,
                      columns: const ['Name', 'Description'],
                      data: db.thresholdProfiles
                          .map((profile) => [profile.name, profile.description])
                          .toList(),
                      onAdd: () => _showThresholdModal(),
                      onEdit: (index) => _showThresholdModal(
                          profile: db.thresholdProfiles[index]),
                      onDelete: (index) async {
                        try {
                          await db.delete(
                              'thresholds', db.thresholdProfiles[index].id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to delete threshold: $e')),
                            );
                          }
                        }
                      },
                    )
                  : CrudTable(
                      title: 'Threshold Values',
                      icon: Icons.tune,
                      columns: const [
                        'Profile',
                        'Sensor Parameter ID',
                        'Min',
                        'Max',
                        'Warning',
                        'Critical'
                      ],
                      data: db.thresholdValues
                          .map((value) => [
                                profileNameById[value.thresholdProfileId] ??
                                    value.thresholdProfileId,
                                value.sensorParameterId,
                                value.minThreshold.toStringAsFixed(2),
                                value.maxThreshold.toStringAsFixed(2),
                                value.warningLevel.toStringAsFixed(2),
                                value.criticalLevel.toStringAsFixed(2),
                              ])
                          .toList(),
                      onAdd: () => _showThresholdValueModal(),
                    ),
            ),
          ],
        );
      },
    );
  }
}
