import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/super_admin_backend_provider.dart';
import '../services/generic_sse_service.dart';
import '../shared/models/threshold_rule.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedDeviceId;
  String _compareMode = 'none';
  String _range = '24h';
  bool _paused = false;
  bool _showFilters = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sensorTypeFilter = 'all';
  String _deviceFilter = 'all';
  String _organizationFilter = 'all';
  String _siteFilter = 'all';
  String _zoneFilter = 'all';
  String _locationFilter = 'all';

  final GenericSseService _processedSseService =
      GenericSseService('/api/v1/processing/readings/live');
  final List<FlSpot> _gravityMagnitudeData = [];
  final List<FlSpot> _motionData = [];
  int _dataPointIndex = 0;
  StreamSubscription? _processedSubscription;

  @override
  void initState() {
    super.initState();
    _startProcessedLiveFetch();
  }

  Future<void> _startProcessedLiveFetch() async {
    await _processedSseService.connect();
    _processedSubscription = _processedSseService.stream.listen((payload) {
      if (!mounted || _paused) return;
      final metrics = _extractProcessedMetrics(payload);
      if (metrics == null) return;
      final selectedDeviceId = _selectedDeviceId?.trim();
      if (selectedDeviceId != null && selectedDeviceId.isNotEmpty) {
        final db = context.read<SuperAdminBackendProvider>();
        final sensor =
            db.sensors.where((s) => s.id == metrics.sensorId).firstOrNull;
        if (sensor == null || sensor.deviceId != selectedDeviceId) {
          return;
        }
      }
      setState(() {
        final xIndex = _dataPointIndex.toDouble();
        _gravityMagnitudeData.add(FlSpot(xIndex, metrics.gravityMagnitude));
        _motionData.add(FlSpot(xIndex, metrics.motionDetected ? 1 : 0));
        _dataPointIndex++;
        _trimAndReindexSeries();
      });
    });
  }

  void _trimAndReindexSeries() {
    while (_gravityMagnitudeData.length > 220) {
      _gravityMagnitudeData.removeAt(0);
    }
    while (_motionData.length > 220) {
      _motionData.removeAt(0);
    }
    for (int i = 0; i < _gravityMagnitudeData.length; i++) {
      _gravityMagnitudeData[i] =
          FlSpot(i.toDouble(), _gravityMagnitudeData[i].y);
    }
    for (int i = 0; i < _motionData.length; i++) {
      _motionData[i] = FlSpot(i.toDouble(), _motionData[i].y);
    }
    _dataPointIndex = _gravityMagnitudeData.length;
  }

  Iterable<Map<dynamic, dynamic>> _candidateMaps(
    dynamic payload, {
    int depth = 0,
  }) sync* {
    if (payload == null || depth > 5) return;

    if (payload is Map) {
      yield payload;
      for (final key in const ['body', 'data', 'payload', 'event']) {
        final next = payload[key];
        if (next != null) {
          yield* _candidateMaps(next, depth: depth + 1);
        }
      }
      return;
    }

    if (payload is List) {
      for (final item in payload) {
        yield* _candidateMaps(item, depth: depth + 1);
      }
    }
  }

  _ProcessedMetrics? _extractProcessedMetrics(
    dynamic payload,
  ) {
    for (final map in _candidateMaps(payload)) {
      final rawPayload = map['rawPayload'];
      final rawParams = rawPayload is Map ? rawPayload['parameters'] : null;

      final processedPayload = map['processedPayload'];
      if (processedPayload is Map) {
        final horizontalMagnitude =
            _toDouble(processedPayload['horizontalMagnitude']);

        final x = _toDouble(processedPayload['x']) ??
            (rawParams is Map ? _toDouble(rawParams['x']) : null);
        final y = _toDouble(processedPayload['y']) ??
            (rawParams is Map ? _toDouble(rawParams['y']) : null);
        final z = _toDouble(processedPayload['z']) ??
            (rawParams is Map ? _toDouble(rawParams['z']) : null);

        final computedRms = (x != null && y != null && z != null)
            ? sqrt((x * x) + (y * y) + (z * z))
            : null;
        final gravityMagnitude = horizontalMagnitude ?? computedRms;
        if (gravityMagnitude == null) continue;
        final sensorId = (map['sensorId'] ??
                map['sensor_id'] ??
                (rawPayload is Map ? rawPayload['sensorId'] : null) ??
                (rawPayload is Map ? rawPayload['sensor_id'] : null) ??
                processedPayload['sensorId'] ??
                processedPayload['sensor_id'] ??
                '')
            .toString()
            .trim();
        final motion = _toBoolOrNumberTrue(
              rawParams is Map ? rawParams['motionDetected'] : null,
            ) ??
            _toBoolOrNumberTrue(processedPayload['motionDetected']) ??
            false;

        return _ProcessedMetrics(
          sensorId: sensorId,
          gravityMagnitude: gravityMagnitude,
          motionDetected: motion,
        );
      }

      final x = _toDouble(map['x']);
      final y = _toDouble(map['y']);
      final z = _toDouble(map['z']);
      if (x != null && y != null && z != null) {
        final magnitude = sqrt((x * x) + (y * y) + (z * z));
        final sensorId =
            (map['sensorId'] ?? map['sensor_id'] ?? '').toString().trim();
        return _ProcessedMetrics(
          sensorId: sensorId,
          gravityMagnitude: magnitude,
          motionDetected: false,
        );
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool? _toBoolOrNumberTrue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text == '1' || text == 'true' || text == 'yes') return true;
    if (text == '0' || text == 'false' || text == 'no') return false;
    return null;
  }

  @override
  void dispose() {
    _processedSubscription?.cancel();
    _processedSseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SuperAdminBackendProvider>(
      builder: (context, db, child) {
        final graphThresholds =
            db.thresholdRulesForGraph(ThresholdGraphTarget.analyticsMain);
        final filteredSensors = db.sensors.where((s) {
          final search = _searchQuery.trim().toLowerCase();
          final sensorType = db.sensorTypes
                  .where((t) => t.id == s.sensorTypeId)
                  .map((t) => t.name)
                  .firstOrNull ??
              '';
          final deviceCode = db.devices
                  .where((d) => d.id == s.deviceId)
                  .map((d) => d.deviceCode)
                  .firstOrNull ??
              '';
          final status = _levelForReading(s.lastReading, graphThresholds);

          final matchesSearch = search.isEmpty ||
              s.serialNumber.toLowerCase().contains(search) ||
              sensorType.toLowerCase().contains(search) ||
              deviceCode.toLowerCase().contains(search);

          final matchesStatus =
              _statusFilter == 'all' || status == _statusFilter;
          final matchesType =
              _sensorTypeFilter == 'all' || s.sensorTypeId == _sensorTypeFilter;
          final matchesDevice =
              _deviceFilter == 'all' || s.deviceId == _deviceFilter;

          return matchesSearch && matchesStatus && matchesType && matchesDevice;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF0f202d)
                                  : const Color(0xFFd4e4ef),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Real-time sensor data visualization and comparison',
                        style:
                            TextStyle(fontSize: 15, color: Color(0xFF4e6473)),
                      ),
                    ],
                  ),
                  _headerButton(
                    label: 'Filters',
                    icon: Icons.filter_list,
                    onTap: () => setState(() => _showFilters = !_showFilters),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_showFilters)
                _buildFilterPanel(context, db, filteredSensors.length),
              if (_showFilters) const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final vertical = width < 1150;
                  final selectorCardWidth = width < 540
                      ? width
                      : width < 980
                          ? (width - 12) / 2
                          : 305.0;

                  final selectorCards = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _selectCard(
                        context,
                        width: selectorCardWidth,
                        title: 'Device',
                        child: _dropdown(
                          value: _selectedDeviceId,
                          hint: 'Select a device',
                          items: db.devices
                              .map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.deviceCode),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() {
                            _selectedDeviceId = value;
                            _gravityMagnitudeData.clear();
                            _motionData.clear();
                            _dataPointIndex = 0;
                          }),
                        ),
                      ),
                      _selectCard(
                        context,
                        width: selectorCardWidth,
                        title: 'Compare',
                        child: _dropdown(
                          value: _compareMode,
                          hint: 'No Comparison',
                          items: const [
                            DropdownMenuItem(
                                value: 'none', child: Text('No Comparison')),
                            DropdownMenuItem(
                                value: 'x', child: Text('Compare X Axis')),
                            DropdownMenuItem(
                                value: 'y', child: Text('Compare Y Axis')),
                            DropdownMenuItem(
                                value: 'both', child: Text('Compare Both')),
                          ],
                          onChanged: (value) =>
                              setState(() => _compareMode = value ?? 'none'),
                        ),
                      ),
                      _selectCard(
                        context,
                        width: selectorCardWidth,
                        title: 'Range',
                        child: _dropdown(
                          value: _range,
                          hint: 'Last 24 Hours',
                          items: const [
                            DropdownMenuItem(
                                value: '1h', child: Text('Last 1 Hour')),
                            DropdownMenuItem(
                                value: '6h', child: Text('Last 6 Hours')),
                            DropdownMenuItem(
                                value: '24h', child: Text('Last 24 Hours')),
                            DropdownMenuItem(
                                value: '7d', child: Text('Last 7 Days')),
                          ],
                          onChanged: (value) =>
                              setState(() => _range = value ?? '24h'),
                        ),
                      ),
                    ],
                  );

                  final actionButtons = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _headerButton(
                        label: _paused ? 'Resume' : 'Pause',
                        icon: _paused ? Icons.play_arrow : Icons.pause,
                        onTap: () => setState(() => _paused = !_paused),
                      ),
                      _headerButton(
                        label: 'CSV',
                        icon: Icons.upload_file_outlined,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV export started')),
                        ),
                      ),
                      _headerButton(
                        label: 'Report',
                        icon: Icons.outbox_outlined,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Report generation started')),
                        ),
                      ),
                    ],
                  );

                  if (vertical) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selectorCards,
                        const SizedBox(height: 10),
                        actionButtons
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: selectorCards),
                      const SizedBox(width: 10),
                      actionButtons,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFC8D6DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 420;
                        final badge = Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF9BA7E4).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4C63C5),
                            ),
                          ),
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gravity Magnitude (Processed Live)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF132733),
                                ),
                              ),
                              const SizedBox(height: 8),
                              badge,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Gravity Magnitude (Processed Live)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF132733),
                                ),
                              ),
                            ),
                            badge,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          _gravityMagnitudeData.isNotEmpty
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 12,
                          color: _gravityMagnitudeData.isNotEmpty
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _gravityMagnitudeData.isNotEmpty
                              ? 'Receiving magnitude data'
                              : 'Waiting for data...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _gravityMagnitudeData.isNotEmpty
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Data points: ${_gravityMagnitudeData.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F6573),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 400,
                      child: _gravityMagnitudeData.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('Waiting for live data...'),
                                ],
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                minY: _gravityMagnitudeData
                                        .map((e) => e.y)
                                        .reduce(min) -
                                    0.5,
                                maxY: _gravityMagnitudeData
                                        .map((e) => e.y)
                                        .reduce(max) +
                                    0.5,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 0.2,
                                  verticalInterval: 20,
                                  getDrawingHorizontalLine: (value) {
                                    final nearInteger =
                                        (value - value.round()).abs() < 0.05;
                                    return FlLine(
                                      color: const Color(0xFF111111).withValues(
                                          alpha: nearInteger ? 0.65 : 0.35),
                                      strokeWidth: nearInteger ? 1.1 : 0.7,
                                      dashArray:
                                          nearInteger ? null : const [8, 6],
                                    );
                                  },
                                  getDrawingVerticalLine: (_) => const FlLine(
                                    color: Color(0xFF8A8A8A),
                                    strokeWidth: 0.8,
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: const Border(
                                    left: BorderSide(
                                        color: Color(0xFF111111), width: 1),
                                    bottom: BorderSide(
                                        color: Color(0xFF111111), width: 1),
                                    top: BorderSide(
                                        color: Color(0xFF111111), width: 1),
                                    right: BorderSide(
                                        color: Color(0xFF111111), width: 1),
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    axisNameWidget: const Text(
                                      'Gravity Magnitude',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E2930),
                                      ),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      interval: 0.5,
                                      getTitlesWidget: (value, _) => Text(
                                        value.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF1E2930),
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    axisNameWidget: const Text(
                                      'Processed Samples',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E2930),
                                      ),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 24,
                                      interval: 20,
                                      getTitlesWidget: (value, _) => Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF1E2930),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _gravityMagnitudeData,
                                    isCurved: true,
                                    color: const Color(0xFF111D8A),
                                    barWidth: 2.1,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 280,
                      child: _singleSeriesChart(
                        title: 'Motion Detection (Processed)',
                        yAxisLabel: 'Motion',
                        data: _motionData,
                        lineColor: const Color(0xFFB9382A),
                        fixedMinY: -0.1,
                        fixedMaxY: 1.1,
                        fixedLeftInterval: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    SuperAdminBackendProvider db,
    int filteredCount,
  ) {
    final isCompact = MediaQuery.of(context).size.width < 1180;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filter Sensors',
            style: TextStyle(
              fontSize: 28 > 20 ? 20 : 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A303D),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 280,
                child: _inputFilter(
                  label: 'Search',
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Sensor ID, Serial, MAC...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Status',
                  value: _statusFilter,
                  items: _statusFilterItems(db.thresholdRulesForGraph(
                      ThresholdGraphTarget.analyticsMain)),
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
              ),
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Sensor Type',
                  value: _sensorTypeFilter,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Types'),
                    ),
                    ...db.sensorTypes.map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name),
                      ),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _sensorTypeFilter = v ?? 'all'),
                ),
              ),
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Device',
                  value: _deviceFilter,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Devices'),
                    ),
                    ...db.devices.map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.deviceCode),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _deviceFilter = v ?? 'all'),
                ),
              ),
              if (!isCompact)
                _countText(
                    filteredCount: filteredCount, total: db.sensors.length),
            ],
          ),
          if (isCompact) ...[
            const SizedBox(height: 10),
            _countText(filteredCount: filteredCount, total: db.sensors.length),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFD1DCE2)),
          const SizedBox(height: 10),
          const Text(
            'LOCATION HIERARCHY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A707E),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Organization',
                  value: _organizationFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Organizations'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _organizationFilter = v ?? 'all'),
                ),
              ),
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Site',
                  value: _siteFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Sites')),
                  ],
                  onChanged: (v) => setState(() => _siteFilter = v ?? 'all'),
                ),
              ),
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Zone',
                  value: _zoneFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Zones')),
                  ],
                  onChanged: (v) => setState(() => _zoneFilter = v ?? 'all'),
                ),
              ),
              SizedBox(
                width: isCompact ? 220 : 180,
                child: _selectFilter(
                  label: 'Location',
                  value: _locationFilter,
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Locations'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _locationFilter = v ?? 'all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _levelForReading(double reading, List<ThresholdRule> thresholds) {
    for (final threshold in thresholds.reversed) {
      if (reading >= threshold.value) return threshold.key;
    }
    return 'normal';
  }

  List<DropdownMenuItem<String>> _statusFilterItems(
    List<ThresholdRule> thresholds,
  ) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'all', child: Text('All Statuses')),
      const DropdownMenuItem(value: 'normal', child: Text('Normal')),
    ];

    for (final threshold in thresholds) {
      items.add(
        DropdownMenuItem(
          value: threshold.key,
          child: Text(threshold.label),
        ),
      );
    }
    return items;
  }

  Widget _countText({required int filteredCount, required int total}) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Text(
        'Showing $filteredCount of $total sensors',
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF48606E),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputFilter({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4D6472),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC8D6DD)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _selectFilter({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _inputFilter(
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _selectCard(
    BuildContext context, {
    required double width,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8D6DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 260) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1b313d),
                  ),
                ),
                const SizedBox(height: 10),
                child,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1b313d),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC8D6DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _headerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EFF3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8D6DD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF18313f)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF18313f),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _singleSeriesChart({
    required String title,
    required String yAxisLabel,
    required List<FlSpot> data,
    required Color lineColor,
    double? fixedMinY,
    double? fixedMaxY,
    double? fixedLeftInterval,
  }) {
    final dataOrDefault = data.isEmpty ? [const FlSpot(0, 0)] : data;
    final minY = fixedMinY ?? (dataOrDefault.map((e) => e.y).reduce(min) - 0.3);
    final maxY = fixedMaxY ?? (dataOrDefault.map((e) => e.y).reduce(max) + 0.3);
    final maxX = dataOrDefault.last.x;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5E1E8)),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX <= 0 ? 1 : maxX,
          minY: minY,
          maxY: maxY <= minY ? minY + 1 : maxY,
          gridData: FlGridData(
            show: true,
            horizontalInterval: ((maxY - minY).abs() / 5).clamp(0.1, 10.0),
            verticalInterval: 20,
            getDrawingHorizontalLine: (_) => FlLine(
              color: const Color(0xFF9AAAB4).withValues(alpha: 0.45),
              strokeWidth: 0.7,
            ),
            getDrawingVerticalLine: (_) => FlLine(
              color: const Color(0xFF9AAAB4).withValues(alpha: 0.35),
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xFF12303E), width: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                yAxisLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2930),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: fixedLeftInterval ??
                    ((maxY - minY).abs() / 4).clamp(0.1, 10.0),
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2930),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: dataOrDefault,
              color: lineColor,
              barWidth: 1.8,
              dotData: const FlDotData(show: false),
              isCurved: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessedMetrics {
  const _ProcessedMetrics({
    required this.sensorId,
    required this.gravityMagnitude,
    required this.motionDetected,
  });

  final String sensorId;
  final double gravityMagnitude;
  final bool motionDetected;
}
