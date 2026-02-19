import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../providers/engineer_database_provider.dart';
import '../widgets/crud_modal.dart';

class EngineerDevicesScreen extends StatefulWidget {
  const EngineerDevicesScreen({super.key});

  @override
  State<EngineerDevicesScreen> createState() => _EngineerDevicesScreenState();
}

class _EngineerDevicesScreenState extends State<EngineerDevicesScreen> {
  String? _editingId;
  String _deviceCode = '';
  String _siteId = '';
  String _zoneId = '';
  String _status = 'active';
  bool _showFilters = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _webhookFilter = 'all';
  String _organizationFilter = 'all';
  String _siteFilter = 'all';
  String _zoneFilter = 'all';
  String _locationFilter = 'all';

  void _showDeviceModal({Device? device}) {
    final db = Provider.of<EngineerDatabaseProvider>(context, listen: false);

    if (device != null) {
      _editingId = device.id;
      _deviceCode = device.deviceCode;
      _siteId = device.siteId;
      _zoneId = device.zoneId;
      _status = device.status;
    } else {
      _editingId = null;
      _deviceCode = '';
      _siteId = db.sites.isNotEmpty ? db.sites.first.id : '';
      _zoneId = db.zones.isNotEmpty ? db.zones.first.id : '';
      _status = 'active';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return EngineerCrudModal(
            title: device == null ? 'Add Device' : 'Edit Device',
            fields: [
              {
                'label': 'Device Code',
                'value': _deviceCode,
                'onChanged': (String value) =>
                    setState(() => _deviceCode = value),
                'keyboardType': TextInputType.text,
              },
              {
                'label': 'Site',
                'type': 'select',
                'value': _siteId,
                'onChanged': (String? value) =>
                    setState(() => _siteId = value ?? _siteId),
                'options': db.sites
                    .map((site) => {'label': site.name, 'value': site.id})
                    .toList(),
              },
              {
                'label': 'Zone',
                'type': 'select',
                'value': _zoneId,
                'onChanged': (String? value) =>
                    setState(() => _zoneId = value ?? _zoneId),
                'options': db.zones
                    .map((zone) => {'label': zone.name, 'value': zone.id})
                    .toList(),
              },
              {
                'label': 'Status',
                'type': 'select',
                'value': _status,
                'onChanged': (String? value) =>
                    setState(() => _status = value ?? _status),
                'options': const [
                  {'label': 'Active', 'value': 'active'},
                  {'label': 'Inactive', 'value': 'inactive'},
                  {'label': 'Maintenance', 'value': 'maintenance'},
                  {'label': 'Retired', 'value': 'retired'},
                ],
              },
            ],
            onSave: () {
              final db =
                  Provider.of<EngineerDatabaseProvider>(context, listen: false);
              if (_editingId == null) {
                db.create('devices', {
                  'device_code': _deviceCode,
                  'site_id': _siteId,
                  'zone_id': _zoneId,
                  'status': _status,
                });
              } else {
                db.update('devices', _editingId!, {
                  'device_code': _deviceCode,
                  'site_id': _siteId,
                  'zone_id': _zoneId,
                  'status': _status,
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

  String _macFor(int index) {
    return '00:1B:44:${(0x10 + index).toRadixString(16).padLeft(2, '0').toUpperCase()}:'
        '${(0x22 + (index * 2)).toRadixString(16).padLeft(2, '0').toUpperCase()}:'
        '${(0xA0 + index).toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  String _serialFor(int index) =>
      'SN202400${index + 1}${String.fromCharCode(65 + index)}';

  String _ipFor(int index) => '192.168.1.${100 + index}';

  String _date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _togglePower(EngineerDatabaseProvider db, Device device) {
    final next = device.status == 'active' ? 'inactive' : 'active';
    db.update('devices', device.id, {
      'device_code': device.deviceCode,
      'site_id': device.siteId,
      'zone_id': device.zoneId,
      'status': next,
    });
  }

  bool _hasWebhook(int index) => index.isEven;

  bool _matchesFilters(EngineerDatabaseProvider db, Device device) {
    final globalIndex = db.devices.indexOf(device);
    final safeIndex = globalIndex < 0 ? 0 : globalIndex;
    final serial = _serialFor(safeIndex).toLowerCase();
    final mac = _macFor(safeIndex).toLowerCase();
    final ip = _ipFor(safeIndex).toLowerCase();
    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      final matchesQuery = device.deviceCode.toLowerCase().contains(query) ||
          serial.contains(query) ||
          mac.contains(query) ||
          ip.contains(query);
      if (!matchesQuery) return false;
    }

    if (_statusFilter != 'all' && device.status != _statusFilter) {
      return false;
    }

    if (_webhookFilter != 'all') {
      final hasWebhook = _hasWebhook(safeIndex);
      if (_webhookFilter == 'configured' && !hasWebhook) return false;
      if (_webhookFilter == 'not_configured' && hasWebhook) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EngineerDatabaseProvider>(
      builder: (context, db, child) {
        final devices =
            db.devices.where((d) => _matchesFilters(db, d)).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (_showFilters) ...[
                const SizedBox(height: 18),
                _buildFiltersPanel(context, devices.length, db.devices.length),
              ],
              const SizedBox(height: 18),
              _buildGrid(context, db, devices),
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
            Text(
              'Device Management',
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
              'Configure and monitor sensor devices',
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
              onTap: () => setState(() => _showFilters = !_showFilters),
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
              onTap: () => _showDeviceModal(),
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

  Widget _buildFiltersPanel(
      BuildContext context, int filteredCount, int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFc8d6dc)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF243946),
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
                    hint: 'Device ID, Serial, MAC, IP...',
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
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'retired', child: Text('Retired')),
                  ],
                  onChanged: (value) =>
                      setState(() => _statusFilter = value ?? 'all'),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  value: _webhookFilter,
                  decoration: _filterFieldDecoration(label: 'Webhook'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(
                        value: 'configured', child: Text('Configured')),
                    DropdownMenuItem(
                        value: 'not_configured', child: Text('Not Configured')),
                  ],
                  onChanged: (value) =>
                      setState(() => _webhookFilter = value ?? 'all'),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFe6eff3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Showing $filteredCount of $totalCount devices',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF324956),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFd9e4ea)),
          const SizedBox(height: 12),
          const Text(
            'LOCATION HIERARCHY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF60717c),
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
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF4F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFc8d6dd)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFc8d6dd)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0f729c), width: 1.4),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, EngineerDatabaseProvider db, List<Device> devices) {
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
          itemCount: devices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final device = devices[index];
            final globalIndex = db.devices.indexOf(device);
            final siteName = db.sites
                .where((s) => s.id == device.siteId)
                .map((s) => s.name)
                .firstOrNull;
            final zoneName = db.zones
                .where((z) => z.id == device.zoneId)
                .map((z) => z.name)
                .firstOrNull;
            final channels =
                db.sensors.where((s) => s.deviceId == device.id).length;
            final location = siteName ?? 'Location not set';

            return _DeviceCard(
              title: device.deviceCode,
              serial: _serialFor(globalIndex < 0 ? index : globalIndex),
              status: device.status,
              mac: _macFor(globalIndex < 0 ? index : globalIndex),
              ip: _ipFor(globalIndex < 0 ? index : globalIndex),
              channels: channels == 0 ? 4 + index : channels,
              lastSeen: _date(device.installedAt),
              location: location,
              zone: zoneName ?? 'Unknown',
              onEdit: () => _showDeviceModal(device: device),
              onPower: () => _togglePower(db, device),
              onDelete: () => db.delete('devices', device.id),
            );
          },
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String title;
  final String serial;
  final String status;
  final String mac;
  final String ip;
  final int channels;
  final String lastSeen;
  final String location;
  final String zone;
  final VoidCallback onEdit;
  final VoidCallback onPower;
  final VoidCallback onDelete;

  const _DeviceCard({
    required this.title,
    required this.serial,
    required this.status,
    required this.mac,
    required this.ip,
    required this.channels,
    required this.lastSeen,
    required this.location,
    required this.zone,
    required this.onEdit,
    required this.onPower,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final isOffline = status == 'inactive' || status == 'retired';
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
                  color: const Color(0xFFdbe7ed),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.memory,
                    color: Color(0xFF0f729c), size: 26),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF152733),
                      ),
                    ),
                    Text(
                      serial,
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
          Row(
            children: [
              Expanded(child: _meta('MAC Address', mac)),
              const SizedBox(width: 10),
              Expanded(child: _meta('IP Address', ip)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _meta('Channels', '$channels')),
              const SizedBox(width: 10),
              Expanded(child: _meta('Last Seen', lastSeen)),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi,
                      size: 18,
                      color: isOffline ? Colors.grey : const Color(0xFF0ca15f)),
                  const SizedBox(width: 6),
                  Text(
                    isOffline ? 'Disconnected' : 'WiFi Connected',
                    style: TextStyle(
                      fontSize: 13,
                      color: isOffline
                          ? const Color(0xFF7f8f98)
                          : const Color(0xFF0ca15f),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFe8edf1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFc8d6dd)),
                ),
                child: Text(
                  zone,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF243946),
                  ),
                ),
              ),
            ],
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
