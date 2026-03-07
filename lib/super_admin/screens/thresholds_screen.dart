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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
      await db.loadSensorTypes();
      await db.loadSensorParameters();
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

  Future<void> _showThresholdValueModal() async {
    final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
    await db.loadSensorTypes();
    await db.loadSensorParameters();
    await db.loadThresholdProfiles();
    if (!mounted) return;

    String sensorTypeId = '';
    List<Map<String, String>> buildParameterOptions(String typeId) {
      var filtered = db.sensorParameters
          .where((param) => param.id.trim().isNotEmpty)
          .toList();
      if (typeId.trim().isNotEmpty) {
        filtered = filtered
            .where((param) => param.sensorTypeId.trim() == typeId.trim())
            .toList();
      }
      if (filtered.isEmpty) {
        filtered = db.sensorParameters
            .where((param) => param.id.trim().isNotEmpty)
            .toList();
      }
      return filtered
          .map((param) => {
                'value': param.id,
                'label': param.name.trim().isEmpty ? 'Parameter' : param.name,
              })
          .toList();
    }

    if (db.sensorTypes.isNotEmpty) {
      final firstWithParameter = db.sensorTypes
          .where((type) => db.sensorParameters
              .any((param) => param.sensorTypeId.trim() == type.id.trim()))
          .map((type) => type.id)
          .firstOrNull;
      sensorTypeId = firstWithParameter ?? db.sensorTypes.first.id;
    }

    var sensorParameterOptions = buildParameterOptions(sensorTypeId);

    _sensorParameterId = sensorParameterOptions.isNotEmpty
        ? sensorParameterOptions.first['value']!
        : '';
    _thresholdProfileId =
        db.thresholdProfiles.isNotEmpty ? db.thresholdProfiles.first.id : '';
    _minThresholdValue = '0';
    _maxThresholdValue = '0';
    _warningLevel = '0';
    _criticalLevel = '0';

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
                'label': 'sensorTypeId',
                'type': 'select',
                'value': sensorTypeId.isEmpty ? null : sensorTypeId,
                'options': db.sensorTypes
                    .where((type) => type.id.trim().isNotEmpty)
                    .map((type) => {
                          'value': type.id,
                          'label': type.name.isEmpty ? type.id : type.name,
                        })
                    .toList(),
                'onChanged': (String? value) => setState(() {
                      sensorTypeId = value ?? '';
                      sensorParameterOptions =
                          buildParameterOptions(sensorTypeId);
                      if (sensorParameterOptions.isEmpty) {
                        _sensorParameterId = '';
                      } else if (!sensorParameterOptions
                          .any((opt) => opt['value'] == _sensorParameterId)) {
                        _sensorParameterId =
                            sensorParameterOptions.first['value']!;
                      }
                    }),
              },
              {
                'label': 'sensorParameterId',
                'type': 'select',
                'value': _sensorParameterId.isEmpty ? null : _sensorParameterId,
                'options': sensorParameterOptions,
                'onChanged': (String? value) => setState(() {
                      _sensorParameterId = value ?? '';
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
                          'label': profile.description.trim().isEmpty
                              ? profile.name
                              : '${profile.name} - ${profile.description}',
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
              if (minValue == null ||
                  maxValue == null ||
                  warning == null ||
                  critical == null) {
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
                        'Threshold Value ID',
                        'Profile',
                        'Sensor Parameter ID',
                        'Min',
                        'Max',
                        'Warning',
                        'Critical'
                      ],
                      data: db.thresholdValues
                          .map((value) => [
                                value.id,
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
                      onDelete: (index) async {
                        try {
                          await db.delete(
                            'threshold_values',
                            db.thresholdValues[index].id,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete threshold value: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
