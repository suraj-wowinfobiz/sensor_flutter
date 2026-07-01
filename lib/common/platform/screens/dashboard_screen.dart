import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../../../shared/widgets/universal_table.dart';
import '../providers/super_admin_api_riverpod_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';
import '../services/analytics_sse_service.dart';
import '../services/generic_sse_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final bool embeddedScroll;
  final String pageTitle;
  final String pageSubtitle;

  const DashboardScreen({
    super.key,
    this.embeddedScroll = false,
    this.pageTitle = 'Dashboard',
    this.pageSubtitle = 'Platform-wide monitoring and configuration.',
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final AnalyticsSseService _analyticsSseService = AnalyticsSseService();
  final GenericSseService _rawSseService =
      GenericSseService('/api/v1/ingestion/readings/live');
  final GenericSseService _processedSseService =
      GenericSseService('/api/v1/processing/readings/live');
  final List<FlSpot> _rawXData = [];
  final List<FlSpot> _rawYData = [];
  final List<FlSpot> _rawZData = [];
  final List<FlSpot> _processedXData = [];
  final List<FlSpot> _processedYData = [];
  final List<FlSpot> _processedZData = [];
  final List<FlSpot> _processedMagnitudeData = [];
  final List<FlSpot> _processedVibrationData = [];
  final List<FlSpot> _processedMotionData = [];
  final List<FlSpot> _analyzedXData = [];
  final List<FlSpot> _analyzedYData = [];
  final List<FlSpot> _analyzedZData = [];
  final List<FlSpot> _analyzedRollData = [];
  final List<FlSpot> _analyzedPitchData = [];
  final List<FlSpot> _analyzedTiltData = [];
  final List<FlSpot> _analyzedAngularVelocityData = [];
  final List<FlSpot> _analyzedAccelerationData = [];
  final List<FlSpot> _processedAngularVelocityData = [];
  final List<FlSpot> _processedAccelerationData = [];
  final List<_ProcessedReadingSnapshot> _processedSnapshots = [];
  final Set<String> _processedSensorIds = <String>{};
  int _rawIndex = 0;
  int _processedIndex = 0;
  int _analyzedIndex = 0;
  double? _previousAnalyzedTilt;
  double? _previousAnalyzedTimestamp;
  double? _previousAnalyzedAngularVelocity;
  double? _previousProcessedTilt;
  double? _previousProcessedTimestampSec;
  double? _previousProcessedAngularVelocity;
  StreamSubscription? _analyticsSubscription;
  StreamSubscription? _rawSubscription;
  StreamSubscription? _processedSubscription;

  @override
  void initState() {
    super.initState();
    _connectToStreams();
    Future.microtask(_primeDashboardData);
  }

  void _connectToStreams() async {
    await _analyticsSseService.connect();
    _analyticsSubscription = _analyticsSseService.stream.listen((data) {
      if (!mounted) return;
      final detail = _extractAnalyzedDetailFromPayload(data);
      if (detail == null) return;
      final roll = detail.roll ?? 0.0;
      final pitch = detail.pitch ?? 0.0;
      final tilt = detail.tilt ?? sqrt((roll * roll) + (pitch * pitch));
      final dtRaw = (_previousAnalyzedTimestamp == null)
          ? null
          : (detail.streamTimestamp - _previousAnalyzedTimestamp!);
      final dt = _deltaSeconds(dtRaw);
      final angularVelocity =
          (_previousAnalyzedTilt == null || dt == null || dt <= 0)
              ? 0.0
              : (tilt - _previousAnalyzedTilt!) / dt;
      final angularAcceleration =
          (_previousAnalyzedAngularVelocity == null || dt == null || dt <= 0)
              ? 0.0
              : (angularVelocity - _previousAnalyzedAngularVelocity!) / dt;
      setState(() {
        _appendAnalyzedPoint(_analyzedXData, detail.x);
        _appendAnalyzedPoint(_analyzedYData, detail.y);
        _appendAnalyzedPoint(_analyzedZData, detail.z);
        _appendAnalyzedPoint(_analyzedRollData, roll);
        _appendAnalyzedPoint(_analyzedPitchData, pitch);
        _appendAnalyzedPoint(_analyzedTiltData, tilt);
        _appendAnalyzedPoint(_analyzedAngularVelocityData, angularVelocity);
        _appendAnalyzedPoint(_analyzedAccelerationData, angularAcceleration);
        _analyzedIndex++;
        _trimAndReindexAnalyzedSeries();
        _previousAnalyzedTilt = tilt;
        _previousAnalyzedTimestamp = detail.streamTimestamp;
        _previousAnalyzedAngularVelocity = angularVelocity;
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
      final snapshot = _extractProcessedSnapshot(data);
      if (snapshot == null) return;
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final dt = (_previousProcessedTimestampSec == null)
          ? null
          : nowSec - _previousProcessedTimestampSec!;
      final angularVelocity =
          (_previousProcessedTilt == null || dt == null || dt <= 0)
              ? 0.0
              : (snapshot.tilt - _previousProcessedTilt!) / dt;
      final angularAcceleration =
          (_previousProcessedAngularVelocity == null || dt == null || dt <= 0)
              ? 0.0
              : (angularVelocity - _previousProcessedAngularVelocity!) / dt;
      setState(() {
        _appendProcessedPoint(_processedXData, snapshot.roll);
        _appendProcessedPoint(_processedYData, snapshot.pitch);
        _appendProcessedPoint(_processedZData, snapshot.tilt);
        _appendProcessedPoint(_processedMagnitudeData, snapshot.magnitude);
        _appendProcessedPoint(_processedAngularVelocityData, angularVelocity);
        _appendProcessedPoint(_processedAccelerationData, angularAcceleration);
        if (snapshot.vibrationRms != null) {
          _appendProcessedPoint(
              _processedVibrationData, snapshot.vibrationRms!);
        }
        _appendProcessedPoint(
          _processedMotionData,
          snapshot.motionDetected ? 1 : 0,
        );
        _processedIndex++;
        _processedSnapshots.add(snapshot);
        _processedSensorIds.add(snapshot.sensorId);
        _trimAndReindexProcessedSeries();
        _previousProcessedTilt = snapshot.tilt;
        _previousProcessedTimestampSec = nowSec;
        _previousProcessedAngularVelocity = angularVelocity;
      });
    });
  }

  Future<void> _primeDashboardData() async {
    final db = ref.read(superAdminBackendChangeNotifierProvider);
    try {
      await Future.wait([
        db.loadOrganizations(),
        db.loadSites(),
        db.loadDevices(),
        db.loadSensors(),
        db.loadUsers(),
      ]);
      final siteIds = db.sites.map((site) => site.id).toList(growable: false);
      await Future.wait(siteIds.map((siteId) => db.loadZones(siteId)));
    } catch (_) {
      // Best-effort preload for dashboard tables.
    }
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
    _trimSeries(_analyzedXData, 65);
    _trimSeries(_analyzedYData, 65);
    _trimSeries(_analyzedZData, 65);
    _trimSeries(_analyzedRollData, 65);
    _trimSeries(_analyzedPitchData, 65);
    _trimSeries(_analyzedTiltData, 65);
    _trimSeries(_analyzedAngularVelocityData, 65);
    _trimSeries(_analyzedAccelerationData, 65);
  }

  void _trimAndReindexRawSeries() {
    _trimSeries(_rawXData, 65);
    _trimSeries(_rawYData, 65);
    _trimSeries(_rawZData, 65);
  }

  void _trimAndReindexProcessedSeries() {
    _trimSeries(_processedXData, 65);
    _trimSeries(_processedYData, 65);
    _trimSeries(_processedZData, 65);
    _trimSeries(_processedMagnitudeData, 65);
    _trimSeries(_processedAngularVelocityData, 65);
    _trimSeries(_processedAccelerationData, 65);
    _trimSeries(_processedVibrationData, 65);
    _trimSeries(_processedMotionData, 65);
    _trimList(_processedSnapshots, 120);
  }

  void _trimSeries(List<FlSpot> series, int maxPoints) {
    final overflow = series.length - maxPoints;
    if (overflow > 0) {
      series.removeRange(0, overflow);
    }
  }

  void _trimList<T>(List<T> values, int maxItems) {
    final overflow = values.length - maxItems;
    if (overflow > 0) {
      values.removeRange(0, overflow);
    }
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

  double? _extractProcessedMagnitude(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final processedPayload = map['processedPayload'];
      if (processedPayload is Map) {
        final horizontal = _toDouble(processedPayload['horizontalMagnitude']);
        if (horizontal != null) return horizontal;

        final x = _toDouble(processedPayload['x']);
        final y = _toDouble(processedPayload['y']);
        final z = _toDouble(processedPayload['z']);
        if (x != null && y != null && z != null) {
          return sqrt((x * x) + (y * y) + (z * z));
        }
      }

      final rawPayload = map['rawPayload'];
      if (rawPayload is Map) {
        final params = rawPayload['parameters'];
        if (params is Map) {
          final x = _toDouble(params['x']);
          final y = _toDouble(params['y']);
          final z = _toDouble(params['z']);
          if (x != null && y != null && z != null) {
            return sqrt((x * x) + (y * y) + (z * z));
          }
        }
      }
    }
    return null;
  }

  _ProcessedReadingSnapshot? _extractProcessedSnapshot(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final processedPayload = map['processedPayload'];
      if (processedPayload is! Map) continue;

      final roll = _toDouble(processedPayload['rollDegrees']) ??
          _toDouble(processedPayload['x']);
      final pitch = _toDouble(processedPayload['pitchDegrees']) ??
          _toDouble(processedPayload['y']);
      final tilt = _toDouble(processedPayload['tiltFromVerticalDegrees']) ??
          _toDouble(processedPayload['z']);
      if (roll == null || pitch == null || tilt == null) continue;

      final magnitude = _toDouble(processedPayload['horizontalMagnitude']) ??
          _extractProcessedMagnitude(map) ??
          sqrt((roll * roll) + (pitch * pitch) + (tilt * tilt));

      final rawPayload = map['rawPayload'];
      final rawParams = rawPayload is Map ? rawPayload['parameters'] : null;
      final vibrationRms =
          rawParams is Map ? _toDouble(rawParams['vibRMS']) : null;
      final motionDetected = _toBoolOrNumberTrue(
            rawParams is Map ? rawParams['motionDetected'] : null,
          ) ??
          _toBoolOrNumberTrue(processedPayload['motionDetected']) ??
          false;

      final rawSensorId = map['sensorId'] ??
          (rawPayload is Map ? rawPayload['sensorId'] : null);
      final sensorId = (rawSensorId ?? 'unknown').toString();
      return _ProcessedReadingSnapshot(
        sensorId: sensorId,
        roll: roll,
        pitch: pitch,
        tilt: tilt,
        magnitude: magnitude,
        vibrationRms: vibrationRms,
        motionDetected: motionDetected,
        receivedAt: DateTime.now(),
      );
    }
    return null;
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

  _AnalyzedDetailSnapshot? _extractAnalyzedDetailFromPayload(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final detail = _extractAnalyzedDetailFromEvent(map);
      if (detail != null) return detail;
    }
    return null;
  }

  _AnalyzedDetailSnapshot? _extractAnalyzedDetailFromEvent(
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

    final evaluations = event['evaluations'];
    if (evaluations is List) {
      for (final item in evaluations) {
        if (item is! Map) continue;
        final name = item['parameterName']?.toString();
        final value = _toDouble(item['value']);
        if (name == null || value == null) continue;
        values[name] = value;
      }
    }

    final roll = values['rollDegrees'] ?? values['roll'];
    final pitch = values['pitchDegrees'] ?? values['pitch'];
    final tilt =
        values['tiltFromVerticalDegrees'] ?? values['inclinationDegrees'];
    final horizontalMagnitude = values['horizontalMagnitude'] ??
        values['accelerationMagnitude'] ??
        values['vibration.vibrationRms'];

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

    final sensorId = (event['sensorId'] ?? '').toString();
    final readingId = (event['readingId'] ?? '').toString();
    final alertCount = (event['alertCount'] as num?)?.toInt() ?? 0;
    final timestampValue = _toDouble(event['timestamp']) ?? 0;

    return _AnalyzedDetailSnapshot(
      sensorId: sensorId,
      readingId: readingId,
      x: x,
      y: y,
      z: z,
      roll: roll,
      pitch: pitch,
      tilt: tilt,
      horizontalMagnitude: horizontalMagnitude,
      alertCount: alertCount,
      streamTimestamp: timestampValue,
    );
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

  double? _deltaSeconds(double? rawDelta) {
    if (rawDelta == null || rawDelta <= 0) return null;
    if (rawDelta > 1000) return rawDelta / 1000.0;
    return rawDelta;
  }

  String _agoLabel(DateTime? when) {
    if (when == null) return 'No updates';
    final seconds = DateTime.now().difference(when).inSeconds;
    if (seconds < 5) return 'Just now';
    if (seconds < 60) return '${seconds}s ago';
    final minutes = seconds ~/ 60;
    return '${minutes}m ago';
  }

  String _shortDate(DateTime? when) {
    if (when == null) return '--';
    final yyyy = when.year.toString().padLeft(4, '0');
    final mm = when.month.toString().padLeft(2, '0');
    final dd = when.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final statsApi = ref.watch(superAdminDashboardStatsApiProvider).valueOrNull;
    final organizationsCount = (db.organizations as List).length;
    final sitesCount = (db.sites as List).length;
    final zonesCount = (db.zones as List).length;
    final devicesCount = (db.devices as List).length;
    final usersCount = (db.users as List).length;
    final sensorsCount = (db.sensors as List).length;
    final onlineDevicesCount = (db.devices as List).where((item) {
      final status = (item.status as String).trim().toLowerCase();
      return status == 'active' ||
          status == 'online' ||
          status == 'healthy' ||
          status == 'running';
    }).length;
    final activeAlerts = (statsApi?['activeAlerts'] as num?)?.toInt() ??
        db.getActiveAlerts().length;
    final criticalAlerts = (db.alerts as List)
        .where((item) => item.resolvedAt == null)
        .where((item) {
      final level = (item.alertLevel as String).trim().toLowerCase();
      return level.contains('critical') || level.contains('high');
    }).length;
    final platformUpdateAt = _latestPlatformUpdateAt(db) ?? DateTime.now();
    final usersSeries = _dailySpotsFromDates(
      (db.users as List).map((item) => item.createdAt as DateTime),
      days: 30,
    );
    final sensorsSeries = _dailySpotsFromDates(
      (db.sensors as List).map((item) => item.installedAt as DateTime),
      days: 30,
    );
    final openAlerts = (db.alerts as List)
        .where((item) => item.resolvedAt == null)
        .toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    final warningAlerts = openAlerts.where((item) {
      final level = item.alertLevel.trim().toLowerCase();
      return level.contains('warning') || level.contains('warn');
    }).length;
    final infoAlerts = openAlerts.length - criticalAlerts - warningAlerts;
    final content = OpsPage(
      title: widget.pageTitle,
      subtitle: widget.pageSubtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(
            '${platformUpdateAt.day.toString().padLeft(2, '0')}/'
            '${platformUpdateAt.month.toString().padLeft(2, '0')}/'
            '${platformUpdateAt.year}',
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export Overview'),
        ),
      ],
      child: Column(
        children: [
          OpsKpiGrid(
            maxColumns: 6,
            minCardWidth: 145,
            cardHeight: 132,
            cards: [
              OpsKpiCard(
                label: 'Organizations',
                value: '$organizationsCount',
                helper: 'Platform-wide organization count',
                icon: Icons.business_outlined,
              ),
              OpsKpiCard(
                label: 'Users',
                value: '$usersCount',
                helper: 'Accounts on the platform',
                icon: Icons.people_outline_rounded,
                color: OpsColors.success,
              ),
              OpsKpiCard(
                label: 'Devices',
                value: '$devicesCount',
                helper: 'Connected platform devices',
                icon: Icons.devices_other_outlined,
                color: OpsColors.warning,
              ),
              OpsKpiCard(
                label: 'Sites',
                value: '$sitesCount',
                helper: 'Managed locations',
                icon: Icons.location_city_outlined,
              ),
              OpsKpiCard(
                label: 'Sensors',
                value: '$sensorsCount',
                helper: 'Sensors visible on the platform',
                icon: Icons.sensors_outlined,
                color: OpsColors.primaryContainer,
              ),
              OpsKpiCard(
                label: 'Active Alerts',
                value: '$activeAlerts',
                helper: '$criticalAlerts critical • $zonesCount zones',
                icon: Icons.warning_amber_rounded,
                color: OpsColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth <= 900;
              final left = OpsPanel(
                title: 'Platform Status',
                padding: const EdgeInsets.all(24),
                child: _AdminStatusDonut(
                  online: onlineDevicesCount,
                  warning: criticalAlerts + warningAlerts,
                  offline: (devicesCount - onlineDevicesCount).clamp(0, 99999),
                ),
              );
              final center = OpsPanel(
                title: 'Alerts Summary',
                subtitle: 'Current unresolved load',
                padding: const EdgeInsets.all(24),
                child: _AdminAlertSummary(
                  critical: criticalAlerts,
                  warning: warningAlerts,
                  info: infoAlerts < 0 ? 0 : infoAlerts,
                  total: openAlerts.length,
                ),
              );
              final right = OpsPanel(
                title: 'Live Feed',
                trailing: const _AdminActiveBadge(),
                padding: const EdgeInsets.all(24),
                child: _AdminLiveFeed(alerts: openAlerts),
              );

              if (vertical) {
                return Column(
                  children: [
                    left,
                    const SizedBox(height: 12),
                    center,
                    const SizedBox(height: 12),
                    right,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 12),
                    Expanded(child: center),
                    const SizedBox(width: 12),
                    Expanded(child: right),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth <= 980;
              final overview = OpsFramedPanel(
                header: const _AdminOverviewHeader(),
                child: _AdminOverviewTable(db: db),
              );
              final trend = OpsPanel(
                title: 'Platform Growth Trend',
                padding: const EdgeInsets.all(24),
                child: _AdminHealthTrend(
                  firstLabel: 'Users',
                  secondLabel: 'Sensors',
                  firstValues: _seriesPercentages(usersSeries),
                  secondValues: _seriesPercentages(sensorsSeries),
                  bottomLabels: _dayLabels(7),
                ),
              );

              if (stacked) {
                return Column(
                  children: [
                    overview,
                    const SizedBox(height: 16),
                    trend,
                  ],
                );
              }

              return const SizedBox();
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 980) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 396,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: OpsFramedPanel(
                        header: const _AdminOverviewHeader(),
                        child: _AdminOverviewTable(db: db),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: OpsPanel(
                        title: 'Platform Growth Trend',
                        padding: const EdgeInsets.all(24),
                        child: _AdminHealthTrend(
                          firstLabel: 'Users',
                          secondLabel: 'Sensors',
                          firstValues: _seriesPercentages(usersSeries),
                          secondValues: _seriesPercentages(sensorsSeries),
                          bottomLabels: _dayLabels(7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const _AdminDashboardFooter(),
          const SizedBox(height: 20),
          _buildTwoColumnRow(
            context,
            left: _buildAnalyzedRow(context),
            right: _buildVelocityCard(context),
          ),
          const SizedBox(height: 16),
          _buildTwoColumnRow(
            context,
            left: _statusDistributionCard(context, db),
            right: _tiltPatternCard(context),
          ),
          const SizedBox(height: 16),
          _buildTwoColumnRow(
            context,
            left: _alertMappingCoverageCard(context, db),
            right: _buildScatterCard(context),
          ),
          const SizedBox(height: 16),
          _buildTwoColumnRow(
            context,
            left: _buildSensorReadingsCard(context),
            right: _buildTopTiltSensorsCard(context, db),
          ),
          const SizedBox(height: 16),
          _buildBottomLiveStats(context, db),
        ],
      ),
    );

    if (widget.embeddedScroll) return content;

    return content;
  }

  List<double> _seriesPercentages(List<FlSpot> spots) {
    if (spots.isEmpty) return const [0, 0, 0, 0, 0, 0, 0];
    final values = spots.map((spot) => spot.y).toList();
    final maxValue = values.reduce(max);
    if (maxValue <= 0) {
      return List<double>.filled(values.length.clamp(0, 7), 0);
    }
    final normalized = values.map((value) => (value / maxValue) * 100).toList();
    if (normalized.length <= 7) return normalized;
    return normalized.sublist(normalized.length - 7);
  }

  Widget _buildTwoColumnRow(
    BuildContext context, {
    required Widget left,
    required Widget right,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 980) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          ),
        );
      },
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
    String yAxisLabel = 'Value',
    String xAxisLabel = 'Sample',
    List<String>? xTickLabels,
  }) {
    final allSpots = [...xData, ...yData, ...zData];
    final hasData = allSpots.isNotEmpty;
    final minY = hasData ? allSpots.map((e) => e.y).reduce(min) - 1 : 0.0;
    final maxY = hasData ? allSpots.map((e) => e.y).reduce(max) + 1 : 10.0;
    final safeXData = xData.isEmpty ? const [FlSpot(0, 0)] : xData;
    final safeYData = yData.isEmpty ? const [FlSpot(0, 0)] : yData;
    final safeZData = zData.isEmpty ? const [FlSpot(0, 0)] : zData;
    final hasTickLabels = xTickLabels != null && xTickLabels.isNotEmpty;
    final minX = hasTickLabels
        ? 0.0
        : (hasData ? allSpots.map((e) => e.x).reduce(min) : 0.0);
    final maxX = hasTickLabels
        ? (xTickLabels!.length - 1).toDouble()
        : (hasData ? allSpots.map((e) => e.x).reduce(max) : 65.0);

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
                    axisNameWidget: Text(
                      yAxisLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _mutedTextColor(context),
                      ),
                    ),
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
                    axisNameWidget: Text(
                      xAxisLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _mutedTextColor(context),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: hasTickLabels ? 32 : 24,
                      interval: hasTickLabels ? 1 : 10,
                      getTitlesWidget: (value, _) {
                        if (hasTickLabels) {
                          final index = value.round();
                          if (index < 0 ||
                              index >= (xTickLabels?.length ?? 0)) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            xTickLabels![index],
                            style: TextStyle(
                              fontSize: 10,
                              color: _mutedTextColor(context),
                            ),
                          );
                        }
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _mutedTextColor(context),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: safeXData,
                    isCurved: true,
                    color: const Color(0xFF2E8BFF),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: safeYData,
                    isCurved: true,
                    color: const Color(0xFF11A95D),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: safeZData,
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
    BuildContext context, {
    required int organizationsCount,
    required int activeOrganizationsCount,
    required int sitesCount,
    required int devicesCount,
    required int onlineDevicesCount,
    required int activeAlerts,
    required int criticalAlerts,
    required DateTime? platformUpdateAt,
  }) {
    final mappingHealth =
        devicesCount == 0 ? 100.0 : (onlineDevicesCount / devicesCount) * 100;
    final cards = [
      _MetricData(
        title: 'ORGANIZATIONS',
        value: organizationsCount.toString(),
        subtitle: '$activeOrganizationsCount active',
        icon: Icons.business,
        tint: const Color(0xFF5973d8),
        isHighlight: false,
      ),
      _MetricData(
        title: 'SITES',
        value: sitesCount.toString(),
        subtitle: 'Platform-wide site inventory',
        icon: Icons.location_on_outlined,
        tint: const Color(0xFFd29a00),
      ),
      _MetricData(
        title: 'DEVICE AVAILABILITY',
        value: '${mappingHealth.toStringAsFixed(0)}%',
        subtitle: '$onlineDevicesCount of $devicesCount online',
        icon: Icons.devices_other_outlined,
        tint: const Color(0xFF0ea65b),
      ),
      _MetricData(
        title: 'ACTIVE ALERTS',
        value: activeAlerts.toString(),
        subtitle:
            '$criticalAlerts critical/high • ${_agoLabel(platformUpdateAt)}',
        icon: Icons.notifications_none,
        tint: const Color(0xFF5973d8),
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

  Widget _buildKinematicsRow(BuildContext context) {
    return _buildVelocityCard(context);
  }

  Widget _buildAnalyzedRow(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final deviceSpots = _dailySpotsFromDates(
      (db.devices as List).map((item) => item.installedAt as DateTime),
      days: 30,
    );
    final sensorSpots = _dailySpotsFromDates(
      (db.sensors as List).map((item) => item.installedAt as DateTime),
      days: 30,
    );
    final siteSpots = _dailySpotsFromDates(
      (db.sites as List).map((item) => item.createdAt as DateTime),
      days: 30,
    );
    return _buildLiveSeriesCard(
      context,
      title: 'Asset Onboarding Trend',
      icon: Icons.psychology_alt_outlined,
      xData: deviceSpots,
      yData: sensorSpots,
      zData: siteSpots,
      xLabel: 'Devices',
      yLabel: 'Sensors',
      zLabel: 'Sites',
      yAxisLabel: 'Assets per day',
      xAxisLabel: 'Last 30 days',
      xTickLabels: _dayLabels(30),
    );
  }

  Widget _buildVelocityCard(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final activeSpots = _dailySpotsFromDates(
      (db.alerts as List)
          .where((item) => item.resolvedAt == null)
          .map((item) => item.triggeredAt as DateTime),
      days: 14,
    );
    final criticalSpots = _dailySpotsFromDates(
      (db.alerts as List).where((item) {
        final level = (item.alertLevel as String).trim().toLowerCase();
        return level.contains('critical') || level.contains('high');
      }).map((item) => item.triggeredAt as DateTime),
      days: 14,
    );
    final all = [...activeSpots, ...criticalSpots];
    final hasData = all.isNotEmpty;
    final minY = hasData ? 0.0 : 0.0;
    final maxY = hasData ? max(1.0, all.map((e) => e.y).reduce(max) + 1) : 1.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Alert Momentum', Icons.speed_outlined),
          const SizedBox(height: 8),
          Text(
            'Daily active vs critical/high alert load across the platform.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
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
                      extraLinesData: const ExtraLinesData(horizontalLines: []),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Alerts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _mutedTextColor(context),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) => Text(
                              value.toStringAsFixed(2),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _mutedTextColor(context)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Day index',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _mutedTextColor(context),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 10,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _mutedTextColor(context)),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: activeSpots,
                          isCurved: true,
                          color: const Color(0xFF0f9ca0),
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: criticalSpots,
                          isCurved: true,
                          color: const Color(0xFFF59E0B),
                          barWidth: 2.0,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No alert trend data yet.',
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(color: Color(0xFF0f9ca0), label: 'Active alerts'),
              _LegendItem(color: Color(0xFFF59E0B), label: 'Critical/high'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccelerationTrendCard(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final userSpots = _dailySpotsFromDates(
      (db.users as List).map((item) => item.createdAt as DateTime),
      days: 14,
    );
    final orgSpots = _dailySpotsFromDates(
      (db.organizations as List).map((item) => item.createdAt as DateTime),
      days: 14,
    );
    final all = [...userSpots, ...orgSpots];
    final hasData = all.isNotEmpty;
    final maxY = hasData ? max(1.0, all.map((e) => e.y).reduce(max) + 1) : 1.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Onboarding Momentum',
            Icons.timelapse_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'Daily onboarding activity for users and organizations.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
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
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 0,
                            color: const Color(0xFF6b7280),
                            strokeWidth: 1,
                            dashArray: [6, 4],
                          ),
                        ],
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
                            'Created records',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _mutedTextColor(context),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, _) => Text(
                              value.toStringAsFixed(3),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _mutedTextColor(context)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Day index',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _mutedTextColor(context),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 10,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _mutedTextColor(context)),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: userSpots,
                          isCurved: true,
                          color: const Color(0xFF7C3AED),
                          barWidth: 2.4,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: orgSpots,
                          isCurved: true,
                          color: const Color(0xFFEF4444),
                          barWidth: 2.0,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No onboarding activity yet.',
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(color: Color(0xFF7C3AED), label: 'New users'),
              _LegendItem(color: Color(0xFFEF4444), label: 'New orgs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context, dynamic db) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 1050;
        if (!twoCols) {
          return Column(
            children: [
              _statusDistributionCard(context, db),
              const SizedBox(height: 16),
              _tiltPatternCard(context),
              const SizedBox(height: 16),
              _alertMappingCoverageCard(context, db),
            ],
          );
        }
        return Column(
          children: [
            _statusDistributionCard(context, db),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _tiltPatternCard(context)),
                const SizedBox(width: 16),
                Expanded(child: _alertMappingCoverageCard(context, db)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statusDistributionCard(BuildContext context, dynamic db) {
    int admins = 0;
    int engineers = 0;
    int vendors = 0;
    int users = 0;
    for (final item in db.users as List) {
      final role = (item.role as String).trim().toLowerCase();
      if (role.contains('admin')) {
        admins++;
      } else if (role.contains('engineer')) {
        engineers++;
      } else if (role.contains('vendor')) {
        vendors++;
      } else {
        users++;
      }
    }
    if ((db.users as List).isEmpty) {
      users = 1;
    }

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'User Role Distribution', Icons.memory_outlined),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: admins.toDouble(),
                    color: const Color(0xFF0ca15f),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: engineers.toDouble(),
                    color: const Color(0xFFd39a00),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: vendors.toDouble(),
                    color: const Color(0xFFea3e43),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: users.toDouble(),
                    color: const Color(0xFF2E8BFF),
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
              _LegendItem(color: Color(0xFF0ca15f), label: 'Admins'),
              _LegendItem(color: Color(0xFFd39a00), label: 'Engineers'),
              _LegendItem(color: Color(0xFFea3e43), label: 'Vendors'),
              _LegendItem(color: Color(0xFF2E8BFF), label: 'Users'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiltPatternCard(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final orgAlerts = _organizationAlertCounts(db);
    final names = orgAlerts.keys.toList();
    final values = orgAlerts.values.toList();
    final maxAlerts = values.isEmpty
        ? 1.0
        : max<double>(1.0, values.reduce(max).toDouble() + 1);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Alerts Per Organization', Icons.show_chart),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxAlerts,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxAlerts / 4).clamp(1, 10.0),
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
                    axisNameWidget: Text(
                      'Active alerts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Organizations',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        () {
                          final index = value.toInt();
                          if (index < 0 || index >= names.length) return '';
                          final name = names[index];
                          return name.length > 6
                              ? '${name.substring(0, 6)}…'
                              : name;
                        }(),
                        style: TextStyle(
                            fontSize: 10, color: _mutedTextColor(context)),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(values.length, (i) {
                  final value = values[i].toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 14,
                        color: value >= 5
                            ? const Color(0xFFea3e43)
                            : value >= 2
                                ? const Color(0xFFd39a00)
                                : const Color(0xFF0f8b89),
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

  Widget _alertMappingCoverageCard(BuildContext context, dynamic db) {
    final activeAlerts = (db.alerts as List)
        .where((item) => item.resolvedAt == null)
        .toList(growable: false);
    final totalAlerts = activeAlerts.length;
    final sensorById = <String, dynamic>{
      for (final sensor in db.sensors as List)
        (sensor.id as String).trim(): sensor,
    };
    final deviceById = <String, dynamic>{
      for (final device in db.devices as List)
        (device.id as String).trim(): device,
    };
    final siteById = <String, dynamic>{
      for (final site in db.sites as List) (site.id as String).trim(): site,
    };
    final organizationById = <String, dynamic>{
      for (final organization in db.organizations as List)
        (organization.id as String).trim(): organization,
    };

    var sensorMapped = 0;
    var deviceMapped = 0;
    var siteMapped = 0;
    var organizationMapped = 0;
    for (final alert in activeAlerts) {
      final sensor = sensorById[(alert.sensorId as String).trim()];
      if (sensor == null) continue;
      sensorMapped++;

      final device = deviceById[(sensor.deviceId as String).trim()];
      if (device == null) continue;
      deviceMapped++;

      final site = siteById[(device.siteId as String).trim()];
      if (site == null) continue;
      siteMapped++;

      final organization =
          organizationById[(site.organizationId as String).trim()];
      if (organization == null) continue;
      organizationMapped++;
    }

    final unmappedAlerts = totalAlerts - organizationMapped;
    final bars = <({String label, int value, int total})>[
      (label: 'Open Alerts', value: totalAlerts, total: max(1, totalAlerts)),
      (label: 'Sensor Linked', value: sensorMapped, total: max(1, totalAlerts)),
      (label: 'Device Linked', value: deviceMapped, total: max(1, totalAlerts)),
      (label: 'Site Linked', value: siteMapped, total: max(1, totalAlerts)),
      (
        label: 'Organization Linked',
        value: organizationMapped,
        total: max(1, totalAlerts),
      ),
      (
        label: 'Unmapped Alerts',
        value: unmappedAlerts.clamp(0, totalAlerts),
        total: max(1, totalAlerts),
      ),
    ];
    final maxBar = max<double>(
        1.0, bars.map((item) => item.value.toDouble()).reduce(max) + 1);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Alert Mapping Coverage', Icons.warning_amber_rounded),
          const SizedBox(height: 6),
          Text(
            'Coverage of active alerts mapped across sensor, device, site, and organization hierarchy.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxBar,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxBar / 5).clamp(0.5, 20.0),
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
                    axisNameWidget: Text(
                      'Count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Alert traceability',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Transform.rotate(
                        angle: -0.7,
                        child: Text(
                          () {
                            final i = value.toInt();
                            if (i < 0 || i >= bars.length) return '--';
                            final label = bars[i].label;
                            return label.length > 8
                                ? '${label.substring(0, 8)}…'
                                : label;
                          }(),
                          style: TextStyle(
                              fontSize: 10, color: _mutedTextColor(context)),
                        ),
                      ),
                    ),
                  ),
                ),
                extraLinesData: const ExtraLinesData(horizontalLines: []),
                barGroups: List.generate(bars.length, (i) {
                  final value = bars[i].value.toDouble();
                  final ratio =
                      bars[i].total == 0 ? 0.0 : value / bars[i].total;
                  final color = ratio < 0.5
                      ? const Color(0xFFea3e43)
                      : ratio < 0.85
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
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final points = <ScatterSpot>[];
    final siteCounts = <String, int>{};
    final deviceCounts = <String, int>{};
    for (final site in db.sites as List) {
      final orgId = (site.organizationId as String).trim();
      if (orgId.isEmpty) continue;
      siteCounts[orgId] = (siteCounts[orgId] ?? 0) + 1;
    }
    for (final device in db.devices as List) {
      final site = (db.sites as List)
          .where((item) =>
              (item.id as String).trim() == (device.siteId as String).trim())
          .firstOrNull;
      final orgId = site == null ? '' : (site.organizationId as String).trim();
      if (orgId.isEmpty) continue;
      deviceCounts[orgId] = (deviceCounts[orgId] ?? 0) + 1;
    }
    for (final organization in db.organizations as List) {
      final orgId = (organization.id as String).trim();
      points.add(
        ScatterSpot(
          (siteCounts[orgId] ?? 0).toDouble(),
          (deviceCounts[orgId] ?? 0).toDouble(),
          dotPainter: FlDotCirclePainter(
            radius: 4,
            color: const Color(0xFF2d8f93),
          ),
        ),
      );
    }

    final hasPoints = points.isNotEmpty;
    final minX = hasPoints ? points.map((p) => p.x).reduce(min) - 0.2 : -1.0;
    final maxX = hasPoints ? points.map((p) => p.x).reduce(max) + 0.2 : 1.0;
    final minY = hasPoints ? points.map((p) => p.y).reduce(min) - 0.2 : -1.0;
    final maxY = hasPoints ? points.map((p) => p.y).reduce(max) + 0.2 : 1.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Organization Site/Device Correlation',
              Icons.multiline_chart),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ScatterChart(
              ScatterChartData(
                minX: minX,
                maxX: max(maxX, minX + 0.5),
                minY: minY,
                maxY: max(maxY, minY + 0.5),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0), strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      const FlLine(color: Color(0xFFd2dbe0), strokeWidth: 1),
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
                      'Devices',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
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
                    axisNameWidget: const Text(
                      'Sites',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: _mutedTextColor(context),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                scatterSpots: points,
                showingTooltipIndicators: const [],
              ),
            ),
          ),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No organization distribution data available.',
                style: TextStyle(color: _mutedTextColor(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorReadingsCard(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final sensors = List.of(db.sensors as List);
    final devices = List.of(db.devices as List);
    final sites = List.of(db.sites as List);
    final zones = List.of(db.zones as List);
    final organizations = List.of(db.organizations as List);
    final rows = <List<String>>[];
    for (final device in devices) {
      final site = sites
          .where((item) =>
              (item.id as String).trim() == (device.siteId as String).trim())
          .firstOrNull;
      final zone = zones
          .where((item) =>
              (item.id as String).trim() == (device.zoneId as String).trim())
          .firstOrNull;
      final organization = site == null
          ? null
          : organizations
              .where((item) =>
                  (item.id as String).trim() ==
                  (site.organizationId as String).trim())
              .firstOrNull;
      rows.add([
        'Device',
        (device.deviceCode as String?)?.trim().isNotEmpty == true
            ? device.deviceCode as String
            : (device.serialNumber as String? ?? device.id as String),
        organization?.name ?? '--',
        site?.name ?? '--',
        zone?.name ?? '--',
        _shortDate(device.installedAt as DateTime?),
      ]);
    }
    for (final sensor in sensors) {
      final device = devices
          .where((item) =>
              (item.id as String).trim() == (sensor.deviceId as String).trim())
          .firstOrNull;
      final site = device == null
          ? null
          : sites
              .where((item) =>
                  (item.id as String).trim() ==
                  (device.siteId as String).trim())
              .firstOrNull;
      final zone = device == null
          ? null
          : zones
              .where((item) =>
                  (item.id as String).trim() ==
                  (device.zoneId as String).trim())
              .firstOrNull;
      final organization = site == null
          ? null
          : organizations
              .where((item) =>
                  (item.id as String).trim() ==
                  (site.organizationId as String).trim())
              .firstOrNull;
      rows.add([
        'Sensor',
        (sensor.serialNumber as String?)?.trim().isNotEmpty == true
            ? sensor.serialNumber as String
            : (sensor.id as String),
        organization?.name ?? '--',
        site?.name ?? '--',
        zone?.name ?? '--',
        _shortDate(sensor.installedAt as DateTime?),
      ]);
    }
    rows.sort((a, b) => b[5].compareTo(a[5]));
    final recentRows = rows.take(8).toList();

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
                'Recent Installations',
                Icons.inventory_2_outlined,
              ),
              _chip(context, 'Export', icon: Icons.upload_outlined),
            ],
          ),
          const SizedBox(height: 16),
          UniversalDataTable(
            minWidth: 900,
            columns: [
              _tableHeading(context, 'Type'),
              _tableHeading(context, 'Asset'),
              _tableHeading(context, 'Organization'),
              _tableHeading(context, 'Site'),
              _tableHeading(context, 'Zone'),
              _tableHeading(context, 'Installed'),
            ],
            rows: (recentRows.isEmpty
                    ? const [
                        ['--', '--', '--', '--', '--', '--']
                      ]
                    : recentRows)
                .map((r) {
              return DataRow(cells: [
                DataCell(UniversalTableText(r[0])),
                DataCell(UniversalTableText(r[1])),
                DataCell(UniversalTableText(r[2])),
                DataCell(UniversalTableText(r[3])),
                DataCell(UniversalTableText(r[4])),
                DataCell(UniversalTableText(r[5])),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  DataColumn _tableHeading(BuildContext context, String label) {
    return DataColumn(
      label: UniversalTableHeaderText(
        label.toUpperCase(),
      ),
    );
  }

  Widget _buildBottomLiveStats(BuildContext context, dynamic db) {
    final now = DateTime.now();
    final devicesLast30d = (db.devices as List)
        .where(
            (item) => now.difference(item.installedAt as DateTime).inDays <= 30)
        .length;
    final sensorsLast30d = (db.sensors as List)
        .where(
            (item) => now.difference(item.installedAt as DateTime).inDays <= 30)
        .length;
    final sitesLast30d = (db.sites as List)
        .where(
            (item) => now.difference(item.createdAt as DateTime).inDays <= 30)
        .length;
    final activeOrganizationsCount = (db.organizations as List)
        .where(
            (item) => (item.status as String).trim().toLowerCase() == 'active')
        .length;

    final cards = [
      _MiniStatData(
        title: 'ACTIVE ORGS',
        value: activeOrganizationsCount.toString(),
        unit: 'orgs',
        detail: 'of ${(db.organizations as List).length} total',
        badge: activeOrganizationsCount > 0 ? 'Live' : 'Idle',
        icon: Icons.business_outlined,
        iconColor: const Color(0xFF0aa34f),
      ),
      _MiniStatData(
        title: 'DEVICES INSTALLED',
        value: devicesLast30d.toString(),
        unit: 'last 30d',
        detail: '${(db.devices as List).length} total devices',
        badge: devicesLast30d > 0 ? 'Active' : 'Idle',
        icon: Icons.devices_other_outlined,
        iconColor: const Color(0xFF5f78de),
      ),
      _MiniStatData(
        title: 'SENSORS INSTALLED',
        value: sensorsLast30d.toString(),
        unit: 'last 30d',
        detail: '${(db.sensors as List).length} total sensors',
        badge: sensorsLast30d > 0 ? 'Active' : 'Idle',
        icon: Icons.sensors_outlined,
        iconColor: const Color(0xFFd39a00),
      ),
      _MiniStatData(
        title: 'SITES ADDED',
        value: sitesLast30d.toString(),
        unit: 'last 30d',
        detail: '${(db.sites as List).length} total sites',
        badge: sitesLast30d > 0 ? 'Active' : 'Idle',
        icon: Icons.location_on_outlined,
        iconColor: const Color(0xFF2b8ab8),
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
    final counts = _alertSeverityCounts(db);
    final labels = ['Critical/High', 'Warning', 'Info', 'Resolved'];
    final values = [
      counts.$1,
      counts.$2,
      counts.$3,
      counts.$4,
    ];
    final maxCount = values.reduce(max).clamp(1, 999);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Alert Severity Distribution',
            Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 10),
          Text(
            'Breakdown of platform alerts by current severity state.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          if ((db.alerts as List).isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No alert data available.',
                style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
              ),
            ),
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
                  final count = values[index];
                  final color = index <= 1
                      ? const Color(0xFFea3e43)
                      : index == 2
                          ? const Color(0xFF0ca15f)
                          : const Color(0xFF60717c);
                  final mildColor =
                      index == 1 ? const Color(0xFFd39a00) : color;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        width: 34,
                        color: mildColor,
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
    final orgAlertMap = _organizationAlertCounts(db);
    final entries = orgAlertMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topOrgs = entries.take(5).toList();
    final maxAlerts = topOrgs.isEmpty
        ? 1.0
        : topOrgs.map((entry) => entry.value.toDouble()).reduce(max);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Top Organizations By Active Alerts',
            Icons.leaderboard_outlined,
          ),
          const SizedBox(height: 10),
          Text(
            'Organizations requiring immediate super-admin attention.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          if (topOrgs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No active organization alerts available.',
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
                  maxY: max(2.0, maxAlerts + 1),
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
                          if (index < 0 || index >= topOrgs.length) {
                            return const SizedBox.shrink();
                          }
                          final label = topOrgs[index].key;
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
                  barGroups: List.generate(topOrgs.length, (index) {
                    final value = topOrgs[index].value.toDouble();
                    final color = value >= 5
                        ? const Color(0xFFea3e43)
                        : value >= 2
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
    final bg = selected ? OpsColors.primary : OpsColors.surfaceLow;
    final fg = selected ? Colors.white : OpsColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: selected ? OpsColors.primary : OpsColors.border),
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

  DateTime? _latestPlatformUpdateAt(dynamic db) {
    final stamps = <DateTime>[
      ...(db.organizations as List).map((item) => item.createdAt as DateTime),
      ...(db.sites as List).map((item) => item.createdAt as DateTime),
      ...(db.users as List).map((item) => item.updatedAt as DateTime),
      ...(db.alerts as List).map((item) => item.triggeredAt as DateTime),
    ];
    if (stamps.isEmpty) return null;
    stamps.sort((a, b) => b.compareTo(a));
    return stamps.first;
  }

  List<String> _dayLabels(int days) {
    final now = DateTime.now();
    return List.generate(
      days,
      (index) {
        final day = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: days - 1 - index));
        final dd = day.day.toString().padLeft(2, '0');
        return dd;
      },
    );
  }

  List<FlSpot> _dailySpotsFromDates(
    Iterable<DateTime> dates, {
    required int days,
  }) {
    final now = DateTime.now();
    final buckets = <DateTime, int>{};
    for (var i = days - 1; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      buckets[day] = 0;
    }
    for (final date in dates) {
      final day = DateTime(date.year, date.month, date.day);
      if (buckets.containsKey(day)) {
        buckets[day] = (buckets[day] ?? 0) + 1;
      }
    }
    return List.generate(
      buckets.length,
      (index) =>
          FlSpot(index.toDouble(), buckets.values.elementAt(index).toDouble()),
    );
  }

  Map<String, int> _organizationAlertCounts(dynamic db) {
    final siteById = <String, dynamic>{
      for (final site in db.sites as List) (site.id as String).trim(): site,
    };
    final deviceById = <String, dynamic>{
      for (final device in db.devices as List)
        (device.id as String).trim(): device,
    };
    final sensorById = <String, dynamic>{
      for (final sensor in db.sensors as List)
        (sensor.id as String).trim(): sensor,
    };
    final orgById = <String, dynamic>{
      for (final org in db.organizations as List)
        (org.id as String).trim(): org,
    };

    final counts = <String, int>{};
    for (final alert in db.alerts as List) {
      if (alert.resolvedAt != null) continue;
      final sensor = sensorById[(alert.sensorId as String).trim()];
      final device = sensor == null
          ? null
          : deviceById[(sensor.deviceId as String).trim()];
      final site =
          device == null ? null : siteById[(device.siteId as String).trim()];
      final org =
          site == null ? null : orgById[(site.organizationId as String).trim()];
      final name = org == null ? 'Unknown' : (org.name as String);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in sorted) entry.key: entry.value};
  }

  (int, int, int, int) _alertSeverityCounts(dynamic db) {
    var critical = 0;
    var warning = 0;
    var info = 0;
    var resolved = 0;
    for (final alert in db.alerts as List) {
      if (alert.resolvedAt != null) {
        resolved++;
        continue;
      }
      final level = (alert.alertLevel as String).trim().toLowerCase();
      if (level.contains('critical') || level.contains('high')) {
        critical++;
      } else if (level.contains('warn')) {
        warning++;
      } else {
        info++;
      }
    }
    return (critical, warning, info, resolved);
  }

  double _radarScale(double? value, double maxAbs) {
    if (value == null || maxAbs <= 0) return 0;
    return ((value / maxAbs) * 100).clamp(0, 100);
  }

  Widget _valueChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFEAF0F4)
            : const Color(0xFF23394A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _titleColor(context),
        ),
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
}

class _AdminStatusDonut extends StatelessWidget {
  final int online;
  final int warning;
  final int offline;

  const _AdminStatusDonut({
    required this.online,
    required this.warning,
    required this.offline,
  });

  @override
  Widget build(BuildContext context) {
    final total = (online + warning + offline).clamp(1, 99999);
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _AdminDonutPainter(
                  online: online / total,
                  warning: warning / total,
                  offline: offline / total,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text('TOTAL', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        _legend('Online', online, total, OpsColors.success),
        _legend('Attention', warning, total, OpsColors.amber),
        _legend('Offline', offline, total, OpsColors.danger),
      ],
    );
  }

  Widget _legend(String label, int value, int total, Color color) {
    final factor = value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: OpsColors.muted)),
          const Spacer(),
          Text(
            '$value (${(factor * 100).round()}%)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AdminDonutPainter extends CustomPainter {
  final double online;
  final double warning;
  final double offline;

  const _AdminDonutPainter({
    required this.online,
    required this.warning,
    required this.offline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    var start = -pi / 2;
    for (final segment in [
      (offline, OpsColors.danger),
      (warning, OpsColors.amber),
      (online, OpsColors.success),
    ]) {
      paint.color = segment.$2;
      final sweep = max(segment.$1, .02) * pi * 2;
      canvas.drawArc(rect.deflate(14), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AdminDonutPainter oldDelegate) {
    return oldDelegate.online != online ||
        oldDelegate.warning != warning ||
        oldDelegate.offline != offline;
  }
}

class _AdminAlertSummary extends StatelessWidget {
  final int critical;
  final int warning;
  final int info;
  final int total;

  const _AdminAlertSummary({
    required this.critical,
    required this.warning,
    required this.info,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    return Column(
      children: [
        _AdminCategoryRow(
          'Critical',
          critical,
          critical / safeTotal,
          OpsColors.danger,
        ),
        _AdminCategoryRow(
          'Warning',
          warning,
          warning / safeTotal,
          const Color(0xFFF97316),
        ),
        _AdminCategoryRow(
          'Info',
          info,
          info / safeTotal,
          OpsColors.primary,
        ),
        _AdminCategoryRow(
          'Healthy',
          (safeTotal - critical - warning - info).clamp(0, safeTotal),
          ((safeTotal - critical - warning - info).clamp(0, safeTotal)) /
              safeTotal,
          OpsColors.success,
        ),
      ],
    );
  }
}

class _AdminCategoryRow extends StatelessWidget {
  final String label;
  final int value;
  final double factor;
  final Color color;

  const _AdminCategoryRow(this.label, this.value, this.factor, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: OpsColors.muted)),
              const Spacer(),
              Text('$value',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor.clamp(0, 1),
              minHeight: 8,
              color: color,
              backgroundColor: const Color(0xFFECEEF0),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActiveBadge extends StatelessWidget {
  const _AdminActiveBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: OpsColors.success),
        SizedBox(width: 8),
        Text(
          'ACTIVE',
          style: TextStyle(
            color: OpsColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AdminLiveFeed extends StatelessWidget {
  final List<dynamic> alerts;

  const _AdminLiveFeed({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final display = alerts.take(4).map((alert) {
      final level = alert.alertLevel.toString().trim().toLowerCase();
      final color = level.contains('critical')
          ? OpsColors.danger
          : level.contains('warn')
              ? OpsColors.amber
              : OpsColors.primary;
      return (
        _iconForLevel(level),
        color,
        alert.message.toString().trim().isEmpty
            ? 'Alert ${alert.id}'
            : alert.message.toString().trim(),
        _ago(alert.triggeredAt as DateTime),
        alert.sensorId.toString().trim().isEmpty
            ? 'Unknown'
            : alert.sensorId.toString().trim(),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LiveCameraPreview(
          activeAlerts: display.length,
          hasCritical: display.any((entry) => entry.$2 == OpsColors.danger),
        ),
        const SizedBox(height: 16),
        if (display.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: OpsColors.surfaceLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OpsColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: OpsColors.text,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'All monitored zones are stable. No unresolved alert events are linked to the live camera view right now.',
                  style: TextStyle(
                    color: OpsColors.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: display.indexed.map((entry) {
              final index = entry.$1;
              final row = entry.$2;
              return _LiveFeedActivityRow(
                icon: row.$1,
                tint: row.$2,
                title: row.$3,
                timeLabel: row.$4,
                assetLabel: row.$5,
                showDivider: index != display.length - 1,
              );
            }).toList(),
          ),
      ],
    );
  }

  static IconData _iconForLevel(String level) {
    if (level.contains('critical') || level.contains('high')) {
      return Icons.warning_amber_rounded;
    }
    if (level.contains('warn')) return Icons.report_problem_outlined;
    return Icons.info_outline_rounded;
  }

  static String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inDays < 1) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }
}

class _LiveCameraPreview extends StatelessWidget {
  final int activeAlerts;
  final bool hasCritical;

  const _LiveCameraPreview({
    required this.activeAlerts,
    required this.hasCritical,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hasCritical ? OpsColors.danger : OpsColors.success;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/construction.jpg',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'CAM 01',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              hasCritical ? 'ATTENTION' : 'MONITORING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Perimeter Camera View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeAlerts == 0
                                    ? 'Live site camera linked to the central monitoring console.'
                                    : '$activeAlerts unresolved event${activeAlerts == 1 ? '' : 's'} detected near the monitored zone.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.84),
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.center_focus_strong_rounded,
                            color: Colors.white,
                            size: 28,
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
      ),
    );
  }
}

class _LiveFeedActivityRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String timeLabel;
  final String assetLabel;
  final bool showDivider;

  const _LiveFeedActivityRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.timeLabel,
    required this.assetLabel,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFECEEF0)),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(timeLabel, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Text(
            assetLabel,
            style: TextStyle(
              color: tint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOverviewTable extends StatelessWidget {
  final dynamic db;

  const _AdminOverviewTable({required this.db});

  @override
  Widget build(BuildContext context) {
    final rows = (db.sites as List).map((site) {
      final siteDevices = (db.devices as List)
          .where((device) => device.siteId == site.id)
          .toList();
      final siteDeviceIds = siteDevices.map((device) => device.id).toSet();
      final siteSensors = (db.sensors as List)
          .where((sensor) => siteDeviceIds.contains(sensor.deviceId))
          .toList();
      final siteSensorIds = siteSensors.map((sensor) => sensor.id).toSet();
      final siteAlerts = (db.alerts as List)
          .where((alert) => alert.resolvedAt == null)
          .where((alert) => siteSensorIds.contains(alert.sensorId))
          .toList();
      final onlineDevices = siteDevices.where((device) {
        final status = device.status.toString().trim().toLowerCase();
        return status == 'active' ||
            status == 'online' ||
            status == 'healthy' ||
            status == 'running';
      }).length;
      final lastUpdate = siteDevices.isEmpty
          ? 'No data'
          : _AdminLiveFeed._ago(
              siteDevices
                  .map((device) => device.installedAt as DateTime)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
            );
      return (
        site.name.toString(),
        onlineDevices == siteDevices.length && siteDevices.isNotEmpty
            ? 'Online'
            : onlineDevices == 0
                ? 'Offline'
                : 'Warning',
        '${siteSensors.length} / ${siteDevices.length}',
        '${siteAlerts.length}',
        lastUpdate,
      );
    }).toList();

    return UniversalDataTable(
      columns: const [
        DataColumn(label: UniversalTableHeaderText('SITE')),
        DataColumn(label: UniversalTableHeaderText('STATUS')),
        DataColumn(
          label: UniversalTableHeaderText(
            'SENSORS',
            textAlign: TextAlign.center,
          ),
        ),
        DataColumn(
          label: UniversalTableHeaderText(
            'ALERTS',
            textAlign: TextAlign.center,
          ),
        ),
        DataColumn(label: UniversalTableHeaderText('LAST UPDATE')),
      ],
      rows: rows.map((row) {
        final alertColor = row.$4 == '0'
            ? OpsColors.muted
            : row.$4 == '1'
                ? OpsColors.warning
                : OpsColors.danger;
        return DataRow(
          cells: [
            DataCell(UniversalTableText(row.$1, bold: true)),
            DataCell(OpsStatusBadge(row.$2)),
            DataCell(
              UniversalTableText(
                row.$3,
                textAlign: TextAlign.center,
                bold: true,
              ),
            ),
            DataCell(
              UniversalTableText(
                row.$4,
                textAlign: TextAlign.center,
                bold: true,
                color: alertColor,
              ),
            ),
            DataCell(
              UniversalTableText(
                row.$5,
                color: OpsColors.muted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _AdminOverviewHeader extends StatelessWidget {
  const _AdminOverviewHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SITE OVERVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: OpsColors.outline,
                letterSpacing: .4,
              ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          iconAlignment: IconAlignment.end,
          label: const Text('View all'),
          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
          style: TextButton.styleFrom(
            foregroundColor: OpsColors.primary,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _AdminHealthTrend extends StatelessWidget {
  final String firstLabel;
  final String secondLabel;
  final List<double> firstValues;
  final List<double> secondValues;
  final List<String> bottomLabels;

  const _AdminHealthTrend({
    required this.firstLabel,
    required this.secondLabel,
    required this.firstValues,
    required this.secondValues,
    required this.bottomLabels,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 286,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                _AdminLegendDot(firstLabel, OpsColors.success),
                const SizedBox(width: 14),
                _AdminLegendDot(secondLabel, OpsColors.amber),
              ],
            ),
          ),
          const Positioned(
            top: 26,
            bottom: 32,
            left: 0,
            width: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('100%'),
                Text('75%'),
                Text('50%'),
                Text('25%'),
                Text('0%'),
              ],
            ),
          ),
          Positioned(
            top: 26,
            bottom: 38,
            left: 38,
            right: 0,
            child: CustomPaint(
              painter: _AdminTrendPainter(
                firstValues: firstValues,
                secondValues: secondValues,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 38,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bottomLabels
                  .map((label) => Text(label))
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _AdminLegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: OpsColors.muted)),
      ],
    );
  }
}

class _AdminTrendPainter extends CustomPainter {
  final List<double> firstValues;
  final List<double> secondValues;

  const _AdminTrendPainter({
    required this.firstValues,
    required this.secondValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = OpsColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawLine(canvas, size, firstValues, OpsColors.success);
    _drawLine(canvas, size, secondValues, OpsColors.amber);
  }

  void _drawLine(Canvas canvas, Size size, List<double> values, Color color) {
    if (values.isEmpty) return;
    final path = Path();
    final pointPaint = Paint()..color = color;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / 100 * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 5.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(min(x + dash, end.dx), end.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _AdminTrendPainter oldDelegate) {
    return oldDelegate.firstValues != firstValues ||
        oldDelegate.secondValues != secondValues;
  }
}

class _AdminDashboardFooter extends StatelessWidget {
  const _AdminDashboardFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OpsColors.border)),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: OpsColors.muted),
          SizedBox(width: 8),
          Text('All times in IST (UTC +05:30)',
              style: TextStyle(color: OpsColors.muted)),
          Spacer(),
          Icon(Icons.circle, size: 8, color: OpsColors.success),
          SizedBox(width: 8),
          Text('Platform updates refresh automatically',
              style: TextStyle(color: OpsColors.muted)),
        ],
      ),
    );
  }
}

class _ProcessedReadingSnapshot {
  const _ProcessedReadingSnapshot({
    required this.sensorId,
    required this.roll,
    required this.pitch,
    required this.tilt,
    required this.magnitude,
    required this.vibrationRms,
    required this.motionDetected,
    required this.receivedAt,
  });

  final String sensorId;
  final double roll;
  final double pitch;
  final double tilt;
  final double magnitude;
  final double? vibrationRms;
  final bool motionDetected;
  final DateTime receivedAt;
}

class _AnalyzedDetailSnapshot {
  const _AnalyzedDetailSnapshot({
    required this.sensorId,
    required this.readingId,
    required this.x,
    required this.y,
    required this.z,
    required this.roll,
    required this.pitch,
    required this.tilt,
    required this.horizontalMagnitude,
    required this.alertCount,
    required this.streamTimestamp,
  });

  final String sensorId;
  final String readingId;
  final double x;
  final double y;
  final double z;
  final double? roll;
  final double? pitch;
  final double? tilt;
  final double? horizontalMagnitude;
  final int alertCount;
  final double streamTimestamp;
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: OpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
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
    final onDark = data.isHighlight ? Colors.white : OpsColors.text;
    final sub = data.isHighlight ? const Color(0xFFb5dbef) : data.tint;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 92 || constraints.maxWidth < 170;
        return Container(
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            color: data.isHighlight ? data.tint : OpsColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OpsColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: data.isHighlight ? 0.12 : 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
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
                  borderRadius: BorderRadius.circular(8),
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
        ? OpsColors.muted
        : OpsColors.muted;
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
    final titleColor = OpsColors.muted;
    final valueColor = OpsColors.text;
    final unitColor = OpsColors.muted;
    final detailColor = OpsColors.muted;
    final badgeBg = OpsColors.success.withValues(alpha: .10);
    final badgeBorder = OpsColors.success.withValues(alpha: .24);
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
