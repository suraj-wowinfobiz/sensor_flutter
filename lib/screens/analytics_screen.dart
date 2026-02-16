import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/database_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, child) {
        final sensors = db.sensors;
        final selected =
            sensors.where((s) => s.id == _selectedSensorId).firstOrNull;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Use filters below to refine analytics')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                          items: sensors
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
                constraints: const BoxConstraints(minHeight: 560),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFC8D6DD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (selected == null)
                      const Expanded(
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
                                  fontSize: 34 > 30 ? 34 - 4 : 30,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            Expanded(
                              child: LineChart(
                                LineChartData(
                                  minY: -3,
                                  maxY: 6,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
