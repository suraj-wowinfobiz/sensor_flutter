import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_admin_riverpod_provider.dart';
import '../../super_admin/services/analytics_sse_service.dart';
import '../../super_admin/services/generic_sse_service.dart';

class UserAdminDashboardScreen extends ConsumerStatefulWidget {
  final bool embeddedScroll;

  const UserAdminDashboardScreen({super.key, this.embeddedScroll = false});

  @override
  ConsumerState<UserAdminDashboardScreen> createState() =>
      _UserAdminDashboardScreenState();
}

class _UserAdminDashboardScreenState
    extends ConsumerState<UserAdminDashboardScreen> {
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
    while (_analyzedRollData.length > 65) {
      _analyzedRollData.removeAt(0);
    }
    while (_analyzedPitchData.length > 65) {
      _analyzedPitchData.removeAt(0);
    }
    while (_analyzedTiltData.length > 65) {
      _analyzedTiltData.removeAt(0);
    }
    while (_analyzedAngularVelocityData.length > 65) {
      _analyzedAngularVelocityData.removeAt(0);
    }
    while (_analyzedAccelerationData.length > 65) {
      _analyzedAccelerationData.removeAt(0);
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
    for (int i = 0; i < _analyzedRollData.length; i++) {
      _analyzedRollData[i] = FlSpot(i.toDouble(), _analyzedRollData[i].y);
    }
    for (int i = 0; i < _analyzedPitchData.length; i++) {
      _analyzedPitchData[i] = FlSpot(i.toDouble(), _analyzedPitchData[i].y);
    }
    for (int i = 0; i < _analyzedTiltData.length; i++) {
      _analyzedTiltData[i] = FlSpot(i.toDouble(), _analyzedTiltData[i].y);
    }
    for (int i = 0; i < _analyzedAngularVelocityData.length; i++) {
      _analyzedAngularVelocityData[i] =
          FlSpot(i.toDouble(), _analyzedAngularVelocityData[i].y);
    }
    for (int i = 0; i < _analyzedAccelerationData.length; i++) {
      _analyzedAccelerationData[i] =
          FlSpot(i.toDouble(), _analyzedAccelerationData[i].y);
    }
    _analyzedIndex = _analyzedXData.length;
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
    while (_processedMagnitudeData.length > 65) {
      _processedMagnitudeData.removeAt(0);
    }
    while (_processedAngularVelocityData.length > 65) {
      _processedAngularVelocityData.removeAt(0);
    }
    while (_processedAccelerationData.length > 65) {
      _processedAccelerationData.removeAt(0);
    }
    while (_processedVibrationData.length > 65) {
      _processedVibrationData.removeAt(0);
    }
    while (_processedMotionData.length > 65) {
      _processedMotionData.removeAt(0);
    }
    while (_processedSnapshots.length > 120) {
      _processedSnapshots.removeAt(0);
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
    for (int i = 0; i < _processedMagnitudeData.length; i++) {
      _processedMagnitudeData[i] =
          FlSpot(i.toDouble(), _processedMagnitudeData[i].y);
    }
    for (int i = 0; i < _processedAngularVelocityData.length; i++) {
      _processedAngularVelocityData[i] =
          FlSpot(i.toDouble(), _processedAngularVelocityData[i].y);
    }
    for (int i = 0; i < _processedAccelerationData.length; i++) {
      _processedAccelerationData[i] =
          FlSpot(i.toDouble(), _processedAccelerationData[i].y);
    }
    for (int i = 0; i < _processedVibrationData.length; i++) {
      _processedVibrationData[i] =
          FlSpot(i.toDouble(), _processedVibrationData[i].y);
    }
    for (int i = 0; i < _processedMotionData.length; i++) {
      _processedMotionData[i] = FlSpot(i.toDouble(), _processedMotionData[i].y);
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
    final activeAlerts = db.getActiveAlerts().length;
    final platformUpdateAt = _latestPlatformUpdateAt(db);
    final orgSeries = _dailySpotsFromDates(
      (db.organizations as List).map((item) => item.createdAt as DateTime),
      days: 30,
    );
    final siteSeries = _dailySpotsFromDates(
      (db.sites as List).map((item) => item.createdAt as DateTime),
      days: 30,
    );
    final userSeries = _dailySpotsFromDates(
      (db.users as List).map((item) => item.createdAt as DateTime),
      days: 30,
    );
    final criticalSeries = _dailySpotsFromDates(
      (db.alerts as List).where((item) {
        if (item.resolvedAt != null) return false;
        final level = (item.alertLevel as String).trim().toLowerCase();
        return level.contains('critical') || level.contains('high');
      }).map((item) => item.triggeredAt as DateTime),
      days: 30,
    );
    final warningSeries = _dailySpotsFromDates(
      (db.alerts as List).where((item) {
        if (item.resolvedAt != null) return false;
        final level = (item.alertLevel as String).trim().toLowerCase();
        return level.contains('warn');
      }).map((item) => item.triggeredAt as DateTime),
      days: 30,
    );
    final infoSeries = _dailySpotsFromDates(
      (db.alerts as List).where((item) {
        if (item.resolvedAt != null) return false;
        final level = (item.alertLevel as String).trim().toLowerCase();
        return !level.contains('critical') &&
            !level.contains('high') &&
            !level.contains('warn');
      }).map((item) => item.triggeredAt as DateTime),
      days: 30,
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopStats(
            context,
            db,
            activeAlerts: activeAlerts,
            latestUpdateAt: platformUpdateAt,
          ),
          // const SizedBox(height: 18),
          // _buildLiveSeriesCard(
          //   context,
          //   title: 'Onboarding Trend (30 Days)',
          //   icon: Icons.hub_outlined,
          //   xData: orgSeries,
          //   yData: siteSeries,
          //   zData: userSeries,
          //   xLabel: 'Organizations',
          //   yLabel: 'Sites',
          //   zLabel: 'Users',
          //   yAxisLabel: 'Created entities',
          //   xAxisLabel: 'Day index',
          // ),
          const SizedBox(height: 18),
          _buildKinematicsRow(context),
          const SizedBox(height: 18),
          _buildSensorReadingsCard(context),
          const SizedBox(height: 18),
          _buildBottomLiveStats(context, db),
          const SizedBox(height: 18),
          _buildTiltRangeDistribution(context, db),
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
    String yAxisLabel = 'Value',
    String xAxisLabel = 'Sample',
  }) {
    final allSpots = [...xData, ...yData, ...zData];
    final hasData = allSpots.isNotEmpty;
    final minY = hasData ? allSpots.map((e) => e.y).reduce(min) - 1 : 0.0;
    final maxY = hasData ? allSpots.map((e) => e.y).reduce(max) + 1 : 10.0;
    final minX = hasData ? allSpots.map((e) => e.x).reduce(min) : 0.0;
    final maxX = hasData ? allSpots.map((e) => e.x).reduce(max) : 65.0;
    final safeXData = xData.isEmpty ? const [FlSpot(0, 0)] : xData;
    final safeYData = yData.isEmpty ? const [FlSpot(0, 0)] : yData;
    final safeZData = zData.isEmpty ? const [FlSpot(0, 0)] : zData;

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
    BuildContext context,
    dynamic db, {
    required int activeAlerts,
    required DateTime? latestUpdateAt,
  }) {
    final activeOrganizations = (db.organizations as List)
        .where(
            (item) => (item.status as String).trim().toLowerCase() == 'active')
        .length;
    final devicesOnline = (db.devices as List).where((item) {
      final status = (item.status as String).trim().toLowerCase();
      return status == 'active' ||
          status == 'online' ||
          status == 'healthy' ||
          status == 'running';
    }).length;
    final totalDevices = (db.devices as List).length;
    final mappedSensors = (db.sensors as List)
        .where((item) => (item.deviceId as String).trim().isNotEmpty)
        .length;
    final totalSensors = (db.sensors as List).length;
    final healthScore = ((totalDevices == 0
                    ? 100
                    : (devicesOnline / totalDevices) * 100) *
                0.4 +
            (totalSensors == 0 ? 100 : (mappedSensors / totalSensors) * 100) *
                0.4 +
            (activeAlerts == 0 ? 100 : max(0, 100 - (activeAlerts * 5))) * 0.2)
        .clamp(0, 100)
        .toDouble();

    final cards = [
      _MetricData(
        title: 'ACTIVE ORGANIZATIONS',
        value: activeOrganizations.toString(),
        subtitle: 'of ${(db.organizations as List).length} total orgs',
        icon: Icons.business_outlined,
        tint: const Color(0xFF5973d8),
        isHighlight: false,
      ),
      _MetricData(
        title: 'DEVICE UPTIME',
        value:
            '${(totalDevices == 0 ? 0 : (devicesOnline / totalDevices) * 100).toStringAsFixed(0)}%',
        subtitle: '$devicesOnline online of $totalDevices devices',
        icon: Icons.router_outlined,
        tint: const Color(0xFFd29a00),
      ),
      _MetricData(
        title: 'PLATFORM HEALTH',
        value: '${healthScore.toStringAsFixed(0)}%',
        subtitle: 'Availability + mapping + alert pressure',
        icon: Icons.check_circle_outline,
        tint: const Color(0xFF0ea65b),
      ),
      _MetricData(
        title: 'LAST PLATFORM UPDATE',
        value: latestUpdateAt == null ? 'N/A' : _agoLabel(latestUpdateAt),
        subtitle: latestUpdateAt == null
            ? 'No activity yet'
            : '${(db.alerts as List).length} alerts tracked',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 1050;
        if (!twoCols) {
          return Column(
            children: [
              _buildVelocityCard(context),
              const SizedBox(height: 16),
              _buildAccelerationTrendCard(context),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildVelocityCard(context)),
            const SizedBox(width: 16),
            Expanded(child: _buildAccelerationTrendCard(context)),
          ],
        );
      },
    );
  }

  // Widget _buildAnalyzedRow(BuildContext context) {
  //   final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
  //   final deviceSpots = _dailySpotsFromDates(
  //     (db.devices as List).map((item) => item.installedAt as DateTime),
  //     days: 30,
  //   );
  //   final sensorSpots = _dailySpotsFromDates(
  //     (db.sensors as List).map((item) => item.installedAt as DateTime),
  //     days: 30,
  //   );
  //   final siteSpots = _dailySpotsFromDates(
  //     (db.sites as List).map((item) => item.createdAt as DateTime),
  //     days: 30,
  //   );
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final twoCols = constraints.maxWidth >= 1050;
  //       const rowCardHeight = 520.0;
  //       final analyzedCard = _buildLiveSeriesCard(
  //         context,
  //         title: 'Asset Onboarding Trend',
  //         icon: Icons.psychology_alt_outlined,
  //         xData: deviceSpots,
  //         yData: sensorSpots,
  //         zData: siteSpots,
  //         xLabel: 'Devices',
  //         yLabel: 'Sensors',
  //         zLabel: 'Sites',
  //         yAxisLabel: 'Assets per day',
  //         xAxisLabel: 'Last 30 days',
  //       );
  //       final radarCard = _buildAnalyzedRadarCard(context);
  //       if (!twoCols) {
  //         return Column(
  //           children: [
  //             analyzedCard,
  //             const SizedBox(height: 16),
  //             radarCard,
  //           ],
  //         );
  //       }
  //       return Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Expanded(
  //             child: SizedBox(
  //               height: rowCardHeight,
  //               child: analyzedCard,
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: SizedBox(
  //               height: rowCardHeight,
  //               child: radarCard,
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget _buildVelocityCard(BuildContext context) {
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
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
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
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
              _historicalTrendCard(context),
              const SizedBox(height: 16),
              _statusDistributionCard(context, db),
              const SizedBox(height: 16),
              _tiltPatternCard(context),
              const SizedBox(height: 16),
              _thresholdMonitoringCard(context, db),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _historicalTrendCard(context)),
                const SizedBox(width: 16),
                Expanded(child: _statusDistributionCard(context, db)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _tiltPatternCard(context)),
                const SizedBox(width: 16),
                Expanded(child: _thresholdMonitoringCard(context, db)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyzedRadarCard(BuildContext context) {
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
    final organizations = (db.organizations as List).length.toDouble();
    final sites = (db.sites as List).length.toDouble();
    final zones = (db.zones as List).length.toDouble();
    final users = (db.users as List).length.toDouble();
    final devices = (db.devices as List).length.toDouble();
    final sensors = (db.sensors as List).length.toDouble();
    final activeAlerts = (db.alerts as List)
        .where((item) => item.resolvedAt == null)
        .length
        .toDouble();
    final maxScale = max<double>(
      1.0,
      [organizations, sites, zones, users, devices, sensors, activeAlerts]
          .reduce(max),
    );
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Platform Composition Profile',
            Icons.radar_outlined,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 5,
                titlePositionPercentageOffset: 0.16,
                titleTextStyle: TextStyle(
                  color: _mutedTextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                ticksTextStyle: TextStyle(
                  color: _mutedTextColor(context),
                  fontSize: 10,
                ),
                tickBorderData: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                getTitle: (index, angle) {
                  const titles = [
                    'Orgs',
                    'Sites',
                    'Zones',
                    'Users',
                    'Devices',
                    'Sensors',
                    'Alerts',
                  ];
                  return RadarChartTitle(
                    text: titles[index],
                    angle: angle,
                  );
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: Theme.of(context).colorScheme.primary.withValues(
                          alpha: 0.20,
                        ),
                    borderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2.2,
                    entryRadius: 3.2,
                    dataEntries: [
                      RadarEntry(value: _radarScale(organizations, maxScale)),
                      RadarEntry(value: _radarScale(sites, maxScale)),
                      RadarEntry(value: _radarScale(zones, maxScale)),
                      RadarEntry(value: _radarScale(users, maxScale)),
                      RadarEntry(value: _radarScale(devices, maxScale)),
                      RadarEntry(value: _radarScale(sensors, maxScale)),
                      RadarEntry(value: _radarScale(activeAlerts, maxScale)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _valueChip(context, 'Orgs', organizations.toStringAsFixed(0)),
              _valueChip(context, 'Sites', sites.toStringAsFixed(0)),
              _valueChip(context, 'Zones', zones.toStringAsFixed(0)),
              _valueChip(context, 'Users', users.toStringAsFixed(0)),
              _valueChip(context, 'Devices', devices.toStringAsFixed(0)),
              _valueChip(context, 'Sensors', sensors.toStringAsFixed(0)),
              _valueChip(
                  context, 'Active Alerts', activeAlerts.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historicalTrendCard(BuildContext context) {
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
    final spots = _dailySpotsFromDates(
      (db.alerts as List).map((item) => item.triggeredAt as DateTime),
      days: 14,
    );
    final hasData = spots.isNotEmpty;
    final maxY =
        hasData ? max<double>(1.0, spots.map((e) => e.y).reduce(max) + 1) : 1.0;
    final maxX = hasData ? spots.last.x : 14.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Alert Volume Trend (14 Days)', Icons.trending_up),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX <= 0 ? 1 : maxX,
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: (maxY / 8).clamp(1, 10.0),
                        verticalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          final major = (value - value.round()).abs() < 0.04;
                          return FlLine(
                            color: const Color(0xFF111111)
                                .withValues(alpha: major ? 0.7 : 0.35),
                            strokeWidth: major ? 1.0 : 0.7,
                            dashArray: major ? null : const [10, 6],
                          );
                        },
                        getDrawingVerticalLine: (_) => FlLine(
                          color: const Color(0xFF111111).withValues(alpha: 0.3),
                          strokeWidth: 0.7,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Color(0xFF111111), width: 1),
                          bottom:
                              BorderSide(color: Color(0xFF111111), width: 1),
                          top: BorderSide(color: Color(0xFF111111), width: 1),
                          right: BorderSide(color: Color(0xFF111111), width: 1),
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
                            'Alerts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2930),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: (maxY / 5).clamp(1, 20.0),
                            getTitlesWidget: (value, _) => Text(
                              value.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1E2930),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text(
                            'Day index',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2930),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 10,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1E2930),
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF111D8A),
                          barWidth: 2.0,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : const Center(child: Text('Waiting for alert trend data...')),
          ),
        ],
      ),
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
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
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

  Widget _thresholdMonitoringCard(BuildContext context, dynamic db) {
    final organizations = (db.organizations as List).length;
    final sites = (db.sites as List).length;
    final zones = (db.zones as List).length;
    final sensors = (db.sensors as List).length;
    final devices = (db.devices as List).length;
    final thresholdValues = (db.thresholdValues as List).length;
    final mappedSites = (db.sites as List)
        .where((item) => (item.organizationId as String).trim().isNotEmpty)
        .length;
    final mappedSensors = (db.sensors as List)
        .where((item) => (item.deviceId as String).trim().isNotEmpty)
        .length;
    final bars = <({String label, int value, int total})>[
      (
        label: 'Organizations',
        value: organizations,
        total: max(1, organizations)
      ),
      (label: 'Sites Mapped', value: mappedSites, total: max(1, sites)),
      (label: 'Zones', value: zones, total: max(1, zones)),
      (label: 'Devices', value: devices, total: max(1, devices)),
      (label: 'Sensors Mapped', value: mappedSensors, total: max(1, sensors)),
      (label: 'Thresholds', value: thresholdValues, total: max(1, sensors)),
    ];
    final maxBar = max<double>(
        1.0, bars.map((item) => item.value.toDouble()).reduce(max) + 1);

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Governance Coverage', Icons.warning_amber_rounded),
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
                      'Control metrics',
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
                            return label.length > 9
                                ? '${label.substring(0, 9)}…'
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
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
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
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
    final sensors = List.of(db.sensors as List);
    final devices = List.of(db.devices as List);
    final sites = List.of(db.sites as List);
    final zones = List.of(db.zones as List);
    final organizations = List.of(db.organizations as List);
    final alerts = List.of(db.alerts as List)
      ..sort((a, b) =>
          (b.triggeredAt as DateTime).compareTo(a.triggeredAt as DateTime));
    final rows = alerts.take(8).map((alert) {
      final sensorId = (alert.sensorId as String).trim();
      final shortId =
          sensorId.length > 12 ? '${sensorId.substring(0, 12)}…' : sensorId;
      final sensor = sensors
          .where((item) => (item.id as String).trim() == sensorId)
          .firstOrNull;
      final device = sensor == null
          ? null
          : devices
              .where((item) =>
                  (item.id as String).trim() ==
                  (sensor.deviceId as String).trim())
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
      final level = (alert.alertLevel as String).trim().toLowerCase();
      final status = level.contains('critical') || level.contains('high')
          ? 'critical'
          : level.contains('warn')
              ? 'warning'
              : 'normal';
      return [
        shortId,
        '${organization?.name ?? '--'} / ${site?.name ?? '--'}',
        zone?.name ?? '--',
        (alert.alertLevel as String),
        (alert.status as String).isEmpty ? '--' : (alert.status as String),
        (alert.message as String),
        status,
        _agoLabel(alert.triggeredAt as DateTime),
      ];
    }).toList();

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
                'Recent Processed Events - Live Feed',
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
                  _tableHeading(context, 'Source ID'),
                  _tableHeading(context, 'Tenant / Site'),
                  _tableHeading(context, 'Zone'),
                  _tableHeading(context, 'Severity'),
                  _tableHeading(context, 'Alert Status'),
                  _tableHeading(context, 'Message'),
                  _tableHeading(context, 'Risk'),
                  _tableHeading(context, 'Last Update'),
                ],
                rows: rows.map((r) {
                  final status = r[6];
                  final isWarning = status == 'warning';
                  final isCritical = status == 'critical';
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
                        color: isCritical
                            ? const Color(0xFFf7d3d6)
                            : isWarning
                                ? const Color(0xFFf9edc9)
                                : const Color(0xFFd7f2df),
                        border: Border.all(
                          color: isCritical
                              ? const Color(0xFFe35b63)
                              : isWarning
                                  ? const Color(0xFFd9a21d)
                                  : const Color(0xFF2eaf61),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isCritical
                              ? const Color(0xFFb2262e)
                              : isWarning
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
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No recent alert records available.',
                style: TextStyle(color: _mutedTextColor(context)),
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

  Widget _buildBottomLiveStats(BuildContext context, dynamic db) {
    final now = DateTime.now();
    final alertsLast24h = (db.alerts as List)
        .where((item) =>
            now.difference(item.triggeredAt as DateTime).inHours <= 24)
        .length;
    final throughput = alertsLast24h / 24.0;
    final activeAlerts =
        (db.alerts as List).where((item) => item.resolvedAt == null).length;
    final totalAlerts = (db.alerts as List).length;
    final anomalyRate =
        totalAlerts == 0 ? 0.0 : ((activeAlerts / totalAlerts) * 100);
    final latestAlertAt = (db.alerts as List).isEmpty
        ? null
        : ((db.alerts as List)
                .map((item) => item.triggeredAt as DateTime)
                .toList()
              ..sort((a, b) => b.compareTo(a)))
            .first;
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
        title: 'EVENT THROUGHPUT',
        value: throughput.toStringAsFixed(2),
        unit: 'evt/sec',
        detail: '$alertsLast24h alerts in 24h',
        badge: throughput > 0 ? 'Live' : 'Idle',
        icon: Icons.bolt_outlined,
        iconColor: const Color(0xFF5f78de),
      ),
      _MiniStatData(
        title: 'ANOMALY RATE',
        value: anomalyRate.toStringAsFixed(0),
        unit: '%',
        detail: 'active alerts share',
        badge: anomalyRate >= 50 ? 'High' : 'Normal',
        icon: Icons.trending_up,
        iconColor: const Color(0xFFd39a00),
      ),
      _MiniStatData(
        title: 'LAST ALERT',
        value: latestAlertAt == null ? '--' : _agoLabel(latestAlertAt),
        unit: '',
        detail: 'most recent platform alert',
        badge: latestAlertAt == null ? 'N/A' : 'Live',
        icon: Icons.network_ping,
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
            'Organizations requiring immediate admin attention.',
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

  Widget _buildDeepAnalysisCard(BuildContext context, dynamic db) {
    final now = DateTime.now();
    final activeAlerts = (db.alerts as List).where((a) => a.resolvedAt == null);
    final criticalActive = activeAlerts.where((a) {
      final level = (a.alertLevel as String).trim().toLowerCase();
      return level.contains('critical') || level.contains('high');
    }).length;
    final mappedSites = (db.sites as List)
        .where((item) => (item.organizationId as String).trim().isNotEmpty)
        .length;
    final mappedSensors = (db.sensors as List)
        .where((item) => (item.deviceId as String).trim().isNotEmpty)
        .length;
    final last7Days = now.subtract(const Duration(days: 7));
    final previous7DaysStart = now.subtract(const Duration(days: 14));
    final usersLast7 = (db.users as List)
        .where((u) => (u.createdAt as DateTime).isAfter(last7Days))
        .length;
    final usersPrev7 = (db.users as List)
        .where((u) =>
            (u.createdAt as DateTime).isAfter(previous7DaysStart) &&
            (u.createdAt as DateTime).isBefore(last7Days))
        .length;
    final orgsLast7 = (db.organizations as List)
        .where((o) => (o.createdAt as DateTime).isAfter(last7Days))
        .length;
    final orgsPrev7 = (db.organizations as List)
        .where((o) =>
            (o.createdAt as DateTime).isAfter(previous7DaysStart) &&
            (o.createdAt as DateTime).isBefore(last7Days))
        .length;
    final topOrg = _organizationAlertCounts(db).entries.firstOrNull;
    final insights = <String>[
      'Critical load: $criticalActive critical/high active alerts need immediate triage.',
      'Coverage: $mappedSites/${(db.sites as List).length} sites mapped, $mappedSensors/${(db.sensors as List).length} sensors linked.',
      'Onboarding velocity: users $usersLast7 vs $usersPrev7 (last 7d vs prior 7d), orgs $orgsLast7 vs $orgsPrev7.',
      'Top risk concentration: ${topOrg?.key ?? 'No organization'} contributes ${topOrg?.value ?? 0} open alerts.',
    ];

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Deep Analysis Summary', Icons.insights_outlined),
          const SizedBox(height: 10),
          Text(
            'Priority interpretation of tenant risk, mapping readiness, and onboarding momentum.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 14),
          ...List.generate(insights.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == insights.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFEAF0F4)
                          : const Color(0xFF23394A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _titleColor(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insights[index],
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: _titleColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
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
