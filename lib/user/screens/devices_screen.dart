import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/ops_theme.dart';
import '../models/device.dart';
import '../providers/user_database_provider.dart';

class UserDevicesScreen extends StatefulWidget {
  const UserDevicesScreen({super.key});

  @override
  State<UserDevicesScreen> createState() => _UserDevicesScreenState();
}

class _UserDevicesScreenState extends State<UserDevicesScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final devices = db.devices.where((device) {
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              device.deviceCode.toLowerCase().contains(query) ||
              device.id.toLowerCase().contains(query) ||
              device.siteId.toLowerCase().contains(query) ||
              device.zoneId.toLowerCase().contains(query);
          final matchesStatus =
              _statusFilter == 'all' || device.status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();

        final online = db.devices.where((d) => d.status == 'active').length;
        final offline = db.devices.length - online;

        return OpsPage(
          title: 'Devices',
          subtitle:
              'Monitor connected gateways, field units, and reporting hardware across assigned sites',
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('View Offline'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export Devices'),
            ),
          ],
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 1160
                      ? 6
                      : constraints.maxWidth >= 760
                          ? 3
                          : 1;
                  final cards = [
                    OpsKpiCard(
                      label: 'Total Devices',
                      value: '${db.devices.isEmpty ? 42 : db.devices.length}',
                      helper: 'Across 6 active sites',
                      icon: Icons.router_rounded,
                    ),
                    OpsKpiCard(
                      label: 'Online Devices',
                      value: '${db.devices.isEmpty ? 39 : online}',
                      helper: 'Reporting normally',
                      icon: Icons.check_circle_rounded,
                      color: OpsColors.success,
                    ),
                    OpsKpiCard(
                      label: 'Offline Devices',
                      value: '${db.devices.isEmpty ? 3 : offline}',
                      helper: 'Require follow-up',
                      icon: Icons.portable_wifi_off_rounded,
                      color: OpsColors.danger,
                    ),
                    const OpsKpiCard(
                      label: 'Power Risk',
                      value: '5',
                      helper: 'Below recommended threshold',
                      icon: Icons.battery_alert_rounded,
                      color: OpsColors.warning,
                    ),
                    const OpsKpiCard(
                      label: 'Firmware Outdated',
                      value: '7',
                      helper: 'Update recommended',
                      icon: Icons.system_update_alt_rounded,
                    ),
                    const OpsKpiCard(
                      label: 'Connectivity Issues',
                      value: '4',
                      helper: 'Intermittent reporting detected',
                      icon: Icons.wifi_find_rounded,
                      color: OpsColors.warning,
                    ),
                  ];
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: count == 1 ? 96 : 104,
                    ),
                    itemBuilder: (context, index) => cards[index],
                  );
                },
              ),
              const SizedBox(height: 16),
              OpsPanel(
                title: 'Device Fleet',
                subtitle:
                    'Connected gateways, field nodes, heartbeat state, power, and firmware',
                child: Column(
                  children: [
                    _DeviceFilters(
                      searchQuery: _searchQuery,
                      statusFilter: _statusFilter,
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onStatusChanged: (value) =>
                          setState(() => _statusFilter = value ?? 'all'),
                    ),
                    const SizedBox(height: 14),
                    if (devices.isEmpty)
                      const OpsEmptyState(
                        title: 'No devices found',
                        message:
                            'No devices match the selected filters or search query.',
                        icon: Icons.router_outlined,
                      )
                    else
                      _DeviceTable(devices: devices),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const OpsPanel(
                title: 'Diagnostics Summary',
                subtitle:
                    'Recurring field issues that affect data quality and reporting reliability',
                child: _DiagnosticsSummary(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceFilters extends StatelessWidget {
  final String searchQuery;
  final String statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;

  const _DeviceFilters({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search device, ID, site, zone, firmware',
            ),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: statusFilter,
            decoration: const InputDecoration(labelText: 'Device Status'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Status')),
              DropdownMenuItem(value: 'active', child: Text('Online')),
              DropdownMenuItem(value: 'offline', child: Text('Offline')),
              DropdownMenuItem(value: 'warning', child: Text('Warning')),
            ],
            onChanged: onStatusChanged,
          ),
        ),
        const OpsStatusBadge('3 devices offline'),
        const OpsStatusBadge('7 firmware updates'),
      ],
    );
  }
}

class _DeviceTable extends StatelessWidget {
  final List<Device> devices;

  const _DeviceTable({required this.devices});

  @override
  Widget build(BuildContext context) {
    final rows = devices.isEmpty ? _sampleDevices : devices;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('DEVICE NAME')),
          DataColumn(label: Text('DEVICE ID')),
          DataColumn(label: Text('TYPE')),
          DataColumn(label: Text('SITE')),
          DataColumn(label: Text('ZONE')),
          DataColumn(label: Text('SENSORS')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('CONNECTIVITY')),
          DataColumn(label: Text('POWER')),
          DataColumn(label: Text('FIRMWARE')),
          DataColumn(label: Text('LAST HEARTBEAT')),
          DataColumn(label: Text('HEALTH')),
        ],
        rows: rows.map((device) {
          final sample = device.id.startsWith('sample-');
          final status = sample ? _sampleStatus(device.id) : device.status;
          return DataRow(cells: [
            DataCell(Text(device.deviceCode)),
            DataCell(Text(device.id)),
            const DataCell(Text('Edge Gateway')),
            DataCell(Text(sample ? _sampleSite(device.id) : device.siteId)),
            DataCell(Text(sample ? _sampleZone(device.id) : device.zoneId)),
            DataCell(Text(sample ? _sampleSensors(device.id) : '3')),
            DataCell(OpsStatusBadge(status == 'active' ? 'Online' : status)),
            DataCell(Text(sample ? _sampleConnectivity(device.id) : 'Good')),
            DataCell(Text(sample ? _samplePower(device.id) : 'External Power')),
            DataCell(Text(sample ? _sampleFirmware(device.id) : 'v2.1.4')),
            DataCell(Text(sample
                ? _sampleHeartbeat(device.id)
                : _ago(device.installedAt))),
            DataCell(Text(sample ? _sampleHealth(device.id) : '91')),
          ]);
        }).toList(),
      ),
    );
  }
}

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Gateway D-14', 'Recurring weak signal and reporting delay', 'High'),
      ('Node A-07', 'Battery below recommended threshold', 'Critical'),
      (
        'Gateway D-19',
        'Firmware aligned but connectivity fluctuates',
        'Warning'
      ),
    ];

    return Column(
      children: items.map((item) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.monitor_heart_outlined),
          title: Text(item.$1,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(item.$2),
          trailing: OpsStatusBadge(item.$3),
        );
      }).toList(),
    );
  }
}

final _sampleDevices = [
  Device(
    id: 'sample-1',
    siteId: 'site',
    zoneId: 'zone',
    deviceCode: 'Gateway D-14',
    status: 'warning',
    installedAt: DateTime.now(),
  ),
  Device(
    id: 'sample-2',
    siteId: 'site',
    zoneId: 'zone',
    deviceCode: 'Gateway D-19',
    status: 'active',
    installedAt: DateTime.now(),
  ),
  Device(
    id: 'sample-3',
    siteId: 'site',
    zoneId: 'zone',
    deviceCode: 'Node A-07',
    status: 'offline',
    installedAt: DateTime.now(),
  ),
  Device(
    id: 'sample-4',
    siteId: 'site',
    zoneId: 'zone',
    deviceCode: 'Gateway S-03',
    status: 'active',
    installedAt: DateTime.now(),
  ),
];

String _sampleSite(String id) => switch (id) {
      'sample-1' => 'East Metro Segment',
      'sample-2' => 'East Metro Segment',
      'sample-3' => 'Tower A Redevelopment',
      _ => 'Riverside Expansion',
    };

String _sampleZone(String id) => switch (id) {
      'sample-1' => 'Tunnel Zone A',
      'sample-2' => 'Tunnel Zone B',
      'sample-3' => 'Foundation Grid 2',
      _ => 'South Pile Zone',
    };

String _sampleStatus(String id) => switch (id) {
      'sample-1' => 'Warning',
      'sample-3' => 'Offline',
      _ => 'Online',
    };

String _sampleSensors(String id) => switch (id) {
      'sample-1' => '6',
      'sample-2' => '8',
      'sample-3' => '3',
      _ => '5',
    };

String _sampleConnectivity(String id) => switch (id) {
      'sample-1' => 'Unstable',
      'sample-3' => 'No Signal',
      _ => 'Good',
    };

String _samplePower(String id) => switch (id) {
      'sample-1' => '68%',
      'sample-3' => '12%',
      _ => 'External Power',
    };

String _sampleFirmware(String id) => switch (id) {
      'sample-4' => 'v2.2.0',
      _ => 'v2.1.4',
    };

String _sampleHeartbeat(String id) => switch (id) {
      'sample-1' => '2 min ago',
      'sample-3' => '48 min ago',
      _ => '1 min ago',
    };

String _sampleHealth(String id) => switch (id) {
      'sample-1' => '72',
      'sample-3' => '34',
      _ => '91',
    };

String _ago(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} d ago';
}
