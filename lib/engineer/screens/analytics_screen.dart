import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/engineer_database_provider.dart';

class EngineerAnalyticsScreen extends StatefulWidget {
  const EngineerAnalyticsScreen({super.key});

  @override
  State<EngineerAnalyticsScreen> createState() =>
      _EngineerAnalyticsScreenState();
}

class _EngineerAnalyticsScreenState extends State<EngineerAnalyticsScreen> {
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
  int _thresholdSeed = 4;
  final List<_ThresholdConfig> _thresholds = [
    const _ThresholdConfig(
      id: 'warning',
      label: 'Warning',
      value: 2.8,
      sound: 'Soft Chime',
      color: Color(0xFFD39A00),
    ),
    const _ThresholdConfig(
      id: 'critical',
      label: 'Critical',
      value: 4.0,
      sound: 'Siren',
      color: Color(0xFFE54C4C),
    ),
    const _ThresholdConfig(
      id: 'emergency',
      label: 'Emergency',
      value: 5.2,
      sound: 'Emergency Bell',
      color: Color(0xFF7A4FD6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<EngineerDatabaseProvider>(
      builder: (context, db, child) {
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
          final status = _levelForReading(s.lastReading);

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

                  final selectorCards = Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _selectCard(
                        context,
                        title: 'Sensor',
                        child: _dropdown(
                          value: _selectedSensorId,
                          hint: 'Select a sensor',
                          width: 210,
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
                        title: 'Compare',
                        child: _dropdown(
                          value: _compareMode,
                          hint: 'No Comparison',
                          width: 210,
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
                        title: 'Range',
                        child: _dropdown(
                          value: _range,
                          hint: 'Last 24 Hours',
                          width: 210,
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
                width: double.infinity,                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFC8D6DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Real-Time Data Visualization',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF132733),
                          ),
                        ),
                        const Spacer(),
                        Container(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildThresholdLegend(),
                    const SizedBox(height: 10),
                    _buildThresholdManager(context),
                    const SizedBox(height: 10),
                    if (selected == null)
                      const SizedBox(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insert_chart_outlined,
                                  size: 64, color: Color(0xFF93A6B2)),
                              SizedBox(height: 12),
                              Text(
                                'Select a sensor to view analytics',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4A6270),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Use the filters above to find sensors, then select one to visualize its data',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF657C89),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sensor: ${selected.serialNumber}  |  Last reading: ${selected.lastReading.toStringAsFixed(2)}°',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4F6573),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 400,
                              child: LineChart(
                                LineChartData(
                                  minY: -3,
                                  maxY: 6,
                                  extraLinesData:
                                      ExtraLinesData(
                                    horizontalLines: _sortedThresholds
                                        .map(
                                          (threshold) => HorizontalLine(
                                            y: threshold.value,
                                            color: threshold.color,
                                            strokeWidth: 1.8,
                                            dashArray: const [6, 4],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
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
                                      spots: List.generate(40, (i) {
                                        final base = selected.lastReading;
                                        final noise =
                                            (Random(i + 21).nextDouble() -
                                                    0.5) *
                                                (_paused ? 0.2 : 1.3);
                                        return FlSpot(
                                            i.toDouble(), base + noise);
                                      }),
                                      isCurved: true,
                                      color: const Color(0xFF0f8f92),
                                      barWidth: 2.5,
                                      dotData: const FlDotData(show: false),
                                    ),
                                    if (_compareMode != 'none')
                                      LineChartBarData(
                                        spots: List.generate(40, (i) {
                                          final offset = _compareMode == 'both'
                                              ? 1.4
                                              : 0.9;
                                          final noise =
                                              (Random(i + 77).nextDouble() -
                                                      0.5) *
                                                  1.1;
                                          return FlSpot(
                                              i.toDouble(),
                                              selected.lastReading +
                                                  offset +
                                                  noise);
                                        }),
                                        isCurved: true,
                                        color: const Color(0xFF5973D8),
                                        barWidth: 2.0,
                                        dotData: const FlDotData(show: false),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                    
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
    EngineerDatabaseProvider db,
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
                  items: _statusFilterItems(),
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

  List<_ThresholdConfig> get _sortedThresholds {
    final sorted = List<_ThresholdConfig>.from(_thresholds)
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted;
  }

  String _levelForReading(double reading) {
    for (final threshold in _sortedThresholds.reversed) {
      if (reading >= threshold.value) return threshold.key;
    }
    return 'normal';
  }

  List<DropdownMenuItem<String>> _statusFilterItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'all', child: Text('All Statuses')),
      const DropdownMenuItem(value: 'normal', child: Text('Normal')),
    ];

    for (final threshold in _sortedThresholds) {
      items.add(
        DropdownMenuItem(
          value: threshold.key,
          child: Text(threshold.label),
        ),
      );
    }
    return items;
  }

  Widget _buildThresholdLegend() {
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
        ..._sortedThresholds.map(
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

  Widget _buildThresholdManager(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E2E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Threshold Rules',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D3340),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showThresholdDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Threshold'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_thresholds.isEmpty)
            const Text(
              'No thresholds configured. Add at least one threshold rule.',
              style: TextStyle(fontSize: 12, color: Color(0xFF607684)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortedThresholds.map((threshold) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: threshold.color.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: threshold.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${threshold.label} ${threshold.value.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A313D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        threshold.sound,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5F7481),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showThresholdDialog(
                          context,
                          existing: threshold,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF305162),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _thresholds.removeWhere((t) => t.id == threshold.id);
                            _syncStatusFilter();
                          });
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFB33A3A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showThresholdDialog(
    BuildContext context, {
    _ThresholdConfig? existing,
  }) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final valueController = TextEditingController(
      text: existing != null ? existing.value.toStringAsFixed(1) : '',
    );
    final soundController = TextEditingController(text: existing?.sound ?? '');
    final colorHexController = TextEditingController(
      text: existing != null ? _toHexColor(existing.color) : '#4C8BF5',
    );

    final presetColors = <String, Color>{
      'Amber': const Color(0xFFD39A00),
      'Red': const Color(0xFFE54C4C),
      'Purple': const Color(0xFF7A4FD6),
      'Blue': const Color(0xFF4C8BF5),
      'Green': const Color(0xFF17A56F),
      'Orange': const Color(0xFFF08A24),
      'Custom': _parseHexColor(colorHexController.text) ??
          (existing?.color ?? const Color(0xFF4C8BF5)),
    };

    String selectedColorName = existing == null
        ? 'Blue'
        : (presetColors.entries
                .firstWhere(
                  (entry) => entry.value.toARGB32() == existing.color.toARGB32(),
                  orElse: () => const MapEntry('Custom', Color(0xFF4C8BF5)),
                )
                .key);

    Color selectedColor = selectedColorName == 'Custom'
        ? (existing?.color ?? const Color(0xFF4C8BF5))
        : presetColors[selectedColorName]!;
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Threshold' : 'Edit Threshold'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label',
                          hintText: 'Example: High Vibration',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Threshold Value (°)',
                          hintText: 'Example: 3.8',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: soundController,
                        decoration: const InputDecoration(
                          labelText: 'Alert Sound',
                          hintText: 'Example: Short Siren',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedColorName,
                        decoration:
                            const InputDecoration(labelText: 'Threshold Color'),
                        items: presetColors.keys
                            .map(
                              (name) => DropdownMenuItem<String>(
                                value: name,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: presetColors[name],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedColorName = value;
                            if (value != 'Custom') {
                              selectedColor = presetColors[value]!;
                              colorHexController.text = _toHexColor(selectedColor);
                            } else {
                              selectedColor = _parseHexColor(
                                    colorHexController.text,
                                  ) ??
                                  selectedColor;
                            }
                          });
                        },
                      ),
                      if (selectedColorName == 'Custom') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: colorHexController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Hex Color',
                            hintText: '#RRGGBB',
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              final parsed = _parseHexColor(value);
                              if (parsed != null) selectedColor = parsed;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Preview:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF49616F),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB33A3A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    final sound = soundController.text.trim();
                    final value = double.tryParse(valueController.text.trim());
                    final customColor = _parseHexColor(colorHexController.text);
                    final resolvedColor = selectedColorName == 'Custom'
                        ? customColor
                        : selectedColor;

                    if (label.isEmpty) {
                      setDialogState(
                        () => errorText = 'Label is required.',
                      );
                      return;
                    }
                    if (value == null) {
                      setDialogState(
                        () => errorText = 'Threshold value must be a number.',
                      );
                      return;
                    }
                    if (sound.isEmpty) {
                      setDialogState(
                        () => errorText = 'Alert sound is required.',
                      );
                      return;
                    }
                    if (resolvedColor == null) {
                      setDialogState(
                        () => errorText =
                            'Color must be valid (example: #FF8800).',
                      );
                      return;
                    }

                    final threshold = _ThresholdConfig(
                      id: existing?.id ?? 'custom_${_thresholdSeed++}',
                      label: label,
                      value: value,
                      sound: sound,
                      color: resolvedColor,
                    );

                    setState(() {
                      if (existing == null) {
                        _thresholds.add(threshold);
                      } else {
                        final index =
                            _thresholds.indexWhere((t) => t.id == existing.id);
                        if (index != -1) _thresholds[index] = threshold;
                      }
                      _syncStatusFilter();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _syncStatusFilter() {
    if (_statusFilter == 'all' || _statusFilter == 'normal') return;
    final stillExists = _thresholds.any((t) => t.key == _statusFilter);
    if (!stillExists) _statusFilter = 'all';
  }

  Color? _parseHexColor(String input) {
    final cleaned = input.trim().replaceAll('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  String _toHexColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
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
    required String title,
    required Widget child,
  }) {
    return Container(
      width: 305,
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
      child: Row(
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
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required double width,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: width,
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

class _ThresholdConfig {
  const _ThresholdConfig({
    required this.id,
    required this.label,
    required this.value,
    required this.sound,
    required this.color,
  });

  final String id;
  final String label;
  final double value;
  final String sound;
  final Color color;

  String get key => label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
