import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;

import '../core/api/admin_api_config.dart';
import '../../../core/theme/ops_theme.dart';
import '../api/sensor_parameter_api.dart';
import '../models/sensor.dart';
import '../providers/super_admin_backend_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';

class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends ConsumerState<SensorsScreen> {
  String? _editingId;
  String _sensorName = '';
  String _serialNumber = '';
  String _deviceId = '';
  String _sensorTypeId = '';
  String _latitude = '37.7749';
  String _longitude = '-122.4194';
  bool _showFilters = false;
  bool _isListView = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  String _deviceFilter = 'all';
  String _organizationFilter = 'all';
  String _siteFilter = 'all';
  String _zoneFilter = 'all';
  String _locationFilter = 'all';
  final Set<String> _inactiveSensors = {};
  int _refreshKey = 0;

  String _generateClientSensorId() {
    const chars = '0123456789abcdef';
    final random = Random.secure();
    String hex(int count) =>
        List.generate(count, (_) => chars[random.nextInt(chars.length)]).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-${'89ab'[random.nextInt(4)]}${hex(3)}-${hex(12)}';
  }

  int _javaStringHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (31 * hash + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  String _buildAbsoluteUrl(String path) {
    final base = AdminApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }

  String _withUserIdPlaceholder(String url) {
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return '$normalized/{userId}';
  }

  Map<String, String> _endpointPreview({
    required String sensorId,
    required String sensorName,
  }) {
    final uid =
        (_javaStringHash(sensorId) % 1000000).toString().padLeft(6, '0');
    final normalizedSensorName = sensorName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+'), '')
        .replaceAll(RegExp(r'-+$'), '')
        .replaceAll(RegExp(r'-{2,}'), '-');
    final endpointKey =
        normalizedSensorName.isEmpty ? uid : '$uid-$normalizedSensorName';
    final ingestion =
        _withUserIdPlaceholder(_buildAbsoluteUrl('/api/v1/ingestion/$endpointKey'));
    final ingestionLive = _withUserIdPlaceholder(
      _buildAbsoluteUrl('/api/v1/ingestion/readings/live/$endpointKey'),
    );
    final processingLive = _withUserIdPlaceholder(
      _buildAbsoluteUrl('/api/v1/processing/readings/live/$endpointKey'),
    );
    final analyticsLive = _withUserIdPlaceholder(
      _buildAbsoluteUrl('/api/v1/analytics/events/live/$endpointKey'),
    );
    return {
      'endpointKey': endpointKey,
      'ingestion': ingestion,
      'ingestionLive': ingestionLive,
      'processingLive': processingLive,
      'analyticsLive': analyticsLive,
    };
  }

  String _requestBodyExample(List<Map<String, dynamic>> sensorParameters) {
    final payload = <String, String>{};
    for (final parameter in sensorParameters) {
      final name = (parameter['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      payload[name] = '';
    }
    if (payload.isEmpty) {
      payload['value'] = '';
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> _showSensorEndpointsDialog(
    BuildContext context,
    Sensor sensor,
    List<Map<String, dynamic>> sensorParameters,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sensor Endpoints'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: _endpointPanel(
              context,
              endpointKey: sensor.endpointKey,
              ingestionEndpoint: sensor.ingestionEndpoint,
              ingestionLiveEndpoint: sensor.ingestionLiveEndpoint,
              processingLiveEndpoint: sensor.processingLiveEndpoint,
              analyticsLiveEndpoint: sensor.analyticsLiveEndpoint,
              requestBodyExample: _requestBodyExample(sensorParameters),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Don't invalidate in initState - let provider load naturally
  }

  Future<void> _showSensorModal({Sensor? sensor}) async {
    final db =
        provider.Provider.of<SuperAdminBackendProvider>(context, listen: false);
    await db.loadDevices();
    await db.loadSensorTypes();
    await db.loadSensorParameters();
    if (!mounted) return;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF5A6F7D) : const Color(0xFFAEC4D7);
    final defaultDeviceId = db.devices.isNotEmpty ? db.devices.first.id : '';
    final defaultTypeId =
        db.sensorTypes.isNotEmpty ? db.sensorTypes.first.id : '';
    final draftSensorId = sensor?.id ?? _generateClientSensorId();
    final transientCreatedParameterIds = <String>{};
    var sensorSaved = false;
    String sensorParameterId = '';
    List<Map<String, dynamic>> sensorParametersForType = [];
    bool sensorParametersLoading = false;
    List<DropdownMenuItem<String>> parameterItems() {
      return sensorParametersForType
          .map(
            (param) => DropdownMenuItem<String>(
              value: (param['sensorParameterId'] ?? param['id'] ?? '')
                  .toString()
                  .trim(),
              child: Text(
                '${(param['name'] ?? '').toString().trim().isEmpty ? "Parameter" : (param['name'] ?? '').toString().trim()}'
                '${(param['unit'] ?? '').toString().trim().isEmpty ? "" : " (${(param['unit'] ?? '').toString().trim()})"}',
              ),
            ),
          )
          .where((item) => (item.value ?? '').trim().isNotEmpty)
          .toList();
    }

    Future<void> fetchParametersForType(
      String typeId, {
      void Function(void Function())? setDialogState,
      String? preferredParameterId,
      bool preserveSelection = true,
      void Function()? onSelectionChanged,
    }) async {
      final normalizedTypeId = typeId.trim();
      if (setDialogState != null) {
        setDialogState(() => sensorParametersLoading = true);
      } else {
        sensorParametersLoading = true;
      }
      try {
        var fetched = <Map<String, dynamic>>[];
        if (normalizedTypeId.isNotEmpty) {
          fetched = await SensorParameterApi.getParametersBySensorType(
            normalizedTypeId,
          );
        }
        if (fetched.isEmpty && normalizedTypeId.isNotEmpty) {
          fetched = db.sensorParameters
              .where((param) => param.sensorTypeId.trim() == normalizedTypeId)
              .map((param) => {
                    'sensorParameterId': param.id,
                    'sensorTypeId': param.sensorTypeId,
                    'name': param.name,
                    'unit': param.unit,
                    'minValue': param.minValue,
                    'maxValue': param.maxValue,
                  })
              .toList();
        }

        void apply() {
          sensorParametersForType = fetched;
          final options = parameterItems();
          final requested = (preferredParameterId ?? '').trim();
          final canUseRequested = requested.isNotEmpty &&
              options.any((item) => item.value == requested);
          if (canUseRequested) {
            sensorParameterId = requested;
          } else if (preserveSelection &&
              sensorParameterId.trim().isNotEmpty &&
              options.any((item) => item.value == sensorParameterId)) {
            // keep existing selection
          } else {
            sensorParameterId =
                options.isNotEmpty ? (options.first.value ?? '') : '';
          }
          sensorParametersLoading = false;
        }

        if (setDialogState != null) {
          setDialogState(apply);
        } else {
          apply();
        }
      } catch (_) {
        if (setDialogState != null) {
          setDialogState(() => sensorParametersLoading = false);
        } else {
          sensorParametersLoading = false;
        }
      } finally {
        onSelectionChanged?.call();
      }
    }

    if (sensor != null) {
      _editingId = sensor.id;
      _sensorName = sensor.serialNumber;
      _serialNumber = sensor.serialNumber;
      _deviceId = sensor.deviceId;
      _sensorTypeId = sensor.sensorTypeId;
    } else {
      _editingId = null;
      _sensorName = 'Sensor ${DateTime.now().millisecondsSinceEpoch % 10000}';
      _serialNumber =
          'SNMLQ${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      _deviceId = defaultDeviceId;
      _sensorTypeId = defaultTypeId;
    }
    await fetchParametersForType(_sensorTypeId);
    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sensor Form',
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDialogLight = theme.brightness == Brightness.light;
          final cornerRadius = BorderRadius.circular(22);
          final preview = _endpointPreview(
            sensorId: draftSensorId,
            sensorName: _sensorName,
          );
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: cornerRadius,
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(
                        alpha: isDialogLight ? 0.1 : 0.22,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _editingId == null
                                      ? 'Add New Sensor'
                                      : 'Edit Sensor',
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Configure sensor parameters and device connection',
                                  style:
                                      TextStyle(fontSize: 14, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _dialogTextField(
                        label: 'Serial Number',
                        value: _serialNumber,
                        onChanged: (v) => setState(() => _serialNumber = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        label: 'Sensor Name',
                        value: _sensorName,
                        onChanged: (v) => setState(() => _sensorName = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'Sensor Type',
                        value: _sensorTypeId.isEmpty ? null : _sensorTypeId,
                        hint: 'Select sensor type',
                        items: db.sensorTypes
                            .map((type) => DropdownMenuItem<String>(
                                  value: type.id,
                                  child: Text(type.name),
                                ))
                            .toList(),
                        onChanged: (value) async {
                          final nextTypeId = value ?? '';
                          setState(() {
                            _sensorTypeId = nextTypeId;
                            sensorParameterId = '';
                          });
                          await fetchParametersForType(
                            _sensorTypeId,
                            setDialogState: setState,
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _showCreateSensorTypeDialog();
                            if (!mounted) return;
                            await db.loadSensorTypes();
                            if (!context.mounted) return;
                            setState(() {
                              if (_sensorTypeId.isEmpty &&
                                  db.sensorTypes.isNotEmpty) {
                                _sensorTypeId = db.sensorTypes.first.id;
                              }
                            });
                            await fetchParametersForType(
                              _sensorTypeId,
                              setDialogState: setState,
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            db.sensorTypes.isEmpty
                                ? 'Create Sensor Type'
                                : 'Create New Sensor Type',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _parameterSection(
                        context,
                        sensorParametersLoading: sensorParametersLoading,
                        sensorParametersForType: sensorParametersForType,
                        onCreate: () async {
                          final createdParameterId =
                              await _showCreateOrEditSensorParameterDialog(
                            initialSensorTypeId: _sensorTypeId,
                          );
                          if (createdParameterId != null &&
                              createdParameterId.trim().isNotEmpty) {
                            transientCreatedParameterIds.add(
                              createdParameterId.trim(),
                            );
                          }
                          if (!mounted) return;
                          await db.loadSensorParameters();
                          if (!context.mounted) return;
                          await fetchParametersForType(
                            _sensorTypeId,
                            setDialogState: setState,
                            preferredParameterId: createdParameterId,
                          );
                        },
                        onEdit: (parameterId) async {
                          final updatedParameterId =
                              await _showCreateOrEditSensorParameterDialog(
                            initialSensorTypeId: _sensorTypeId,
                            editingParameterId: parameterId,
                          );
                          if (!mounted) return;
                          await db.loadSensorParameters();
                          if (!context.mounted) return;
                          await fetchParametersForType(
                            _sensorTypeId,
                            setDialogState: setState,
                            preferredParameterId: updatedParameterId,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogDropdown(
                              label: 'Connected Device',
                              value: _deviceId.isEmpty ? null : _deviceId,
                              hint: 'Select a device',
                              items: db.devices
                                  .map((device) => DropdownMenuItem<String>(
                                        value: device.id,
                                        child: Text(device.deviceCode),
                                      ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _deviceId = value ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _endpointPanel(
                        context,
                        endpointKey: preview['endpointKey'] ?? '',
                        ingestionEndpoint: preview['ingestion'] ?? '',
                        ingestionLiveEndpoint: preview['ingestionLive'] ?? '',
                        processingLiveEndpoint: preview['processingLive'] ?? '',
                        analyticsLiveEndpoint: preview['analyticsLive'] ?? '',
                        requestBodyExample:
                            _requestBodyExample(sensorParametersForType),
                        helperText: _deviceId.trim().isEmpty
                            ? 'Select a device to generate the exact sensor URLs.'
                            : (_editingId == null
                                ? 'These exact URLs will be created for this sensor when you save it.'
                                : 'These are the exact live endpoints for this sensor.'),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 560;
                          final title = Text(
                            'GPS Coordinates',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                          final action = OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _latitude = '37.7749';
                                _longitude = '-122.4194';
                              });
                            },
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text(
                              'Get Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                const SizedBox(height: 8),
                                action,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: title),
                              const SizedBox(width: 10),
                              action,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextField(
                              label: 'Latitude',
                              value: _latitude,
                              onChanged: (v) => setState(() => _latitude = v),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _dialogTextField(
                              label: 'Longitude',
                              value: _longitude,
                              onChanged: (v) => setState(() => _longitude = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final backend = provider.Provider.of<
                                    SuperAdminBackendProvider>(
                                  context,
                                  listen: false,
                                );
                                try {
                                  if (_deviceId.trim().isEmpty) {
                                    throw Exception(
                                      'Please select a device before saving sensor.',
                                    );
                                  }
                                  if (_sensorTypeId.trim().isEmpty) {
                                    throw Exception(
                                      'Please select sensor type or create one.',
                                    );
                                  }
                                  if (_editingId == null) {
                                    await backend.create('sensors', {
                                      'sensor_id': draftSensorId,
                                      'sensorId': draftSensorId,
                                      'name': _sensorName.trim(),
                                      'serial_number': _serialNumber.trim(),
                                      'device_id': _deviceId,
                                      'sensor_type_id': _sensorTypeId,
                                      if (sensorParameterId.trim().isNotEmpty)
                                        'sensor_parameter_id':
                                            sensorParameterId,
                                      if (sensorParameterId.trim().isNotEmpty)
                                        'sensorParameterId': sensorParameterId,
                                      'lat': _latitude.trim(),
                                      'log': _longitude.trim(),
                                      'status': 'ACTIVE',
                                      'unit': '',
                                    });
                                  } else {
                                    await backend
                                        .update('sensors', _editingId!, {
                                      'sensor_id': draftSensorId,
                                      'sensorId': draftSensorId,
                                      'name': _sensorName.trim(),
                                      'serial_number': _serialNumber.trim(),
                                      'device_id': _deviceId,
                                      'sensor_type_id': _sensorTypeId,
                                      if (sensorParameterId.trim().isNotEmpty)
                                        'sensor_parameter_id':
                                            sensorParameterId,
                                      if (sensorParameterId.trim().isNotEmpty)
                                        'sensorParameterId': sensorParameterId,
                                      'lat': _latitude.trim(),
                                      'log': _longitude.trim(),
                                      'status': 'ACTIVE',
                                      'unit': '',
                                    });
                                  }
                                  final savedSensorId =
                                      _editingId?.trim().isNotEmpty == true
                                          ? _editingId!
                                          : draftSensorId;
                                  final savedSensor = backend.sensors
                                      .where((item) => item.id == savedSensorId)
                                      .firstOrNull;
                                  if (savedSensor != null && context.mounted) {
                                    final savedSensorParameters = db
                                        .sensorParameters
                                        .where((param) =>
                                            param.sensorTypeId ==
                                            savedSensor.sensorTypeId)
                                        .map(
                                          (param) => {
                                            'sensorParameterId': param.id,
                                            'name': param.name,
                                            'unit': param.unit,
                                          },
                                        )
                                        .toList();
                                    await _showSensorEndpointsDialog(
                                      context,
                                      savedSensor,
                                      savedSensorParameters,
                                    );
                                  }
                                  sensorSaved = true;
                                  if (context.mounted) Navigator.pop(context);
                                  this.setState(() => _refreshKey++);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to save sensor: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(_editingId == null
                                  ? 'Add Sensor'
                                  : 'Save Sensor'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
    );

    if (!sensorSaved && transientCreatedParameterIds.isNotEmpty) {
      for (final parameterId in transientCreatedParameterIds) {
        try {
          await SensorParameterApi.deleteSensorParameter(parameterId);
        } catch (_) {
          // Best-effort cleanup for parameters created during abandoned sensor creation.
        }
      }
      if (mounted) {
        await db.loadSensorParameters();
      }
    }
  }

  Future<void> _showCreateSensorTypeDialog() async {
    String name = '';
    String category = 'general';
    String description = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Sensor Type'),
          content: StatefulBuilder(
            builder: (context, setDialogState) => SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogTextField(
                    label: 'Name',
                    value: name,
                    onChanged: (v) => setDialogState(() => name = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogTextField(
                    label: 'Category',
                    value: category,
                    onChanged: (v) => setDialogState(() => category = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogTextField(
                    label: 'Description',
                    value: description,
                    onChanged: (v) => setDialogState(() => description = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sensor type name is required')),
                  );
                  return;
                }
                try {
                  final backend =
                      provider.Provider.of<SuperAdminBackendProvider>(
                    context,
                    listen: false,
                  );
                  await backend.create('sensor_types', {
                    'name': name.trim(),
                    'category':
                        category.trim().isEmpty ? 'general' : category.trim(),
                    'description': description.trim(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create sensor type: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showCreateOrEditSensorParameterDialog({
    required String initialSensorTypeId,
    String? editingParameterId,
  }) async {
    final db =
        provider.Provider.of<SuperAdminBackendProvider>(context, listen: false);
    await db.loadSensorTypes();
    await db.loadSensorParameters();
    if (!mounted) return null;

    final editingParameter = db.sensorParameters
        .where((param) => param.id == editingParameterId)
        .firstOrNull;

    String sensorTypeId = editingParameter?.sensorTypeId ?? initialSensorTypeId;
    if (sensorTypeId.trim().isEmpty && db.sensorTypes.isNotEmpty) {
      sensorTypeId = db.sensorTypes.first.id;
    }
    String name = editingParameter?.name ?? '';
    String unit = editingParameter?.unit ?? '';
    String calculationName = editingParameter?.calculationName ?? '';
    String formulaType = editingParameter?.formulaType ?? '';
    String graphType = editingParameter?.graphType.isNotEmpty == true
        ? editingParameter!.graphType
        : 'line';
    String useFor = editingParameter?.useFor.isNotEmpty == true
        ? editingParameter!.useFor
        : 'custom';
    String? savedId;

    Map<String, String> presetForType(String typeId) {
      final matchingTypes =
          db.sensorTypes.where((type) => type.id == typeId).toList();
      final matchingType = matchingTypes.isEmpty ? null : matchingTypes.first;
      final typeName = (matchingType?.name ?? '').trim().toLowerCase();

      if (typeName.contains('tilt')) {
        return {
          'calculationName': 'Tilt Angle',
          'formulaType': 'tilt_angle_deg',
          'graphType': 'line',
          'useFor': 'custom',
          'unit': unit.isEmpty ? 'deg' : unit,
        };
      }
      if (typeName.contains('accel')) {
        return {
          'calculationName': 'Acceleration Magnitude',
          'formulaType': 'magnitude_xyz',
          'graphType': 'line',
          'useFor': 'custom',
          'unit': unit.isEmpty ? 'm/s²' : unit,
        };
      }
      return {
        'calculationName': calculationName,
        'formulaType': formulaType,
        'graphType': graphType,
        'useFor': useFor,
        'unit': unit,
      };
    }

    void applyPresetForType(String typeId) {
      final preset = presetForType(typeId);
      calculationName = preset['calculationName'] ?? calculationName;
      formulaType = preset['formulaType'] ?? formulaType;
      graphType = preset['graphType'] ?? graphType;
      useFor = preset['useFor'] ?? useFor;
      unit = preset['unit'] ?? unit;
    }

    if (editingParameter == null && sensorTypeId.trim().isNotEmpty) {
      applyPresetForType(sensorTypeId);
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            editingParameter == null
                ? 'Create Sensor Parameter'
                : 'Edit Sensor Parameter',
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) => SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogDropdown(
                    label: 'Sensor Type',
                    value: sensorTypeId.isEmpty ? null : sensorTypeId,
                    hint: 'Select sensor type',
                    items: db.sensorTypes
                        .map((type) => DropdownMenuItem<String>(
                              value: type.id,
                              child: Text(type.name),
                            ))
                        .toList(),
                    onChanged: (value) => setDialogState(() {
                      sensorTypeId = value ?? '';
                      if (editingParameter == null) {
                        applyPresetForType(sensorTypeId);
                      }
                    }),
                  ),
                  const SizedBox(height: 10),
                  _dialogTextField(
                    label: 'Name',
                    value: name,
                    onChanged: (v) => setDialogState(() => name = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogTextField(
                    label: 'Unit',
                    value: unit,
                    onChanged: (v) => setDialogState(() => unit = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogTextField(
                    label: 'Calculation Name',
                    value: calculationName,
                    onChanged: (v) =>
                        setDialogState(() => calculationName = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    label: 'Formula',
                    value: formulaType.isEmpty ? null : formulaType,
                    hint: 'Select calculation formula',
                    items: const [
                      DropdownMenuItem(
                        value: 'x',
                        child: Text('X only'),
                      ),
                      DropdownMenuItem(
                        value: 'y',
                        child: Text('Y only'),
                      ),
                      DropdownMenuItem(
                        value: 'z',
                        child: Text('Z only'),
                      ),
                      DropdownMenuItem(
                        value: 'average_xyz',
                        child: Text('Average of X, Y, Z'),
                      ),
                      DropdownMenuItem(
                        value: 'magnitude_xyz',
                        child: Text('Magnitude sqrt(x²+y²+z²)'),
                      ),
                      DropdownMenuItem(
                        value: 'tilt_angle_deg',
                        child: Text('Tilt angle from X, Y, Z'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => formulaType = value ?? ''),
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    label: 'Graph Type',
                    value: graphType,
                    hint: 'Select graph type',
                    items: const [
                      DropdownMenuItem(value: 'line', child: Text('Line')),
                      DropdownMenuItem(value: 'bar', child: Text('Bar')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => graphType = value ?? 'line'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (sensorTypeId.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sensor type is required')),
                  );
                  return;
                }
                if (name.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sensor parameter name is required')),
                  );
                  return;
                }
                if (formulaType.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calculation formula is required')),
                  );
                  return;
                }
                try {
                  Map<String, dynamic> response;
                  if (editingParameter == null) {
                    response = await SensorParameterApi.createSensorParameter(
                      sensorTypeId: sensorTypeId,
                      name: name.trim(),
                      unit: unit.trim(),
                      minValue: 0,
                      maxValue: 0,
                      calculationName: calculationName.trim().isEmpty
                          ? name.trim()
                          : calculationName.trim(),
                      formulaType: formulaType.trim(),
                      graphType: graphType.trim(),
                      useFor: useFor.trim(),
                    );
                  } else {
                    response = await SensorParameterApi.updateSensorParameter(
                      sensorTypeId: sensorTypeId,
                      sensorParameterId: editingParameter.id,
                      name: name.trim(),
                      unit: unit.trim(),
                      minValue: 0,
                      maxValue: 0,
                      calculationName: calculationName.trim().isEmpty
                          ? name.trim()
                          : calculationName.trim(),
                      formulaType: formulaType.trim(),
                      graphType: graphType.trim(),
                      useFor: useFor.trim(),
                    );
                  }
                  final responseId =
                      (response['sensorParameterId'] ?? response['id'] ?? '')
                          .toString()
                          .trim();
                  savedId = responseId.isNotEmpty
                      ? responseId
                      : (editingParameter?.id ?? '');
                  await db.loadSensorParameters();
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed to save sensor parameter: $e')),
                  );
                }
              },
              child: Text(editingParameter == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );
    return savedId;
  }

  Widget _dialogTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF7FAFC)
                : const Color(0xFF1A3347),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          iconSize: 18,
          style: const TextStyle(fontSize: 12.5),
          hint: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5),
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dropdownItemLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF7FAFC)
                : const Color(0xFF1A3347),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _endpointPanel(
    BuildContext context, {
    required String endpointKey,
    required String ingestionEndpoint,
    required String ingestionLiveEndpoint,
    required String processingLiveEndpoint,
    required String analyticsLiveEndpoint,
    required String requestBodyExample,
    String? helperText,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor =
        isLight ? const Color(0xFF1B313D) : const Color(0xFFE2EDF8);
    final mutedColor =
        isLight ? const Color(0xFF5A6F7D) : const Color(0xFFAEC4D7);

    Widget endpointRow(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF7FAFC) : const Color(0xFF1A3347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exact Sensor URLs',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if ((helperText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: TextStyle(fontSize: 12.5, color: mutedColor),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Use a valid userId as the final path segment. These endpoints now verify that user before returning data.',
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          const SizedBox(height: 10),
          endpointRow('Endpoint Key', endpointKey),
          const SizedBox(height: 10),
          endpointRow('POST Ingestion', ingestionEndpoint),
          const SizedBox(height: 10),
          endpointRow('Live Ingestion SSE', ingestionLiveEndpoint),
          const SizedBox(height: 10),
          endpointRow('Live Processing SSE', processingLiveEndpoint),
          const SizedBox(height: 10),
          endpointRow('Live Analytics SSE', analyticsLiveEndpoint),
          const SizedBox(height: 10),
          endpointRow('Request Body Example', requestBodyExample),
        ],
      ),
    );
  }

  Widget _parameterSection(
    BuildContext context, {
    required bool sensorParametersLoading,
    required List<Map<String, dynamic>> sensorParametersForType,
    required Future<void> Function() onCreate,
    required Future<void> Function(String parameterId) onEdit,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor =
        isLight ? const Color(0xFF1B313D) : const Color(0xFFE2EDF8);
    final mutedColor =
        isLight ? const Color(0xFF5A6F7D) : const Color(0xFFAEC4D7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF7FAFC) : const Color(0xFF1A3347),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'API Parameters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                tooltip: 'Add parameter',
              ),
            ],
          ),
          Text(
            'Add payload fields like x, y, z. These fields will appear in the ingestion request body.',
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          if (sensorParametersLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 8),
          if (sensorParametersForType.isEmpty)
            Text(
              'No parameters added yet.',
              style: TextStyle(fontSize: 12.5, color: mutedColor),
            )
          else
            ...sensorParametersForType.map((parameter) {
              final parameterId =
                  (parameter['sensorParameterId'] ?? parameter['id'] ?? '')
                      .toString()
                      .trim();
              final name = (parameter['name'] ?? '').toString().trim();
              final unit = (parameter['unit'] ?? '').toString().trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isLight ? Colors.white : const Color(0xFF132A3B),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          unit.isEmpty ? name : '$name ($unit)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: parameterId.isEmpty
                          ? null
                          : () => onEdit(parameterId),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit parameter',
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _dropdownItemLabel(DropdownMenuItem<String> item) {
    final child = item.child;
    if (child is Text) return child.data ?? (item.value ?? '');
    return item.value ?? '';
  }

  String _sensorCodeFor(int index) => 'SEN-${[
        'H002B',
        'P003C',
        'V004D',
        'T005E',
        'X006F',
        'Y007G'
      ][index % 6]}';

  String _sensorTypeLabel(String id, SuperAdminBackendProvider db) {
    return db.sensorTypes
            .where((t) => t.id == id)
            .map((t) => t.name)
            .firstOrNull ??
        'Sensor';
  }

  IconData _iconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('humidity')) return Icons.water_drop_outlined;
    if (lower.contains('pressure')) return Icons.speed_outlined;
    if (lower.contains('vibration')) return Icons.waves_outlined;
    if (lower.contains('temperature') || lower.contains('thermal')) {
      return Icons.sensors;
    }
    if (lower.contains('tilt') || lower.contains('inclinometer')) {
      return Icons.show_chart;
    }
    return Icons.sensors;
  }

  String _unitForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('humidity')) return '%';
    if (lower.contains('pressure')) return 'Pa';
    if (lower.contains('vibration')) return 'mm/s';
    if (lower.contains('temperature') || lower.contains('thermal')) return 'C';
    return '';
  }

  int _channelFor(int index) => (index % 4) + 1;

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this sensor?'),
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
    return confirmed == true;
  }

  void _togglePower(String sensorId) {
    setState(() {
      if (_inactiveSensors.contains(sensorId)) {
        _inactiveSensors.remove(sensorId);
      } else {
        _inactiveSensors.add(sensorId);
      }
    });
  }

  bool _matchesFilters(SuperAdminBackendProvider db, Sensor sensor) {
    final globalIndex = db.sensors.indexOf(sensor);
    final safeIndex = globalIndex < 0 ? 0 : globalIndex;
    final type = _sensorTypeLabel(sensor.sensorTypeId, db);
    final deviceName = db.devices
            .where((d) => d.id == sensor.deviceId)
            .map((d) => d.deviceCode)
            .firstOrNull ??
        '';
    final sensorCode = _sensorCodeFor(safeIndex);
    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      final matchesQuery = sensorCode.toLowerCase().contains(query) ||
          sensor.serialNumber.toLowerCase().contains(query) ||
          deviceName.toLowerCase().contains(query) ||
          type.toLowerCase().contains(query);
      if (!matchesQuery) return false;
    }

    if (_statusFilter != 'all') {
      final isActive = !_inactiveSensors.contains(sensor.id);
      if (_statusFilter == 'active' && !isActive) return false;
      if (_statusFilter == 'inactive' && isActive) return false;
    }

    if (_typeFilter != 'all' && sensor.sensorTypeId != _typeFilter) {
      return false;
    }

    if (_deviceFilter != 'all' && sensor.deviceId != _deviceFilter) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sensorsAsync = ref.watch(sensorsProvider(_refreshKey));

    return sensorsAsync.when(
      data: (sensors) => _buildContent(context, sensors),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading sensors: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(sensorsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Sensor> allSensors) {
    return provider.Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        final sensors =
            allSensors.where((s) => _matchesFilters(db, s)).toList();
        final activeSensors =
            allSensors.where((s) => !_inactiveSensors.contains(s.id)).length;
        final inactiveSensors =
            allSensors.where((s) => _inactiveSensors.contains(s.id)).length;
        final assignedDevices = allSensors
            .where((s) => s.deviceId.trim().isNotEmpty)
            .map((s) => s.deviceId)
            .toSet()
            .length;
        final typeCount = allSensors
            .where((s) => s.sensorTypeId.trim().isNotEmpty)
            .map((s) => s.sensorTypeId)
            .toSet()
            .length;

        return OpsPage(
          title: 'Sensors',
          subtitle:
              'Track sensor inventory, linked devices, deployment coverage, and operational status across the platform',
          actions: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _isListView = !_isListView),
              icon: Icon(
                _isListView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                size: 18,
              ),
              label: Text(_isListView ? 'Cards' : 'List'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showSensorModal(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Sensor'),
            ),
          ],
          child: Column(
            children: [
              OpsKpiGrid(
                maxColumns: 6,
                minCardWidth: 145,
                spacing: 12,
                cardHeight: 126,
                cards: [
                  OpsKpiCard(
                    label: 'Total Sensors',
                    value: '${allSensors.length}',
                    helper: 'Platform inventory',
                    icon: Icons.sensors_rounded,
                  ),
                  OpsKpiCard(
                    label: 'Active Sensors',
                    value: '$activeSensors',
                    helper: 'Currently enabled',
                    icon: Icons.check_circle_rounded,
                    color: OpsColors.success,
                  ),
                  OpsKpiCard(
                    label: 'Inactive Sensors',
                    value: '$inactiveSensors',
                    helper: 'Toggled off',
                    icon: Icons.power_settings_new_rounded,
                    color: OpsColors.warning,
                  ),
                  OpsKpiCard(
                    label: 'Sensor Types',
                    value: '$typeCount',
                    helper: 'Distinct categories',
                    icon: Icons.category_outlined,
                  ),
                  OpsKpiCard(
                    label: 'Assigned Devices',
                    value: '$assignedDevices',
                    helper: 'Linked hardware',
                    icon: Icons.memory_rounded,
                    color: OpsColors.primaryContainer,
                  ),
                  OpsKpiCard(
                    label: 'Filtered View',
                    value: '${sensors.length}',
                    helper: 'Of ${allSensors.length} total',
                    icon: Icons.filter_alt_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OpsPanel(
                title: 'Sensor Inventory',
                subtitle:
                    'Serial details, sensor type, linked device, channel mapping, and power actions',
                child: Column(
                  children: [
                    if (_showFilters) ...[
                      _buildFiltersPanel(
                          context, db, sensors.length, allSensors.length),
                      const SizedBox(height: 14),
                    ],
                    if (sensors.isEmpty)
                      const OpsEmptyState(
                        title: 'No sensors found',
                        message:
                            'No sensors match the selected filters or current search query.',
                        icon: Icons.sensors_off_outlined,
                      )
                    else
                      (_isListView
                          ? _buildList(context, db, sensors)
                          : _buildGrid(context, db, sensors)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sensor Management',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: OpsColors.text,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Configure and monitor sensors',
              style: TextStyle(
                fontSize: 15,
                color: OpsColors.muted,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _headerButton(
              context: context,
              label: 'Filters',
              icon: Icons.filter_list,
              onTap: () => setState(() => _showFilters = !_showFilters),
            ),
            _headerButton(
              context: context,
              label: _isListView ? 'Cards' : 'List',
              icon: _isListView
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
              onTap: () => setState(() => _isListView = !_isListView),
            ),
            _headerButton(
              context: context,
              label: 'Export',
              icon: Icons.upload_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export started')),
                );
              },
            ),
            _headerButton(
              context: context,
              label: 'Add',
              icon: Icons.add,
              primary: true,
              onTap: () => _showSensorModal(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = primary
        ? const Color(0xFF0f729c)
        : (isLight ? const Color(0xFFe6eff3) : const Color(0xFF243E52));
    final border = primary
        ? const Color(0xFF0f729c)
        : (isLight ? const Color(0xFFc8d6dd) : Theme.of(context).dividerColor);
    final fg = primary
        ? Colors.white
        : (isLight ? const Color(0xFF18313f) : const Color(0xFFD7E8F6));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel(
    BuildContext context,
    SuperAdminBackendProvider db,
    int filteredCount,
    int totalCount,
  ) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor =
        isLight ? const Color(0xFF243946) : const Color(0xFFD8E8F5);
    final mutedColor =
        isLight ? const Color(0xFF60717c) : const Color(0xFF9FB4C6);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Sensors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 290,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: _filterFieldDecoration(
                    label: 'Search',
                    hint: 'Sensor ID, Serial, MAC...',
                    icon: Icons.search,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: _filterFieldDecoration(label: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) =>
                      setState(() => _statusFilter = value ?? 'all'),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _typeFilter,
                  decoration: _filterFieldDecoration(label: 'Sensor Type'),
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('All Types')),
                    ...db.sensorTypes.map(
                      (type) => DropdownMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _typeFilter = value ?? 'all'),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _deviceFilter,
                  decoration: _filterFieldDecoration(label: 'Device'),
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('All Devices')),
                    ...db.devices.map(
                      (device) => DropdownMenuItem(
                        value: device.id,
                        child: Text(device.deviceCode),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _deviceFilter = value ?? 'all'),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isLight
                      ? const Color(0xFFe6eff3)
                      : const Color(0xFF243E52),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Showing $filteredCount of $totalCount sensors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLight
                        ? const Color(0xFF324956)
                        : const Color(0xFFD4E5F2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Text(
            'LOCATION HIERARCHY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _hierarchyDropdown(
                label: 'Organization',
                value: _organizationFilter,
                onChanged: (value) =>
                    setState(() => _organizationFilter = value ?? 'all'),
              ),
              _hierarchyDropdown(
                label: 'Site',
                value: _siteFilter,
                onChanged: (value) =>
                    setState(() => _siteFilter = value ?? 'all'),
              ),
              _hierarchyDropdown(
                label: 'Zone',
                value: _zoneFilter,
                onChanged: (value) =>
                    setState(() => _zoneFilter = value ?? 'all'),
              ),
              _hierarchyDropdown(
                label: 'Location',
                value: _locationFilter,
                onChanged: (value) =>
                    setState(() => _locationFilter = value ?? 'all'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hierarchyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _filterFieldDecoration(label: label),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('All')),
        ],
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _filterFieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      isDense: true,
      filled: true,
      fillColor: isLight ? const Color(0xFFF4F8FA) : const Color(0xFF223B4E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    SuperAdminBackendProvider db,
    List<Sensor> sensors,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 2
            : width >= 700
                ? 2
                : 1;
        final ratio = width >= 1300
            ? 1.65
            : width >= 1000
                ? 1.4
                : width >= 700
                    ? 1.1
                    : 0.95;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sensors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final sensor = sensors[index];
            final globalIndex = db.sensors.indexOf(sensor);
            final type = _sensorTypeLabel(sensor.sensorTypeId, db);
            final deviceName = db.devices
                    .where((d) => d.id == sensor.deviceId)
                    .map((d) => d.deviceCode)
                    .firstOrNull ??
                'Unassigned';
            final isActive = !_inactiveSensors.contains(sensor.id);
            final siteName = db.sites
                    .where((s) =>
                        s.id ==
                        db.devices
                            .where((d) => d.id == sensor.deviceId)
                            .map((d) => d.siteId)
                            .firstOrNull)
                    .map((s) => s.name)
                    .firstOrNull ??
                'Location not set';

            return _SensorCard(
              title: _sensorCodeFor(globalIndex < 0 ? index : globalIndex),
              sensorType: type,
              serial: sensor.serialNumber,
              endpointKey: sensor.endpointKey,
              connectedDevice: deviceName,
              channel: _channelFor(globalIndex < 0 ? index : globalIndex),
              unit: _unitForType(type),
              location: siteName,
              icon: _iconForType(type),
              status: isActive ? 'active' : 'inactive',
              onEdit: () => _showSensorModal(sensor: sensor),
              onPower: () => _togglePower(sensor.id),
              onDelete: () async {
                final confirm = await _confirmDelete(context);
                if (!confirm || !context.mounted) return;
                try {
                  await db.delete('sensors', sensor.id);
                  setState(() => _refreshKey++);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete sensor: $e')),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    SuperAdminBackendProvider db,
    List<Sensor> sensors,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sensors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        final globalIndex = db.sensors.indexOf(sensor);
        final safeIndex = globalIndex < 0 ? index : globalIndex;
        final type = _sensorTypeLabel(sensor.sensorTypeId, db);
        final deviceName = db.devices
                .where((d) => d.id == sensor.deviceId)
                .map((d) => d.deviceCode)
                .firstOrNull ??
            'Unassigned';
        final siteName = db.sites
                .where((s) =>
                    s.id ==
                    db.devices
                        .where((d) => d.id == sensor.deviceId)
                        .map((d) => d.siteId)
                        .firstOrNull)
                .map((s) => s.name)
                .firstOrNull ??
            'Location not set';
        final status =
            _inactiveSensors.contains(sensor.id) ? 'inactive' : 'active';
        final isLight = Theme.of(context).brightness == Brightness.light;
        final statusColor = status == 'active'
            ? const Color(0xFF0ca15f)
            : (isLight ? const Color(0xFF8397a3) : const Color(0xFF9FB4C6));
        final metaLine =
            '${sensor.serialNumber} • $deviceName • ${_channelFor(safeIndex)} • ${_unitForType(type)} • $siteName'
            '${sensor.endpointKey.trim().isEmpty ? '' : ' • ${sensor.endpointKey}'}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForType(type),
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_sensorCodeFor(safeIndex)} • $type',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF152733)
                            : const Color(0xFFE2EDF8),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                metaLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF4a6170)
                      : const Color(0xFFBBD0E0),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showSensorModal(sensor: sensor),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: isLight
                          ? const Color(0xFF2F4654)
                          : const Color(0xFFBBD0E0),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _togglePower(sensor.id),
                    icon: Icon(Icons.power_settings_new, color: statusColor),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () async {
                      final confirm = await _confirmDelete(context);
                      if (!confirm || !context.mounted) return;
                      try {
                        await db.delete('sensors', sensor.id);
                        setState(() => _refreshKey++);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete sensor: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String sensorType;
  final String serial;
  final String endpointKey;
  final String connectedDevice;
  final int channel;
  final String unit;
  final String location;
  final IconData icon;
  final String status;
  final VoidCallback onEdit;
  final VoidCallback onPower;
  final VoidCallback onDelete;

  const _SensorCard({
    required this.title,
    required this.sensorType,
    required this.serial,
    required this.endpointKey,
    required this.connectedDevice,
    required this.channel,
    required this.unit,
    required this.location,
    required this.icon,
    required this.status,
    required this.onEdit,
    required this.onPower,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final statusColor =
        isActive ? const Color(0xFF0ca15f) : const Color(0xFF8397a3);

    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: OpsColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: OpsColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 30 > 22 ? 30 - 8 : 22,
                        fontWeight: FontWeight.w800,
                        color: OpsColors.text,
                      ),
                    ),
                    Text(
                      sensorType,
                      style: TextStyle(
                        fontSize: 14,
                        color: OpsColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _meta(context, 'Serial Number', serial),
          const SizedBox(height: 8),
          if (endpointKey.trim().isNotEmpty) ...[
            _meta(context, 'Endpoint Key', endpointKey),
            const SizedBox(height: 8),
          ],
          _meta(context, 'Connected Device', connectedDevice),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _meta(context, 'Channel', '$channel')),
              const SizedBox(width: 10),
              Expanded(child: _meta(context, 'Unit', unit)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: OpsColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: OpsColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OpsColors.text,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _iconButton(
                  context: context, icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 8),
              _iconButton(
                context: context,
                icon: Icons.power_settings_new,
                onTap: onPower,
                iconColor: statusColor,
              ),
              const SizedBox(width: 8),
              _iconButton(
                context: context,
                icon: Icons.delete_outline,
                onTap: onDelete,
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isLight ? const Color(0xFF60717c) : const Color(0xFF9FB4C6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            color: isLight ? const Color(0xFF152733) : const Color(0xFFE2EDF8),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final resolvedIconColor = iconColor ??
        (isLight ? const Color(0xFF2F4654) : const Color(0xFFBBD0E0));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFe6eff3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, size: 20, color: resolvedIconColor),
      ),
    );
  }
}
