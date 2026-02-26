import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/models/threshold_rule.dart';
import '../providers/super_admin_database_provider.dart';
import '../api/analytics_live_api.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedSensorId;
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
  
  final List<FlSpot> _liveData = [];
  int _dataPointIndex = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startLiveDataFetch();
  }

  void _startLiveDataFetch() {
    _subscription = AnalyticsLiveApi.connectToLiveStream().listen((event) {
      if (mounted && !_paused) {
        setState(() {
          final value = event.x / 1000000000000;
          _liveData.add(FlSpot(_dataPointIndex.toDouble(), value));
          _dataPointIndex++;
          if (_liveData.length > 40) {
            _liveData.removeAt(0);
            for (int i = 0; i < _liveData.length; i++) {
              _liveData[i] = FlSpot(i.toDouble(), _liveData[i].y);
            }
            _dataPointIndex = _liveData.length;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
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

        final selected =
            filteredSensors.where((s) => s.id == _selectedSensorId).firstOrNull;

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
                        title: 'Sensor',
                        child: _dropdown(
                          value: _selectedSensorId,
                          hint: 'Select a sensor',
                          items: filteredSensors
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.serialNumber),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedSensorId = value),
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
                                'Real-Time Data Visualization',
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
                                'Real-Time Data Visualization',
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
                          _liveData.isNotEmpty ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: _liveData.isNotEmpty ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _liveData.isNotEmpty ? 'Receiving Data' : 'Waiting for data...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _liveData.isNotEmpty ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Data points: ${_liveData.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F6573),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildThresholdLegend(graphThresholds),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 400,
                      child: _liveData.isEmpty
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
                                minY: _liveData.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5,
                                maxY: _liveData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) =>
                                      const FlLine(color: Color(0xFFD2DBE0)),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    left: BorderSide(
                                        color: Colors.blueGrey.shade200),
                                    bottom: BorderSide(
                                        color: Colors.blueGrey.shade200),
                                    top: BorderSide.none,
                                    right: BorderSide.none,
                                  ),
                                ),
                                titlesData: const FlTitlesData(
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _liveData,
                                    isCurved: true,
                                    color: const Color(0xFF0f8f92),
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                              ),
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
    DatabaseProvider db,
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

  Widget _buildThresholdLegend(List<ThresholdRule> thresholds) {
    Widget item(String label, Color color, double value, String sound) {
      return Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          '$label ${value.toStringAsFixed(1)}°  |  $sound',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Wrap(
      children: [
        ...thresholds.map(
          (threshold) => item(
            threshold.label,
            threshold.color,
            threshold.value,
            threshold.sound,
          ),
        ),
      ],
    );
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
}
