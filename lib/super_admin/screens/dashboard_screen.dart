import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/threshold_rule.dart';
import '../providers/super_admin_api_riverpod_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../services/analytics_sse_service.dart';
import '../services/generic_sse_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool embeddedScroll;

  const DashboardScreen({super.key, this.embeddedScroll = false});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final AnalyticsSseService _analyticsSseService = AnalyticsSseService();
  final GenericSseService _rawSseService =
      GenericSseService('/api/v1/ingestion/readings/live');
  final GenericSseService _processedSseService =
      GenericSseService('/api/v1/processing/readings/live');
  final List<FlSpot> _liveData = [];
  final List<FlSpot> _rawXData = [];
  final List<FlSpot> _rawYData = [];
  final List<FlSpot> _rawZData = [];
  final List<FlSpot> _processedXData = [];
  final List<FlSpot> _processedYData = [];
  final List<FlSpot> _processedZData = [];
  final List<FlSpot> _analyzedXData = [];
  final List<FlSpot> _analyzedYData = [];
  final List<FlSpot> _analyzedZData = [];
  int _dataPointIndex = 0;
  int _rawIndex = 0;
  int _processedIndex = 0;
  int _analyzedIndex = 0;
  StreamSubscription? _analyticsSubscription;
  StreamSubscription? _rawSubscription;
  StreamSubscription? _processedSubscription;

  @override
  void initState() {
    super.initState();
    _connectToStreams();
  }

  void _connectToStreams() async {
    await _analyticsSseService.connect();
    _analyticsSubscription = _analyticsSseService.stream.listen((data) {
      if (!mounted) return;
      final metrics = _extractAnalyzedMetricsFromPayload(data);
      if (metrics == null) return;
      setState(() {
        _appendAnalyzedPoint(_analyzedXData, metrics.$1);
        _appendAnalyzedPoint(_analyzedYData, metrics.$2);
        _appendAnalyzedPoint(_analyzedZData, metrics.$3);
        _analyzedIndex++;
        _trimAndReindexAnalyzedSeries();

        _liveData.add(FlSpot(_dataPointIndex.toDouble(), metrics.$4));
        _dataPointIndex++;
        _trimAndReindexRealtime();
      });
    });

    await _rawSseService.connect();
    _rawSubscription = _rawSseService.stream.listen((data) {
      if (!mounted) return;
      final rawValues = _extractXyzValues(data);
      if (rawValues == null) return;
      setState(() {
        _appendRawPoint(_rawXData, rawValues.$1);
        _appendRawPoint(_rawYData, rawValues.$2);
        _appendRawPoint(_rawZData, rawValues.$3);
        _rawIndex++;
        _trimAndReindexRawSeries();
      });
    });

    await _processedSseService.connect();
    _processedSubscription = _processedSseService.stream.listen((data) {
      if (!mounted) return;
      final processedValues = _extractProcessedValues(data);
      if (processedValues == null) return;
      setState(() {
        _appendProcessedPoint(_processedXData, processedValues.$1);
        _appendProcessedPoint(_processedYData, processedValues.$2);
        _appendProcessedPoint(_processedZData, processedValues.$3);
        _processedIndex++;
        _trimAndReindexProcessedSeries();
      });
    });
  }

  @override
  void dispose() {
    _analyticsSubscription?.cancel();
    _rawSubscription?.cancel();
    _processedSubscription?.cancel();
    _analyticsSseService.dispose();
    _rawSseService.dispose();
    _processedSseService.dispose();
    super.dispose();
  }

  void _appendRawPoint(List<FlSpot> points, double value) {
    points.add(FlSpot(_rawIndex.toDouble(), value));
  }

  void _appendProcessedPoint(List<FlSpot> points, double value) {
    points.add(FlSpot(_processedIndex.toDouble(), value));
  }

  void _appendAnalyzedPoint(List<FlSpot> points, double value) {
    points.add(FlSpot(_analyzedIndex.toDouble(), value));
  }

  void _trimAndReindexAnalyzedSeries() {
    while (_analyzedXData.length > 65) {
      _analyzedXData.removeAt(0);
    }
    while (_analyzedYData.length > 65) {
      _analyzedYData.removeAt(0);
    }
    while (_analyzedZData.length > 65) {
      _analyzedZData.removeAt(0);
    }

    for (int i = 0; i < _analyzedXData.length; i++) {
      _analyzedXData[i] = FlSpot(i.toDouble(), _analyzedXData[i].y);
    }
    for (int i = 0; i < _analyzedYData.length; i++) {
      _analyzedYData[i] = FlSpot(i.toDouble(), _analyzedYData[i].y);
    }
    for (int i = 0; i < _analyzedZData.length; i++) {
      _analyzedZData[i] = FlSpot(i.toDouble(), _analyzedZData[i].y);
    }
    _analyzedIndex = _analyzedXData.length;
  }

  void _trimAndReindexRealtime() {
    while (_liveData.length > 65) {
      _liveData.removeAt(0);
    }
    for (int i = 0; i < _liveData.length; i++) {
      _liveData[i] = FlSpot(i.toDouble(), _liveData[i].y);
    }
    _dataPointIndex = _liveData.length;
  }

  void _trimAndReindexRawSeries() {
    while (_rawXData.length > 65) {
      _rawXData.removeAt(0);
    }
    while (_rawYData.length > 65) {
      _rawYData.removeAt(0);
    }
    while (_rawZData.length > 65) {
      _rawZData.removeAt(0);
    }

    for (int i = 0; i < _rawXData.length; i++) {
      _rawXData[i] = FlSpot(i.toDouble(), _rawXData[i].y);
    }
    for (int i = 0; i < _rawYData.length; i++) {
      _rawYData[i] = FlSpot(i.toDouble(), _rawYData[i].y);
    }
    for (int i = 0; i < _rawZData.length; i++) {
      _rawZData[i] = FlSpot(i.toDouble(), _rawZData[i].y);
    }
    _rawIndex = _rawXData.length;
  }

  void _trimAndReindexProcessedSeries() {
    while (_processedXData.length > 65) {
      _processedXData.removeAt(0);
    }
    while (_processedYData.length > 65) {
      _processedYData.removeAt(0);
    }
    while (_processedZData.length > 65) {
      _processedZData.removeAt(0);
    }

    for (int i = 0; i < _processedXData.length; i++) {
      _processedXData[i] = FlSpot(i.toDouble(), _processedXData[i].y);
    }
    for (int i = 0; i < _processedYData.length; i++) {
      _processedYData[i] = FlSpot(i.toDouble(), _processedYData[i].y);
    }
    for (int i = 0; i < _processedZData.length; i++) {
      _processedZData[i] = FlSpot(i.toDouble(), _processedZData[i].y);
    }
    _processedIndex = _processedXData.length;
  }

  (double, double, double)? _extractXyzValues(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final fromRawPayload = map['rawPayload'];
      if (fromRawPayload is Map) {
        final rawParams = fromRawPayload['parameters'];
        if (rawParams is Map) {
          final x = _toDouble(rawParams['x']);
          final y = _toDouble(rawParams['y']);
          final z = _toDouble(rawParams['z']);
          if (x != null && y != null && z != null) return (x, y, z);
        }
      }

      final params = map['parameters'];
      if (params is Map) {
        final x = _toDouble(params['x']);
        final y = _toDouble(params['y']);
        final z = _toDouble(params['z']);
        if (x != null && y != null && z != null) return (x, y, z);
      }

      final x = _toDouble(map['x']);
      final y = _toDouble(map['y']);
      final z = _toDouble(map['z']);
      if (x != null && y != null && z != null) return (x, y, z);
    }
    return null;
  }

  (double, double, double)? _extractProcessedValues(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final processedPayload = map['processedPayload'];
      if (processedPayload is Map) {
        final roll = _toDouble(processedPayload['rollDegrees']);
        final pitch = _toDouble(processedPayload['pitchDegrees']);
        final tilt = _toDouble(processedPayload['tiltFromVerticalDegrees']);
        if (roll != null && pitch != null && tilt != null) {
          return (roll, pitch, tilt);
        }

        final x = _toDouble(processedPayload['x']);
        final y = _toDouble(processedPayload['y']);
        final z = _toDouble(processedPayload['z']);
        if (x != null && y != null && z != null) return (x, y, z);
      }
    }

    return _extractXyzValues(payload);
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

  (double, double, double, double)? _extractAnalyzedMetricsFromPayload(
    dynamic payload,
  ) {
    for (final map in _candidateMaps(payload)) {
      final metrics = _extractAnalyzedMetricsFromEvent(map);
      if (metrics != null) return metrics;
    }
    return null;
  }

  (double, double, double, double)? _extractAnalyzedMetricsFromEvent(
    Map<dynamic, dynamic> event,
  ) {
    final series = event['series'];
    final values = <String, double>{};

    if (series is List) {
      for (final item in series) {
        if (item is! Map) continue;
        final name = item['name']?.toString();
        final value = _toDouble(item['value']);
        if (name == null || value == null) continue;
        values[name] = value;
      }
    }

    final x = values['x'] ??
        values['tilt.x'] ??
        values['vibration.x'] ??
        _toDouble(event['x']);
    final y = values['y'] ??
        values['tilt.y'] ??
        values['vibration.y'] ??
        _toDouble(event['y']);
    final z = values['z'] ??
        values['tilt.z'] ??
        values['vibration.z'] ??
        _toDouble(event['z']);
    if (x == null || y == null || z == null) return null;

    final realtimeMagnitude = values['accelerationMagnitude'] ??
        values['vibration.vibrationRms'] ??
        values['inclinometer.inclinationDegrees'] ??
        sqrt((x * x) + (y * y) + (z * z));

    return (x, y, z, realtimeMagnitude);
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final statsApi = ref.watch(superAdminDashboardStatsApiProvider).valueOrNull;
    final activeAlerts = (statsApi?['activeAlerts'] as num?)?.toInt() ??
        db.getActiveAlerts().length;
    final avgTilt = (statsApi?['averageTilt'] as num?)?.toDouble() ??
        (db.sensors.isEmpty
            ? 0.0
            : db.sensors
                    .map((s) => s.lastReading.abs())
                    .reduce((a, b) => a + b) /
                db.sensors.length);
    final maxTilt = (statsApi?['maxTilt'] as num?)?.toDouble() ??
        (db.sensors.isEmpty
            ? 0.0
            : db.sensors
                .map((s) => s.lastReading.abs())
                .reduce((a, b) => max(a, b)));

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopStats(context, avgTilt, maxTilt, activeAlerts),
          const SizedBox(height: 18),
          _buildRealtimeCard(context),
          const SizedBox(height: 18),
          _buildLiveSeriesCard(
            context,
            title: 'Sensor Live Records',
            icon: Icons.sensors,
            xData: _rawXData,
            yData: _rawYData,
            zData: _rawZData,
          ),
          const SizedBox(height: 18),
          _buildLiveSeriesCard(
            context,
            title: 'Processed Live Data',
            icon: Icons.settings_input_component_outlined,
            xData: _processedXData,
            yData: _processedYData,
            zData: _processedZData,
            xLabel: 'Roll',
            yLabel: 'Pitch',
            zLabel: 'Tilt',
          ),
          const SizedBox(height: 18),
          _buildLiveSeriesCard(
            context,
            title: 'Analyzed Live Data',
            icon: Icons.psychology_alt_outlined,
            xData: _analyzedXData,
            yData: _analyzedYData,
            zData: _analyzedZData,
          ),
          const SizedBox(height: 18),
          _buildAnalyticsGrid(context),
          const SizedBox(height: 18),
          _buildScatterCard(context),
          const SizedBox(height: 18),
          _buildSensorReadingsCard(context),
          const SizedBox(height: 18),
          _buildBottomLiveStats(context),
          const SizedBox(height: 18),
          _buildTiltRangeDistribution(context, db),
          const SizedBox(height: 18),
          _buildTopTiltSensorsCard(context, db),
        ],
      ),
    );

    if (widget.embeddedScroll) return content;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: content,
    );
  }

  Widget _buildLiveSeriesCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<FlSpot> xData,
    required List<FlSpot> yData,
    required List<FlSpot> zData,
    String xLabel = 'X',
    String yLabel = 'Y',
    String zLabel = 'Z',
  }) {
    final allSpots = [...xData, ...yData, ...zData];
    final hasData = allSpots.isNotEmpty;
    final minY = hasData ? allSpots.map((e) => e.y).reduce(min) - 1 : 0.0;
    final maxY = hasData ? allSpots.map((e) => e.y).reduce(max) + 1 : 10.0;
    final minX = hasData ? allSpots.map((e) => e.x).reduce(min) : 0.0;
    final maxX = hasData ? allSpots.map((e) => e.x).reduce(max) : 65.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, title, icon),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _LegendItem(color: const Color(0xFF2E8BFF), label: xLabel),
              _LegendItem(color: const Color(0xFF11A95D), label: yLabel),
              _LegendItem(color: const Color(0xFFE58500), label: zLabel),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval:
                      hasData ? ((maxY - minY) / 5).clamp(1, 9999) : 2,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFd2dbe0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: _mutedTextColor(context),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 10,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _mutedTextColor(context),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: xData,
                    isCurved: true,
                    color: const Color(0xFF2E8BFF),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: yData,
                    isCurved: true,
                    color: const Color(0xFF11A95D),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: zData,
                    isCurved: true,
                    color: const Color(0xFFE58500),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats(
    BuildContext context,
    double avgTilt,
    double maxTilt,
    int activeAlerts,
  ) {
    final cards = [
      _MetricData(
        title: 'AVG TILT ANGLE',
        value: '${avgTilt.toStringAsFixed(2)}°',
        subtitle: 'Current',
        icon: Icons.trending_up,
        tint: const Color(0xFF5973d8),
        isHighlight: false,
      ),
      _MetricData(
        title: 'MAX TILT ANGLE',
        value: '${maxTilt.toStringAsFixed(2)}°',
        subtitle: 'Tower',
        icon: Icons.warning_amber_rounded,
        tint: const Color(0xFFd29a00),
      ),
      _MetricData(
        title: 'SYSTEM HEALTH',
        value: '${(100 - (activeAlerts * 2)).clamp(84, 100)}%',
        subtitle: 'Operational',
        icon: Icons.check_circle_outline,
        tint: const Color(0xFF0ea65b),
      ),
      const _MetricData(
        title: 'LAST UPDATE',
        value: 'SSE',
        subtitle: 'Live stream',
        icon: Icons.notifications_none,
        tint: Color(0xFF5973d8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 980
            ? 4
            : width >= 820
                ? 3
                : width >= 560
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width >= 980
                ? 1.95
                : width >= 820
                    ? 2.05
                    : width >= 560
                        ? 2.3
                        : 2.6,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }

  Widget _buildRealtimeCard(BuildContext context) {
    final hasLiveData = _liveData.isNotEmpty;
    final minLiveY =
        hasLiveData ? _liveData.map((e) => e.y).reduce(min) - 2 : 42.0;
    final maxLiveY =
        hasLiveData ? _liveData.map((e) => e.y).reduce(max) + 2 : 72.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF5f78de)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Real-Time Tilt Monitoring - All Sensors',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _titleColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _liveData.isEmpty ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _liveData.isEmpty
                          ? 'Waiting...'
                          : 'Live ${_liveData.length} pts',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _chip(context, 'Pause', icon: Icons.pause, selected: false),
                  _chip(context, '1H', selected: true),
                  _chip(context, '6H'),
                  _chip(context, '1D'),
                  _chip(context, '7D'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 350,
            child: LineChart(
              LineChartData(
                minY: minLiveY,
                maxY: maxLiveY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFd2dbe0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 11, color: _mutedTextColor(context)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final sec = value.toInt();
                        final minute = 43 + (sec ~/ 20);
                        final second = (sec * 3) % 60;
                        return Text(
                          '14:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              fontSize: 10, color: _mutedTextColor(context)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _liveData.isEmpty
                        ? List.generate(65, (i) {
                            final y = 47 +
                                (sin(i / 5) * 6) +
                                (Random(i + 2).nextDouble() * 16);
                            return FlSpot(i.toDouble(), y);
                          })
                        : _liveData,
                    isCurved: true,
                    color: const Color(0xFF0f9ca0),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 1050;
        if (!twoCols) {
          return Column(
            children: [
              _historicalTrendCard(context),
              const SizedBox(height: 16),
              _statusDistributionCard(context),
              const SizedBox(height: 16),
              _tiltPatternCard(context),
              const SizedBox(height: 16),
              _thresholdMonitoringCard(context),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _historicalTrendCard(context)),
                const SizedBox(width: 16),
                Expanded(child: _statusDistributionCard(context)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _tiltPatternCard(context)),
                const SizedBox(width: 16),
                Expanded(child: _thresholdMonitoringCard(context)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _historicalTrendCard(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Historical Trend', Icons.trending_up),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 2.1,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        final d = value.toInt() + 1;
                        if (d % 7 != 0) return const SizedBox.shrink();
                        return Text(
                          '${d.toString().padLeft(2, '0')}/01',
                          style: TextStyle(
                              fontSize: 10, color: _mutedTextColor(context)),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: _thresholdLinesForGraph(
                    context,
                    ThresholdGraphTarget.dashboardRealtime,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(30, (i) {
                      final y = 1.05 + (Random(i + 3).nextDouble() * 0.55);
                      return FlSpot(i.toDouble(), y);
                    }),
                    isCurved: true,
                    color: const Color(0xFF0d6e76),
                    barWidth: 2.6,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDistributionCard(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Sensor Status Distribution', Icons.memory_outlined),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: 68,
                    color: const Color(0xFF0ca15f),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: 25,
                    color: const Color(0xFFd39a00),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: 7,
                    color: const Color(0xFFea3e43),
                    title: '',
                    radius: 60,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _LegendItem(color: Color(0xFF0ca15f), label: 'Normal'),
              _LegendItem(color: Color(0xFFd39a00), label: 'Warning'),
              _LegendItem(color: Color(0xFFea3e43), label: 'Critical'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiltPatternCard(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Tilt Pattern Analysis', Icons.show_chart),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 2.0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 10, color: _mutedTextColor(context)),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(24, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: 0.8 + Random(i + 12).nextDouble() * 0.8,
                        width: 14,
                        color: const Color(0xFF0f8b89),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdMonitoringCard(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Threshold Monitoring', Icons.warning_amber_rounded),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Transform.rotate(
                        angle: -0.7,
                        child: Text(
                          'TLT-${(value.toInt() + 1).toString().padLeft(3, '0')}',
                          style: TextStyle(
                              fontSize: 10, color: _mutedTextColor(context)),
                        ),
                      ),
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: _thresholdLinesForGraph(
                    context,
                    ThresholdGraphTarget.dashboardThresholdMonitoring,
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  final value = [1.2, 0.8, 1.8, 1.5, 1.1, 1.6, 0.9][i];
                  final color = (value >= 1.6)
                      ? const Color(0xFFd39a00)
                      : const Color(0xFF0ca15f);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 26,
                        color: color,
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScatterCard(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'X & Y Axis Analysis', Icons.multiline_chart),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ScatterChart(
              ScatterChartData(
                minX: -2,
                maxX: 2,
                minY: -2,
                maxY: 2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0), strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0), strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                scatterSpots: List.generate(24, (i) {
                  final x =
                      (Random(i + 77).nextDouble() * 2) * (i.isEven ? 1 : -1);
                  final y = (Random(i + 177).nextDouble() * 2) *
                      (i % 3 == 0 ? 1 : -1);
                  return ScatterSpot(x, y,
                      dotPainter: FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF2d8f93),
                      ));
                }),
                showingTooltipIndicators: const [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorReadingsCard(BuildContext context) {
    const rows = [
      [
        'TLT-001',
        'Building A - Column 7',
        'Tower',
        '1.46°',
        '-0.86°',
        '1.36°',
        'normal',
        'Just now'
      ],
      [
        'TLT-002',
        'Building A - Column 12',
        'Tower',
        '1.20°',
        '-1.03°',
        '-0.05°',
        'normal',
        'Just now'
      ],
      [
        'TLT-003',
        'Building B - Foundation',
        'Wall',
        '0.01°',
        '-1.37°',
        '1.33°',
        'normal',
        'Just now'
      ],
      [
        'TLT-004',
        'Bridge Section 9',
        'Bridge',
        '1.47°',
        '1.91°',
        '2.22°',
        'warning',
        'Just now'
      ],
      [
        'TLT-005',
        'Water Tank Base',
        'Basin',
        '-0.52°',
        '0.79°',
        '0.63°',
        'normal',
        'Just now'
      ],
    ];

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _panelTitle(
                context,
                'Tilt Sensor Readings - Live Data',
                Icons.show_chart_outlined,
              ),
              _chip(context, 'Export', icon: Icons.upload_outlined),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFc5d2d8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFe3eaee)
                      : const Color(0xFF2A4154),
                ),
                dataRowMinHeight: 54,
                dataRowMaxHeight: 54,
                horizontalMargin: 10,
                columnSpacing: 26,
                columns: [
                  _tableHeading(context, 'Sensor ID'),
                  _tableHeading(context, 'Location'),
                  _tableHeading(context, 'Zone'),
                  _tableHeading(context, 'X Axis (°)'),
                  _tableHeading(context, 'Y Axis (°)'),
                  _tableHeading(context, 'Total Tilt (°)'),
                  _tableHeading(context, 'Status'),
                  _tableHeading(context, 'Last Update'),
                ],
                rows: rows.map((r) {
                  final status = r[6];
                  final isWarning = status == 'warning';
                  return DataRow(cells: [
                    DataCell(Text(r[0])),
                    DataCell(Text(r[1])),
                    DataCell(Text(r[2])),
                    DataCell(Text(r[3])),
                    DataCell(Text(r[4])),
                    DataCell(Text(r[5])),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isWarning
                            ? const Color(0xFFf9edc9)
                            : const Color(0xFFd7f2df),
                        border: Border.all(
                          color: isWarning
                              ? const Color(0xFFd9a21d)
                              : const Color(0xFF2eaf61),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isWarning
                              ? const Color(0xFFb38200)
                              : const Color(0xFF0d9a4d),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    DataCell(Text(r[7])),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _tableHeading(BuildContext context, String label) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isLight ? const Color(0xFF203845) : const Color(0xFFD8E8F5),
        ),
      ),
    );
  }

  Widget _buildBottomLiveStats(BuildContext context) {
    const cards = [
      _MiniStatData(
        title: 'ACTIVE SENSORS',
        value: '124',
        unit: 'sensors',
        detail: 'of 214 total',
        badge: 'Live',
        icon: Icons.monitor_heart_outlined,
        iconColor: Color(0xFF0aa34f),
      ),
      _MiniStatData(
        title: 'DATA THROUGHPUT',
        value: '62.0',
        unit: 'pts/sec',
        detail: '',
        badge: 'Live',
        icon: Icons.bolt_outlined,
        iconColor: Color(0xFF5f78de),
      ),
      _MiniStatData(
        title: 'SYSTEM LOAD',
        value: '100',
        unit: '%',
        detail: '',
        badge: 'Live',
        icon: Icons.trending_up,
        iconColor: Color(0xFFd39a00),
      ),
      _MiniStatData(
        title: 'NETWORK LATENCY',
        value: '37',
        unit: 'ms',
        detail: '',
        badge: 'Stable',
        icon: Icons.network_ping,
        iconColor: Color(0xFF2b8ab8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 860
            ? 4
            : width >= 700
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width >= 860
                ? 2.2
                : width >= 700
                    ? 2.2
                    : 2.6,
          ),
          itemBuilder: (context, index) => _MiniStatCard(data: cards[index]),
        );
      },
    );
  }

  Widget _buildTiltRangeDistribution(BuildContext context, dynamic db) {
    final readings = (db.sensors as List)
        .map((sensor) => (sensor.lastReading as num).abs().toDouble())
        .toList();
    final bins = [0, 0, 0, 0];
    for (final value in readings) {
      if (value < 0.5) {
        bins[0]++;
      } else if (value < 1.0) {
        bins[1]++;
      } else if (value < 1.5) {
        bins[2]++;
      } else {
        bins[3]++;
      }
    }
    final labels = ['0-0.5°', '0.5-1.0°', '1.0-1.5°', '>1.5°'];
    final maxCount = bins.reduce(max).clamp(1, 999);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Tilt Range Distribution',
            Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 10),
          Text(
            'Shows how many sensors are in each tilt severity band.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 270,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: (maxCount + 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: _mutedTextColor(context),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(labels.length, (index) {
                  final count = bins[index];
                  final color = index <= 1
                      ? const Color(0xFF0ca15f)
                      : index == 2
                          ? const Color(0xFFd39a00)
                          : const Color(0xFFea3e43);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        width: 34,
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTiltSensorsCard(BuildContext context, dynamic db) {
    final sensors = List.of(db.sensors as List);
    sensors.sort(
      (a, b) =>
          (b.lastReading as num).abs().compareTo((a.lastReading as num).abs()),
    );
    final topSensors = sensors.take(5).toList();
    final maxTilt = topSensors.isEmpty
        ? 1.0
        : topSensors
            .map((sensor) => (sensor.lastReading as num).abs().toDouble())
            .reduce(max);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Top Sensors By Tilt',
            Icons.leaderboard_outlined,
          ),
          const SizedBox(height: 10),
          Text(
            'Highest current tilt sensors to review first.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          if (topSensors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No sensor data available.',
                  style: TextStyle(color: _mutedTextColor(context)),
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: max(2.0, maxTilt + 0.5),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.5,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFd2dbe0)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.blueGrey.shade200),
                      bottom: BorderSide(color: Colors.blueGrey.shade200),
                      top: BorderSide.none,
                      right: BorderSide.none,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= topSensors.length) {
                            return const SizedBox.shrink();
                          }
                          final sensor = topSensors[index];
                          final label =
                              (sensor.serialNumber ?? sensor.id).toString();
                          final shortLabel = label.length > 8
                              ? '${label.substring(0, 8)}…'
                              : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              shortLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: _mutedTextColor(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(topSensors.length, (index) {
                    final value =
                        (topSensors[index].lastReading as num).abs().toDouble();
                    final color = value >= 1.5
                        ? const Color(0xFFea3e43)
                        : value >= 1.0
                            ? const Color(0xFFd39a00)
                            : const Color(0xFF0ca15f);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          width: 30,
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMultiSensorComparison(BuildContext context) {
    final timeLabels = List.generate(11, (i) => '15:0${(i / 2).floor()}');
    final lineColors = [
      const Color(0xFF4f6fd8),
      const Color(0xFF11a95d),
      const Color(0xFFde6c00),
      const Color(0xFFa447db),
      const Color(0xFF168f9a),
      const Color(0xFFb68008),
    ];
    final legends = [
      'SEN-H002B 52.41%',
      'SEN-P003C 1011.08Pa',
      'SEN-V004D 0.54mm/s',
      'SEN-T005E 21.95°C',
      'SEN-1L937I5C 22.57°C',
      'SEN-2YY6LMEF 20.06°C',
    ];

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Multi-Sensor Comparison', Icons.trending_up),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: Row(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 60,
                      minY: 0,
                      maxY: 1100,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 200,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: Color(0xFFd2dbe0)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: Colors.blueGrey.shade200),
                          bottom: BorderSide(color: Colors.blueGrey.shade200),
                          top: BorderSide.none,
                          right: BorderSide.none,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 12,
                            getTitlesWidget: (value, meta) {
                              final idx = (value ~/ 6).toInt();
                              if (idx < 0 || idx >= timeLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                timeLabels[idx],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _mutedTextColor(context)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(61, (i) {
                            return FlSpot(
                              i.toDouble(),
                              1005 + Random(i + 33).nextDouble() * 12,
                            );
                          }),
                          color: lineColors[1],
                          isCurved: true,
                          barWidth: 2.4,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: List.generate(61, (i) {
                            return FlSpot(
                              i.toDouble(),
                              45 + Random(i + 11).nextDouble() * 18,
                            );
                          }),
                          color: lineColors[0],
                          isCurved: true,
                          barWidth: 2.2,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: List.generate(61, (i) {
                            return FlSpot(
                              i.toDouble(),
                              20 + Random(i + 5).nextDouble() * 3,
                            );
                          }),
                          color: lineColors[4],
                          isCurved: true,
                          barWidth: 1.9,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: List.generate(61, (i) {
                            return FlSpot(
                              i.toDouble(),
                              3 + Random(i + 9).nextDouble() * 2,
                            );
                          }),
                          color: lineColors[2],
                          isCurved: true,
                          barWidth: 1.8,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: List.generate(61, (i) {
                            return FlSpot(
                              i.toDouble(),
                              22 + Random(i + 71).nextDouble() * 2,
                            );
                          }),
                          color: lineColors[3],
                          isCurved: true,
                          barWidth: 1.8,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: List.generate(61, (i) {
                            return FlSpot(
                              i.toDouble(),
                              19 + Random(i + 81).nextDouble() * 2,
                            );
                          }),
                          color: lineColors[5],
                          isCurved: true,
                          barWidth: 1.8,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: legends.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 2,
                              color: lineColors[index],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                legends[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: lineColors[index],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStatisticalAnalysis(BuildContext context) {
    const sensors = [
      'SEN-H002B',
      'SEN-P003C',
      'SEN-V004D',
      'SEN-T005E',
      'SEN-1L937I5C',
      'SEN-2YY6LMEF',
      'SENSOR-0001',
      'SENSOR-0002',
    ];
    final mean = <double>[55, 1008, 0.9, 22, 23, 21.7, 0.6, 150];
    final median = <double>[51, 1014, 0.7, 21.2, 22.6, 20.9, 0.5, 164];

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Statistical Analysis', Icons.memory_outlined),
          const SizedBox(height: 12),
          SizedBox(
            height: 330,
            child: ScatterChart(
              ScatterChartData(
                minX: -0.5,
                maxX: sensors.length - 0.5,
                minY: 0,
                maxY: 1100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 200,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.blueGrey.shade200),
                    bottom: BorderSide(color: Colors.blueGrey.shade200),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sensors.length) {
                          return const SizedBox.shrink();
                        }
                        return Transform.rotate(
                          angle: -0.7,
                          child: Text(
                            sensors[idx],
                            style: TextStyle(
                                fontSize: 10, color: _mutedTextColor(context)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                scatterSpots: [
                  ...List.generate(sensors.length, (i) {
                    return ScatterSpot(
                      i.toDouble(),
                      mean[i],
                      dotPainter: FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF4f6fd8),
                      ),
                    );
                  }),
                  ...List.generate(sensors.length, (i) {
                    return ScatterSpot(
                      i.toDouble(),
                      median[i],
                      dotPainter: FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF0da65a),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 18,
            children: [
              _LegendItem(color: Color(0xFF4f6fd8), label: 'Mean'),
              _LegendItem(color: Color(0xFF0da65a), label: 'Median'),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHourlyHeatmap(BuildContext context) {
    final values = List.generate(24, (i) => Random(i + 91).nextDouble() * 57.7);
    final maxValue = values.reduce(max);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Hourly Activity Heatmap', Icons.show_chart),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Hourly Activity Pattern - SEN-H002B',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _titleColor(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: List.generate(24, (i) {
                    final value = values[i];
                    final normalized = (value / maxValue).clamp(0.0, 1.0);
                    final color = Color.lerp(
                      const Color(0xFF0f1320),
                      const Color(0xFF5a7de2),
                      normalized,
                    )!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 52,
                        height: 320,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(24, (i) {
                    return SizedBox(
                      width: 56,
                      child: Center(
                        child: Text(
                          '${i}h',
                          style: TextStyle(
                            fontSize: 11,
                            color: _mutedTextColor(context),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '0',
                      style: TextStyle(
                          fontSize: 11, color: _mutedTextColor(context)),
                    ),
                    Container(
                      width: 320,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFcad9ff), Color(0xFF5a7de2)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Text(
                      maxValue.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 11, color: _mutedTextColor(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelTitle(BuildContext context, String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _mutedTextColor(context), size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 36 > 18 ? 36 - 18 : 18,
            fontWeight: FontWeight.w700,
            color: _titleColor(context),
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label,
      {IconData? icon, bool selected = false}) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = selected
        ? (isLight ? const Color(0xFFdbe6ea) : const Color(0xFF2A4052))
        : (isLight ? const Color(0xFFd6e1e6) : const Color(0xFF23394A));
    final fg = isLight ? const Color(0xFF20333e) : const Color(0xFFD8E8F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18 > 14 ? 18 - 4 : 14,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Color _titleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF1c2a33)
        : const Color(0xFFd4e4ef);
  }

  Color _mutedTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF60717c)
        : const Color(0xFF9FB4C6);
  }

  List<HorizontalLine> _thresholdLinesForGraph(
    BuildContext context,
    ThresholdGraphTarget target,
  ) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final rules = db.thresholdRulesForGraph(target);

    return rules
        .map(
          (rule) => HorizontalLine(
            y: rule.value,
            color: rule.color,
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: TextStyle(color: rule.color, fontWeight: FontWeight.w600),
              labelResolver: (_) =>
                  '${rule.label}: ${rule.value.toStringAsFixed(1)}°',
            ),
          ),
        )
        .toList();
  }
}

class _DashboardPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DashboardPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final bool isHighlight;

  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tint,
    this.isHighlight = false,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final onDark = data.isHighlight
        ? Colors.white
        : (isLight ? const Color(0xFF1e3039) : const Color(0xFFE3EEF8));
    final sub = data.isHighlight
        ? const Color(0xFFb5dbef)
        : (isLight ? data.tint : data.tint.withValues(alpha: 0.9));
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 92 || constraints.maxWidth < 170;
        return Container(
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            color: data.isHighlight ? data.tint : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: data.isHighlight ? 0.12 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 38,
                height: compact ? 30 : 38,
                decoration: BoxDecoration(
                  color: data.isHighlight
                      ? Colors.white.withValues(alpha: 0.22)
                      : data.tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  size: compact ? 16 : 20,
                  color: data.isHighlight ? Colors.white : data.tint,
                ),
              ),
              SizedBox(width: compact ? 6 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 10 : 12,
                        color: onDark.withValues(alpha: 0.78),
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      data.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 22 : 30,
                        fontWeight: FontWeight.w800,
                        color: onDark,
                        height: 1,
                      ),
                    ),
                    if (!compact)
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: sub,
                          height: 1.2,
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF566872)
        : const Color(0xFF9FB4C6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
      ],
    );
  }
}

class _MiniStatData {
  final String title;
  final String value;
  final String unit;
  final String detail;
  final String badge;
  final IconData icon;
  final Color iconColor;

  const _MiniStatData({
    required this.title,
    required this.value,
    required this.unit,
    required this.detail,
    required this.badge,
    required this.icon,
    required this.iconColor,
  });
}

class _MiniStatCard extends StatelessWidget {
  final _MiniStatData data;

  const _MiniStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final titleColor =
        isLight ? const Color(0xFF4d616d) : const Color(0xFFB8CBDA);
    final valueColor =
        isLight ? const Color(0xFF11212d) : const Color(0xFFE3EEF8);
    final unitColor =
        isLight ? const Color(0xFF5f707a) : const Color(0xFFA8BDCE);
    final detailColor =
        isLight ? const Color(0xFF60717c) : const Color(0xFF9FB4C6);
    final badgeBg = isLight ? const Color(0xFFd7f2df) : const Color(0xFF1E4736);
    final badgeBorder =
        isLight ? const Color(0xFF9edbb2) : const Color(0xFF2E8E61);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 96 || constraints.maxWidth < 200;
        return _DashboardPanel(
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 24 : 30,
                    height: compact ? 24 : 30,
                    decoration: BoxDecoration(
                      color: data.iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      color: data.iconColor,
                      size: compact ? 14 : 16,
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      data.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      data.badge,
                      style: const TextStyle(
                        color: Color(0xFF0d9a4d),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.value,
                    style: TextStyle(
                      fontSize: compact ? 22 : 30,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: compact ? 4 : 6),
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 2 : 4),
                    child: Text(
                      data.unit,
                      style: TextStyle(
                        fontSize: compact ? 13 : 16,
                        color: unitColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (data.detail.isNotEmpty && !compact)
                Text(
                  data.detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: detailColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
