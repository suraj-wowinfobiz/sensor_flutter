import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../providers/super_admin_backend_provider.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String? _editingId;
  String _deviceCode = '';
  String _siteId = '';
  String _zoneId = '';
  String _serialNumber = '';
  String _macAddress = '';
  String _ipUrl = '';
  String _channelsCount = '4';
  String _webhookUrl = 'https://api.example.com/webhook';
  String _latitude = '37.7749';
  String _longitude = '-122.4194';
  bool _dataTransmissionEnabled = true;
  bool _showFilters = false;
  bool _isListView = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _webhookFilter = 'all';
  String _organizationFilter = 'all';
  String _siteFilter = 'all';
  String _zoneFilter = 'all';
  String _locationFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
      await db.loadSites();
      for (final site in db.sites) {
        await db.loadZones(site.id);
      }
      await db.loadDevices();
      await db.loadSensors();
    });
  }

  void _showDeviceModal({Device? device}) {
    final db = Provider.of<SuperAdminBackendProvider>(context, listen: false);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subColor =
        isLight ? const Color(0xFF5A6F7D) : const Color(0xFFAEC4D7);
    final defaultSiteId = db.sites.isNotEmpty ? db.sites.first.id : '';
    final defaultZoneId = db.zones.isNotEmpty ? db.zones.first.id : '';

    if (device != null) {
      final index = db.devices.indexOf(device);
      _editingId = device.id;
      _deviceCode = device.deviceCode;
      _siteId = device.siteId;
      _zoneId = device.zoneId;
      _serialNumber = _serialFor(index < 0 ? 0 : index);
      _macAddress = _macFor(index < 0 ? 0 : index);
      _ipUrl = _ipFor(index < 0 ? 0 : index);
      _channelsCount =
          '${db.sensors.where((s) => s.deviceId == device.id).length}';
      if (_channelsCount == '0') _channelsCount = '4';
      _latitude = '37.7749';
      _longitude = '-122.4194';
      _dataTransmissionEnabled = device.status == 'active';
    } else {
      _editingId = null;
      _deviceCode =
          'DEV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _serialNumber =
          'SNMLQ${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      _macAddress = _macFor(db.devices.length);
      _ipUrl = _ipFor(db.devices.length);
      _channelsCount = '4';
      _siteId = defaultSiteId;
      _zoneId = defaultZoneId;
      _latitude = '37.7749';
      _longitude = '-122.4194';
      _dataTransmissionEnabled = true;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Device Form',
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDialogLight = theme.brightness == Brightness.light;
          final cornerRadius = BorderRadius.circular(22);
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
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
                                      ? 'Add New Device'
                                      : 'Edit Device',
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Configure device parameters and network settings',
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
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextField(
                              label: 'Device ID',
                              value: _deviceCode,
                              onChanged: (v) => setState(() => _deviceCode = v),
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
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextField(
                              label: 'MAC Address',
                              value: _macAddress,
                              onChanged: (v) => setState(() => _macAddress = v),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _dialogTextField(
                              label: 'IP Address / URL',
                              value: _ipUrl,
                              onChanged: (v) => setState(() => _ipUrl = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        label: 'Number of Channels',
                        value: _channelsCount,
                        onChanged: (v) => setState(() => _channelsCount = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogTextField(
                        label: 'Webhook URL',
                        value: _webhookUrl,
                        onChanged: (v) => setState(() => _webhookUrl = v),
                      ),
                      const SizedBox(height: 12),
                      _dialogDropdown(
                        label: 'Organization *',
                        value: _siteId.isEmpty ? null : _siteId,
                        hint: 'Select organization',
                        items: db.sites
                            .map((site) => DropdownMenuItem<String>(
                                  value: site.id,
                                  child: Text(site.name),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _siteId = value ?? '';
                          final firstZone = db.zones
                              .where((z) => z.siteId == _siteId)
                              .map((z) => z.id)
                              .firstOrNull;
                          _zoneId = firstZone ?? defaultZoneId;
                        }),
                      ),
                      const SizedBox(height: 18),
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
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Transmission',
                                    style: TextStyle(
                                        fontSize: 30 > 22 ? 22 : 20,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Enable device to send data',
                                    style: TextStyle(color: subColor),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _dataTransmissionEnabled,
                              onChanged: (v) =>
                                  setState(() => _dataTransmissionEnabled = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final provider = Provider.of<SuperAdminBackendProvider>(
                                  context,
                                  listen: false,
                                );
                                final status = _dataTransmissionEnabled
                                    ? 'active'
                                    : 'inactive';
                                try {
                                  if (_editingId == null) {
                                    await provider.create('devices', {
                                      'device_code': _deviceCode.trim(),
                                      'serial_number': _serialNumber.trim(),
                                      'firmware_version': '1.0.0',
                                      'site_id': _siteId,
                                      'zone_id': _zoneId,
                                      'status': status,
                                    });
                                  } else {
                                    await provider.update('devices', _editingId!, {
                                      'device_code': _deviceCode.trim(),
                                      'serial_number': _serialNumber.trim(),
                                      'firmware_version': '1.0.0',
                                      'site_id': _siteId,
                                      'zone_id': _zoneId,
                                      'status': status,
                                    });
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to save device: $e'),
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
                              child: Text(
                                _editingId == null
                                    ? 'Add Device'
                                    : 'Save Device',
                              ),
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

  String _dropdownItemLabel(DropdownMenuItem<String> item) {
    final child = item.child;
    if (child is Text) return child.data ?? (item.value ?? '');
    return item.value ?? '';
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

  Future<void> _togglePower(SuperAdminBackendProvider db, Device device) async {
    final next = device.status == 'active' ? 'inactive' : 'active';
    await db.update('devices', device.id, {
      'device_code': device.deviceCode,
      'serial_number': device.deviceCode,
      'firmware_version': '1.0.0',
      'site_id': device.siteId,
      'zone_id': device.zoneId,
      'status': next,
    });
  }

  bool _hasWebhook(int index) => index.isEven;

  bool _matchesFilters(SuperAdminBackendProvider db, Device device) {
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
    return Consumer<SuperAdminBackendProvider>(
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
              _isListView
                  ? _buildList(context, db, devices)
                  : _buildGrid(context, db, devices),
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
            Text(
              'Configure and monitor sensor devices',
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
              label: 'Filters',
              icon: Icons.filter_list,
              onTap: () => setState(() => _showFilters = !_showFilters),
            ),
            _headerButton(
              label: _isListView ? 'Cards' : 'List',
              icon: _isListView
                  ? Icons.grid_view_rounded
                  : Icons.view_list_rounded,
              onTap: () => setState(() => _isListView = !_isListView),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: primary
              ? const Color(0xFF0f729c)
              : (isLight ? const Color(0xFFe6eff3) : const Color(0xFF243E52)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary
                ? const Color(0xFF0f729c)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 19,
                color: primary
                    ? Colors.white
                    : (isLight
                        ? const Color(0xFF18313f)
                        : const Color(0xFFD7E8F6))),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? Colors.white
                    : (isLight
                        ? const Color(0xFF18313f)
                        : const Color(0xFFD7E8F6)),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
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
            'Filter Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color:
                  isLight ? const Color(0xFF243946) : const Color(0xFFD7E8F6),
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
                  color: isLight
                      ? const Color(0xFFe6eff3)
                      : const Color(0xFF253F52),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Showing $filteredCount of $totalCount devices',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isLight
                        ? const Color(0xFF324956)
                        : const Color(0xFFD7E8F6),
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
              color:
                  isLight ? const Color(0xFF60717c) : const Color(0xFFBBD0E0),
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
      fillColor: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF4F8FA)
          : const Color(0xFF1E3A52),
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
      BuildContext context, SuperAdminBackendProvider db, List<Device> devices) {
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
              onDelete: () async {
                try {
                  await db.delete('devices', device.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete device: $e')),
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
      BuildContext context, SuperAdminBackendProvider db, List<Device> devices) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = devices[index];
        final globalIndex = db.devices.indexOf(device);
        final safeIndex = globalIndex < 0 ? index : globalIndex;
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
        final statusColor = device.status == 'active'
            ? const Color(0xFF0ca15f)
            : const Color(0xFF8397a3);
        final metaLine =
            '${_macFor(safeIndex)} • ${_ipFor(safeIndex)} • ${channels == 0 ? 4 + index : channels} • ${_date(device.installedAt)} • $location • ${zoneName ?? 'Unknown'}';

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
                  Icon(Icons.memory,
                      size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${device.deviceCode} • ${_serialFor(safeIndex)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF152733)
                            : const Color(0xFFD7E8F6),
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
                      device.status,
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
                    onPressed: () => _showDeviceModal(device: device),
                    icon: const Icon(Icons.edit_outlined),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () => _togglePower(db, device),
                    icon: const Icon(Icons.power_settings_new),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () async {
                      try {
                        await db.delete('devices', device.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete device: $e'),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isActive = status == 'active';
    final isOffline = status == 'inactive' || status == 'retired';
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
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.18),
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
                      ? const Color(0xFFdbe7ed)
                      : const Color(0xFF2B4659),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.memory,
                    color: Theme.of(context).colorScheme.primary, size: 26),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isLight
                            ? const Color(0xFF152733)
                            : const Color(0xFFD7E8F6),
                      ),
                    ),
                    Text(
                      serial,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLight
                            ? const Color(0xFF60717c)
                            : const Color(0xFFBBD0E0),
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
              Expanded(child: _meta(context, 'MAC Address', mac)),
              const SizedBox(width: 10),
              Expanded(child: _meta(context, 'IP Address', ip)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _meta(context, 'Channels', '$channels')),
              const SizedBox(width: 10),
              Expanded(child: _meta(context, 'Last Seen', lastSeen)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xFFe9f0f4) : const Color(0xFF253F52),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF2c404d)
                          : const Color(0xFFD7E8F6),
                      fontSize: 13,
                    ),
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
                  color: isLight
                      ? const Color(0xFFe8edf1)
                      : const Color(0xFF253F52),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  zone,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLight
                        ? const Color(0xFF243946)
                        : const Color(0xFFD7E8F6),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _iconButton(context, icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 8),
              _iconButton(context,
                  icon: Icons.power_settings_new, onTap: onPower),
              const SizedBox(width: 8),
              _iconButton(
                context,
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
            color: isLight ? const Color(0xFF60717c) : const Color(0xFFBBD0E0),
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
            color: isLight ? const Color(0xFF152733) : const Color(0xFFD7E8F6),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _iconButton(
    BuildContext context, {
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
        child: Icon(
          icon,
          size: 20,
          color: iconColor == const Color(0xFF2f4654) && !isLight
              ? const Color(0xFFD7E8F6)
              : iconColor,
        ),
      ),
    );
  }
}
