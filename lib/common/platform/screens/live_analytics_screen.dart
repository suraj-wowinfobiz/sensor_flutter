import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/ops_theme.dart';
import '../services/analytics_sse_service.dart';

class LiveAnalyticsScreen extends StatefulWidget {
  const LiveAnalyticsScreen({super.key});

  @override
  State<LiveAnalyticsScreen> createState() => _LiveAnalyticsScreenState();
}

class _LiveAnalyticsScreenState extends State<LiveAnalyticsScreen> {
  final AnalyticsSseService _analyticsSseService = AnalyticsSseService();
  final List<FlSpot> _series = [];
  final List<_LiveAnalyticsRow> _rows = [];
  StreamSubscription? _subscription;
  Map<String, dynamic>? _latestEvent;
  int _pointIndex = 0;
  bool _paused = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    await _analyticsSseService.connect();
    if (!mounted) return;
    setState(() => _connected = _analyticsSseService.isConnected);
    _subscription = _analyticsSseService.stream.listen((payload) {
      if (!mounted || _paused) return;
      final event = _asMap(payload);
      if (event == null) return;
      final rows = _extractRows(event);
      if (rows.isEmpty) return;
      setState(() {
        _latestEvent = event;
        for (final row in rows) {
          _rows.insert(0, row);
          _series.add(FlSpot(_pointIndex.toDouble(), row.value));
          _pointIndex++;
        }
        while (_rows.length > 12) {
          _rows.removeLast();
        }
        while (_series.length > 120) {
          _series.removeAt(0);
        }
        for (var i = 0; i < _series.length; i++) {
          _series[i] = FlSpot(i.toDouble(), _series[i].y);
        }
        _pointIndex = _series.length;
      });
    });
  }

  Map<String, dynamic>? _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  List<_LiveAnalyticsRow> _extractRows(Map<String, dynamic> event) {
    final nestedEvent = event['event'];
    final timestamp = event['timestamp']?.toString() ??
        (nestedEvent is Map ? nestedEvent['timestamp']?.toString() : null);
    final sensorId = event['sensorId']?.toString() ??
        (nestedEvent is Map ? nestedEvent['sensorId']?.toString() : null) ??
        'unknown';

    final rows = <_LiveAnalyticsRow>[];
    final series = event['series'];
    if (series is List) {
      for (final item in series) {
        if (item is! Map) continue;
        final value = _toDouble(item['value']);
        if (value == null) continue;
        rows.add(
          _LiveAnalyticsRow(
            metric: item['name']?.toString() ?? 'value',
            value: value,
            sensorId: sensorId,
            timestamp: timestamp ?? DateTime.now().toIso8601String(),
          ),
        );
      }
    }

    if (rows.isNotEmpty) return rows;

    final evaluations =
        nestedEvent is Map ? nestedEvent['evaluations'] : event['evaluations'];
    if (evaluations is List) {
      for (final item in evaluations) {
        if (item is! Map) continue;
        final value = _toDouble(item['value']);
        if (value == null) continue;
        rows.add(
          _LiveAnalyticsRow(
            metric: item['parameterName']?.toString() ?? 'value',
            value: value,
            sensorId: sensorId,
            timestamp: timestamp ?? DateTime.now().toIso8601String(),
          ),
        );
      }
    }
    return rows;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _analyticsSseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestValue =
        _rows.isEmpty ? '--' : _rows.first.value.toStringAsFixed(2);
    return OpsPage(
      title: 'Live Analytics',
      subtitle: 'Streaming analytics events from live sensor processing',
      actions: [
        FilledButton.icon(
          onPressed: () => setState(() => _paused = !_paused),
          icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          label: Text(_paused ? 'Resume' : 'Pause'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 920;
              final cards = [
                OpsKpiCard(
                  label: 'Connection',
                  value: _connected ? 'Live' : 'Waiting',
                  helper: 'Analytics SSE',
                  icon: Icons.wifi_tethering_rounded,
                  color: _connected ? OpsColors.success : OpsColors.warning,
                ),
                OpsKpiCard(
                  label: 'Latest Value',
                  value: latestValue,
                  helper:
                      _rows.isEmpty ? 'No readings yet' : _rows.first.metric,
                  icon: Icons.timeline_rounded,
                  color: OpsColors.primary,
                ),
                OpsKpiCard(
                  label: 'Buffered Points',
                  value: '${_series.length}',
                  helper: 'Last 120 plotted',
                  icon: Icons.show_chart_rounded,
                  color: OpsColors.primaryContainer,
                ),
              ];
              if (compact) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: cards
                    .map(
                      (card) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: card,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          OpsPanel(
            title: 'Live Signal',
            subtitle: _paused ? 'Paused' : 'Streaming',
            child: SizedBox(
              height: 320,
              child: _series.isEmpty
                  ? const Center(
                      child: Text(
                        'Waiting for analytics events',
                        style: TextStyle(color: OpsColors.muted),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minY: _series
                                .map((spot) => spot.y)
                                .reduce((a, b) => a < b ? a : b) -
                            2,
                        maxY: _series
                                .map((spot) => spot.y)
                                .reduce((a, b) => a > b ? a : b) +
                            2,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: OpsColors.border),
                        ),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _series,
                            isCurved: true,
                            color: OpsColors.primary,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: OpsColors.primary.withValues(alpha: .10),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          OpsPanel(
            title: 'Latest Events',
            subtitle: 'Most recent metrics',
            child: _rows.isEmpty
                ? const Text(
                    'No live analytics rows yet.',
                    style: TextStyle(color: OpsColors.muted),
                  )
                : Column(
                    children: _rows
                        .map(
                          (row) => _LiveAnalyticsTile(row: row),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          OpsPanel(
            title: 'Raw Event',
            subtitle: 'Last payload',
            child: Text(
              _latestEvent == null ? '{}' : _latestEvent.toString(),
              style: const TextStyle(
                color: OpsColors.muted,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveAnalyticsRow {
  const _LiveAnalyticsRow({
    required this.metric,
    required this.value,
    required this.sensorId,
    required this.timestamp,
  });

  final String metric;
  final double value;
  final String sensorId;
  final String timestamp;
}

class _LiveAnalyticsTile extends StatelessWidget {
  const _LiveAnalyticsTile({required this.row});

  final _LiveAnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: OpsColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: OpsColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.metric,
                  style: const TextStyle(
                    color: OpsColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.sensorId} - ${row.timestamp}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: OpsColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            row.value.toStringAsFixed(2),
            style: const TextStyle(
              color: OpsColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
