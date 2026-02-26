import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../super_admin/core/theme/custom_theme_tokens.dart';
import '../../super_admin/shared/models/threshold_rule.dart';
import '../providers/user_database_provider.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDatabaseProvider>(
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
        final tokens = Theme.of(context).extension<CustomThemeTokens>()!;

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
                          color: tokens.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Real-time sensor data visualization and comparison',
                        style: TextStyle(
                          fontSize: 15,
                          color: tokens.subheading,
                        ),
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
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Real-Time Data Visualization',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: tokens.heading,
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
                    _buildThresholdLegend(graphThresholds),
                    const SizedBox(height: 10),
                    if (selected == null)
                      SizedBox(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insert_chart_outlined,
                                  size: 64, color: tokens.mutedText),
                              SizedBox(height: 12),
                              Text(
                                'Select a sensor to view analytics',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.heading,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Use the filters above to find sensors, then select one to visualize its data',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: tokens.mutedText,
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
                                extraLinesData: ExtraLinesData(
                                  horizontalLines: graphThresholds
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
                                      FlLine(color: tokens.chartGrid),
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
                                          (Random(i + 21).nextDouble() - 0.5) *
                                              (_paused ? 0.2 : 1.3);
                                      return FlSpot(i.toDouble(), base + noise);
                                    }),
                                    isCurved: true,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  if (_compareMode != 'none')
                                    LineChartBarData(
                                      spots: List.generate(40, (i) {
                                        final offset =
                                            _compareMode == 'both' ? 1.4 : 0.9;
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
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
    UserDatabaseProvider db,
    int filteredCount,
  ) {
    final isCompact = MediaQuery.of(context).size.width < 1180;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter Sensors',
            style: TextStyle(
              fontSize: 28 > 20 ? 20 : 20,
              fontWeight: FontWeight.w700,
              color:
                  isLight ? const Color(0xFF1A303D) : const Color(0xFFD8E8F5),
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
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 10),
          Text(
            'LOCATION HIERARCHY',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color:
                  isLight ? const Color(0xFF5A707E) : const Color(0xFF9FB4C6),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Text(
        'Showing $filteredCount of $total sensors',
        style: TextStyle(
          fontSize: 16,
          color: isLight ? const Color(0xFF48606E) : const Color(0xFF9FB4C6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputFilter({required String label, required Widget child}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isLight ? const Color(0xFF4D6472) : const Color(0xFF9FB4C6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF243E52),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
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
        border: Border.all(color: Theme.of(context).dividerColor),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF1b313d)
                    : const Color(0xFFD8E8F5),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: width,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF243E52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final buttonTextColor =
        isLight ? const Color(0xFF18313f) : const Color(0xFFD7E8F6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFE6EFF3) : const Color(0xFF243E52),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: buttonTextColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: buttonTextColor,
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
