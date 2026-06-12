import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/ops_theme.dart';
import '../models/sensor.dart';
import '../providers/user_database_provider.dart';

class UserSensorsScreen extends StatefulWidget {
  const UserSensorsScreen({super.key});

  @override
  State<UserSensorsScreen> createState() => _UserSensorsScreenState();
}

class _UserSensorsScreenState extends State<UserSensorsScreen> {
  String _searchQuery = '';
  String _stateFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
      builder: (context, db, child) {
        final sensors = db.sensors.where((sensor) {
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              sensor.serialNumber.toLowerCase().contains(query) ||
              sensor.id.toLowerCase().contains(query) ||
              sensor.deviceId.toLowerCase().contains(query);
          final state = _sensorState(sensor.lastReading).toLowerCase();
          final matchesState = _stateFilter == 'all' ||
              state.toLowerCase() == _stateFilter.toLowerCase();
          return matchesSearch && matchesState;
        }).toList();

        final reporting = db.sensors.where((s) => s.lastReading < 3).length;
        final warning = db.sensors.where((s) => s.lastReading >= 3).length;

        return OpsPage(
          title: 'Sensors',
          subtitle:
              'Track sensor inventory, latest readings, threshold status, and field health across monitored sites',
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Threshold Breaches'),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export Sensors'),
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
                      label: 'Total Sensors',
                      value: '${db.sensors.isEmpty ? 128 : db.sensors.length}',
                      helper: 'Across all assigned sites',
                      icon: Icons.sensors_rounded,
                    ),
                    OpsKpiCard(
                      label: 'Reporting Normally',
                      value: '${db.sensors.isEmpty ? 112 : reporting}',
                      helper: 'Within expected interval',
                      icon: Icons.check_circle_rounded,
                      color: OpsColors.success,
                    ),
                    OpsKpiCard(
                      label: 'Warning State',
                      value: '${db.sensors.isEmpty ? 11 : warning}',
                      helper: 'Monitoring required',
                      icon: Icons.warning_amber_rounded,
                      color: OpsColors.warning,
                    ),
                    const OpsKpiCard(
                      label: 'Offline / No Data',
                      value: '5',
                      helper: 'No recent readings',
                      icon: Icons.signal_wifi_off_rounded,
                      color: OpsColors.danger,
                    ),
                    const OpsKpiCard(
                      label: 'Breaches Today',
                      value: '14',
                      helper: 'Warning and critical combined',
                      icon: Icons.stacked_line_chart_rounded,
                      color: OpsColors.warning,
                    ),
                    const OpsKpiCard(
                      label: 'Calibration Due',
                      value: '8',
                      helper: 'Review accuracy schedule',
                      icon: Icons.build_circle_outlined,
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
                title: 'Sensor Inventory',
                subtitle:
                    'Latest reading, threshold state, linked device, calibration, and health score',
                child: Column(
                  children: [
                    _SensorFilters(
                      searchQuery: _searchQuery,
                      stateFilter: _stateFilter,
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onStateChanged: (value) =>
                          setState(() => _stateFilter = value ?? 'all'),
                    ),
                    const SizedBox(height: 14),
                    _SensorTable(
                        sensors: sensors.isEmpty ? _sampleSensors : sensors),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const OpsPanel(
                title: 'Threshold & Calibration Review',
                subtitle:
                    'Sensors with repeated breaches, drift, noisy readings, or upcoming calibration',
                child: _ThresholdReview(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorFilters extends StatelessWidget {
  final String searchQuery;
  final String stateFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStateChanged;

  const _SensorFilters({
    required this.searchQuery,
    required this.stateFilter,
    required this.onSearchChanged,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search sensor, ID, type, site, zone, linked device',
            ),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: stateFilter,
            decoration: const InputDecoration(labelText: 'Threshold State'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All States')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'warning', child: Text('Warning')),
              DropdownMenuItem(value: 'critical', child: Text('Critical')),
            ],
            onChanged: onStateChanged,
          ),
        ),
        const OpsStatusBadge('11 sensors outside range'),
        const OpsStatusBadge('8 calibration due'),
      ],
    );
  }
}

class _SensorTable extends StatelessWidget {
  final List<Sensor> sensors;

  const _SensorTable({required this.sensors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('SENSOR NAME')),
          DataColumn(label: Text('SENSOR ID')),
          DataColumn(label: Text('TYPE')),
          DataColumn(label: Text('SITE')),
          DataColumn(label: Text('ZONE')),
          DataColumn(label: Text('LINKED DEVICE')),
          DataColumn(label: Text('LATEST READING')),
          DataColumn(label: Text('UNIT')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('THRESHOLD')),
          DataColumn(label: Text('CALIBRATION')),
          DataColumn(label: Text('HEALTH')),
        ],
        rows: sensors.map((sensor) {
          final sample = sensor.id.startsWith('sample-');
          final state = _sensorState(sensor.lastReading);
          return DataRow(cells: [
            DataCell(
                Text(sample ? _sampleName(sensor.id) : sensor.serialNumber)),
            DataCell(Text(sensor.id)),
            DataCell(Text(sample ? _sampleType(sensor.id) : 'Telemetry')),
            DataCell(Text(sample ? _sampleSite(sensor.id) : 'Project Alpha')),
            DataCell(Text(sample ? _sampleZone(sensor.id) : 'Field Zone')),
            DataCell(Text(sample ? _sampleDevice(sensor.id) : sensor.deviceId)),
            DataCell(Text(sample
                ? _sampleReading(sensor.id)
                : sensor.lastReading.toStringAsFixed(2))),
            DataCell(Text(sample ? _sampleUnit(sensor.id) : 'unit')),
            DataCell(OpsStatusBadge(state)),
            DataCell(Text(state == 'Normal' ? 'Within Range' : 'Review')),
            DataCell(Text(sample ? _sampleCalibration(sensor.id) : '24 days')),
            DataCell(Text(sample ? _sampleHealth(sensor.id) : '90')),
          ]);
        }).toList(),
      ),
    );
  }
}

class _ThresholdReview extends StatelessWidget {
  const _ThresholdReview();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Vibration Sensor V-118', '7 breaches', 'Rising variability', 'High'),
      (
        'Tilt Sensor T-301',
        'Missing reports',
        'Calibration due in 7 days',
        'Critical'
      ),
      ('Temperature Sensor TMP-77', '4 breaches', 'Elevated trend', 'Warning'),
    ];

    return Column(
      children: rows.map((row) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sensors_rounded),
          title:
              Text(row.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${row.$2} - ${row.$3}'),
          trailing: OpsStatusBadge(row.$4),
        );
      }).toList(),
    );
  }
}

String _sensorState(double reading) {
  if (reading >= 4) return 'Critical';
  if (reading >= 3) return 'Warning';
  return 'Normal';
}

final _sampleSensors = [
  Sensor(
    id: 'sample-1',
    deviceId: 'Gateway D-14',
    sensorTypeId: 'Tilt',
    serialNumber: 'Tilt Sensor T-204',
    installedAt: DateTime.now(),
    lastReading: .82,
  ),
  Sensor(
    id: 'sample-2',
    deviceId: 'Gateway D-14',
    sensorTypeId: 'Vibration',
    serialNumber: 'Vibration Sensor V-118',
    installedAt: DateTime.now(),
    lastReading: 3.24,
  ),
  Sensor(
    id: 'sample-3',
    deviceId: 'Node C-11',
    sensorTypeId: 'Temperature',
    serialNumber: 'Temperature Sensor TMP-77',
    installedAt: DateTime.now(),
    lastReading: 3.41,
  ),
  Sensor(
    id: 'sample-4',
    deviceId: 'Gateway S-03',
    sensorTypeId: 'Strain',
    serialNumber: 'Strain Sensor S-091',
    installedAt: DateTime.now(),
    lastReading: .14,
  ),
];

String _sampleName(String id) => switch (id) {
      'sample-1' => 'Tilt Sensor T-204',
      'sample-2' => 'Vibration Sensor V-118',
      'sample-3' => 'Temperature Sensor TMP-77',
      _ => 'Strain Sensor S-091',
    };

String _sampleType(String id) => switch (id) {
      'sample-1' => 'Tilt',
      'sample-2' => 'Vibration',
      'sample-3' => 'Temperature',
      _ => 'Strain',
    };

String _sampleSite(String id) => switch (id) {
      'sample-1' => 'Tower A Redevelopment',
      'sample-2' => 'East Metro Segment',
      'sample-3' => 'Industrial Block C',
      _ => 'Riverside Expansion',
    };

String _sampleZone(String id) => switch (id) {
      'sample-1' => 'Core Wall Zone 3',
      'sample-2' => 'Tunnel Zone A',
      'sample-3' => 'Crane Pad South',
      _ => 'South Pile Zone',
    };

String _sampleDevice(String id) => switch (id) {
      'sample-3' => 'Node C-11',
      'sample-4' => 'Gateway S-03',
      _ => 'Gateway D-14',
    };

String _sampleReading(String id) => switch (id) {
      'sample-1' => '0.82',
      'sample-2' => '1.24',
      'sample-3' => '34.1',
      _ => '0.014',
    };

String _sampleUnit(String id) => switch (id) {
      'sample-1' => 'deg',
      'sample-2' => 'mm/s',
      'sample-3' => 'C',
      _ => 'mm/m',
    };

String _sampleCalibration(String id) => switch (id) {
      'sample-2' => '11 days',
      'sample-3' => '37 days',
      _ => '24 days',
    };

String _sampleHealth(String id) => switch (id) {
      'sample-2' => '68',
      'sample-3' => '63',
      _ => '92',
    };
