import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sensor.dart';
import '../providers/engineer_database_provider.dart';

class EngineerSensorsScreen extends StatefulWidget {
  const EngineerSensorsScreen({super.key});

  @override
  State<EngineerSensorsScreen> createState() => _EngineerSensorsScreenState();
}

class _EngineerSensorsScreenState extends State<EngineerSensorsScreen> {
  String? _editingId;
  String _serialNumber = '';
  String _deviceId = '';
  String _sensorTypeId = '';
  String _sensorCodeInput = '';
  String _macAddress = '';
  String _channelNumber = '1';
  String _organizationId = '';
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

  void _showSensorModal({Sensor? sensor}) {
    final db = Provider.of<EngineerDatabaseProvider>(context, listen: false);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF4e6473) : const Color(0xFF9db7d2);
    final defaultDeviceId = db.devices.isNotEmpty ? db.devices.first.id : '';
    final defaultTypeId =
        db.sensorTypes.isNotEmpty ? db.sensorTypes.first.id : '';
    final defaultOrgId = db.sites.isNotEmpty ? db.sites.first.id : '';

    if (sensor != null) {
      final index = db.sensors.indexOf(sensor);
      _editingId = sensor.id;
      _serialNumber = sensor.serialNumber;
      _deviceId = sensor.deviceId;
      _sensorTypeId = sensor.sensorTypeId;
      _sensorCodeInput = _sensorCodeFor(index < 0 ? 0 : index);
      _macAddress =
          '9E:55:DE:5E:${(56 + (index < 0 ? 0 : index)).toRadixString(16).padLeft(2, '0').toUpperCase()}:18';
      _channelNumber = '${_channelFor(index < 0 ? 0 : index)}';
      _organizationId = defaultOrgId;
    } else {
      _editingId = null;
      _sensorCodeInput =
          'SEN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _serialNumber =
          'SNMLQ${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      _macAddress = '9E:55:DE:5E:56:18';
      _channelNumber = '1';
      _deviceId = defaultDeviceId;
      _sensorTypeId = defaultTypeId;
      _organizationId = defaultOrgId;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sensor Form',
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 740),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                                  style: TextStyle(
                                      fontSize: 14, color: subColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextField(
                              label: 'Sensor ID',
                              value: _sensorCodeInput,
                              onChanged: (v) =>
                                  setState(() => _sensorCodeInput = v),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _dialogTextField(
                              label: 'Serial Number',
                              value: _serialNumber,
                              onChanged: (v) =>
                                  setState(() => _serialNumber = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        label: 'MAC Address',
                        value: _macAddress,
                        onChanged: (v) => setState(() => _macAddress = v),
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: _dialogTextField(
                              label: 'Channel Number',
                              value: _channelNumber,
                              onChanged: (v) =>
                                  setState(() => _channelNumber = v),
                            ),
                          ),
                        ],
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
                        onChanged: (value) =>
                            setState(() => _sensorTypeId = value ?? ''),
                      ),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'Organization',
                        value: _organizationId.isEmpty ? null : _organizationId,
                        hint: 'Select organization',
                        items: db.sites
                            .map((site) => DropdownMenuItem<String>(
                                  value: site.id,
                                  child: Text(site.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _organizationId = value ?? ''),
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
                              onPressed: () {
                                final provider = Provider.of<EngineerDatabaseProvider>(
                                  context,
                                  listen: false,
                                );
                                if (_editingId == null) {
                                  provider.create('sensors', {
                                    'serial_number': _serialNumber.trim(),
                                    'device_id': _deviceId,
                                    'sensor_type_id': _sensorTypeId,
                                  });
                                } else {
                                  provider.update('sensors', _editingId!, {
                                    'serial_number': _serialNumber.trim(),
                                    'device_id': _deviceId,
                                    'sensor_type_id': _sensorTypeId,
                                  });
                                }
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_editingId == null
                                  ? 'Add Sensor'
                                  : 'Save Sensor'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 22),
                            ),
                            child: const Text('Cancel'),
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFFF4F8FA)
                : const Color(0xFF223B4E),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                ? const Color(0xFFF4F8FA)
                : const Color(0xFF223B4E),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
      ],
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

  String _sensorTypeLabel(String id, EngineerDatabaseProvider db) {
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

  bool _matchesFilters(EngineerDatabaseProvider db, Sensor sensor) {
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
    return Consumer<EngineerDatabaseProvider>(
      builder: (context, db, child) {
        final sensors =
            db.sensors.where((s) => _matchesFilters(db, s)).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (_showFilters) ...[
                const SizedBox(height: 18),
                _buildFiltersPanel(
                    context, db, sensors.length, db.sensors.length),
              ],
              const SizedBox(height: 18),
              _isListView
                  ? _buildList(context, db, sensors)
                  : _buildGrid(context, db, sensors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
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
            Text(
              'Configure and monitor sensors',
              style: TextStyle(
                fontSize: 15,
                color:
                    isLight ? const Color(0xFF4e6473) : const Color(0xFF9db7d2),
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
    EngineerDatabaseProvider db,
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
    EngineerDatabaseProvider db,
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

  Widget _buildList(
    BuildContext context,
    EngineerDatabaseProvider db,
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
        final statusColor = status == 'active'
            ? const Color(0xFF0ca15f)
            : const Color(0xFF8397a3);
        final metaLine =
            '${sensor.serialNumber} • $deviceName • ${_channelFor(safeIndex)} • ${_unitForType(type)} • $siteName';

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
                    icon: const Icon(Icons.edit_outlined),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _togglePower(sensor.id),
                    icon: const Icon(Icons.power_settings_new),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => db.delete('sensors', sensor.id),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final statusColor =
        isActive ? const Color(0xFF0ca15f) : const Color(0xFF8397a3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
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
                  color: isLight
                      ? const Color(0xFFdfe3ef)
                      : const Color(0xFF2A3F54),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
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
                        color: isLight
                            ? const Color(0xFF152733)
                            : const Color(0xFFE2EDF8),
                      ),
                    ),
                    Text(
                      sensorType,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight
                            ? const Color(0xFF60717c)
                            : const Color(0xFF9FB4C6),
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
              color:
                  isLight ? const Color(0xFFe9f0f4) : const Color(0xFF233C4F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF2c404d)
                          : const Color(0xFFD3E4F2),
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
                  onTap: onPower),
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
    Color iconColor = const Color(0xFF2f4654),
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
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
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}
