import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor.dart';
import '../providers/database_provider.dart';
import '../widgets/crud_modal.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  String? _editingId;
  String _serialNumber = '';
  String _deviceId = '';
  String _sensorTypeId = '';
  String _typeFilter = 'all';
  final Set<String> _inactiveSensors = {};

  void _showSensorModal({Sensor? sensor}) {
    final db = Provider.of<DatabaseProvider>(context, listen: false);

    if (sensor != null) {
      _editingId = sensor.id;
      _serialNumber = sensor.serialNumber;
      _deviceId = sensor.deviceId;
      _sensorTypeId = sensor.sensorTypeId;
    } else {
      _editingId = null;
      _serialNumber = '';
      _deviceId = db.devices.isNotEmpty ? db.devices.first.id : '';
      _sensorTypeId = db.sensorTypes.isNotEmpty ? db.sensorTypes.first.id : '';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CrudModal(
            title: sensor == null ? 'Add Sensor' : 'Edit Sensor',
            fields: [
              {
                'label': 'Serial Number',
                'value': _serialNumber,
                'onChanged': (String value) =>
                    setState(() => _serialNumber = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Device',
                'type': 'select',
                'value': _deviceId,
                'onChanged': (String? value) =>
                    setState(() => _deviceId = value ?? _deviceId),
                'options': db.devices
                    .map((device) =>
                        {'label': device.deviceCode, 'value': device.id})
                    .toList(),
              },
              {
                'label': 'Sensor Type',
                'type': 'select',
                'value': _sensorTypeId,
                'onChanged': (String? value) =>
                    setState(() => _sensorTypeId = value ?? _sensorTypeId),
                'options': db.sensorTypes
                    .map((type) => {'label': type.name, 'value': type.id})
                    .toList(),
              },
            ],
            onSave: () {
              final db = Provider.of<DatabaseProvider>(context, listen: false);
              if (_editingId == null) {
                db.create('sensors', {
                  'serial_number': _serialNumber,
                  'device_id': _deviceId,
                  'sensor_type_id': _sensorTypeId,
                });
              } else {
                db.update('sensors', _editingId!, {
                  'serial_number': _serialNumber,
                  'device_id': _deviceId,
                  'sensor_type_id': _sensorTypeId,
                });
              }
              Navigator.pop(context);
            },
            onCancel: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  String _sensorCodeFor(int index) => 'SEN-${[
        'H002B',
        'P003C',
        'V004D',
        'T005E',
        'X006F',
        'Y007G'
      ][index % 6]}';

  String _sensorTypeLabel(String id, DatabaseProvider db) {
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
      return Icons.device_thermostat_outlined;
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
    if (lower.contains('temperature') || lower.contains('thermal')) return '°C';
    return '°';
  }

  int _channelFor(int index) => (index % 4) + 1;

  void _togglePower(String sensorId) {
    setState(() {
      if (_inactiveSensors.contains(sensorId)) {
        _inactiveSensors.remove(sensorId);
      } else {
        _inactiveSensors.add(sensorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        final sensors = db.sensors.where((s) {
          if (_typeFilter == 'all') return true;
          return s.sensorTypeId == _typeFilter;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, db),
              const SizedBox(height: 18),
              _buildGrid(context, db, sensors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DatabaseProvider db) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor Management',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF0f202d)
                    : const Color(0xFFd4e4ef),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Configure and monitor sensors',
              style: TextStyle(fontSize: 15, color: Color(0xFF4e6473)),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _headerButton(
              label: 'Filters',
              icon: Icons.filter_list,
              onTap: () async {
                final value = await showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 140, 24, 0),
                  items: [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    ...db.sensorTypes.map(
                      (type) => PopupMenuItem(
                        value: type.id,
                        child: Text(type.name),
                      ),
                    ),
                  ],
                );
                if (value != null) setState(() => _typeFilter = value);
              },
            ),
            _headerButton(
              label: 'Export',
              icon: Icons.upload_outlined,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export started')),
                );
              },
            ),
            _headerButton(
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
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF0f729c) : const Color(0xFFe6eff3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary ? const Color(0xFF0f729c) : const Color(0xFFc8d6dd),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 19,
                color: primary ? Colors.white : const Color(0xFF18313f)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : const Color(0xFF18313f),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    DatabaseProvider db,
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
              connectedDevice: deviceName,
              channel: _channelFor(globalIndex < 0 ? index : globalIndex),
              unit: _unitForType(type),
              location: siteName,
              icon: _iconForType(type),
              status: isActive ? 'active' : 'inactive',
              onEdit: () => _showSensorModal(sensor: sensor),
              onPower: () => _togglePower(sensor.id),
              onDelete: () => db.delete('sensors', sensor.id),
            );
          },
        );
      },
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String sensorType;
  final String serial;
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFc8d6dc)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: const Color(0xFFdfe3ef),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF5673d8), size: 26),
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
                      style: const TextStyle(
                        fontSize: 30 > 22 ? 30 - 8 : 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF152733),
                      ),
                    ),
                    Text(
                      sensorType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF60717c),
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
          _meta('Serial Number', serial),
          const SizedBox(height: 8),
          _meta('Connected Device', connectedDevice),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _meta('Channel', '$channel')),
              const SizedBox(width: 10),
              Expanded(child: _meta('Unit', unit)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFe9f0f4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: Color(0xFF2f83ad)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF2c404d), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _iconButton(icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 8),
              _iconButton(icon: Icons.power_settings_new, onTap: onPower),
              const SizedBox(width: 8),
              _iconButton(
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

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF60717c),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF152733),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF2f4654),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFe6eff3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFc8d6dd)),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}
