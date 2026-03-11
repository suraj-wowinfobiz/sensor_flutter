import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_sse_service.dart';
import '../services/generic_sse_service.dart';
import '../../super_admin/shared/models/threshold_rule.dart';
import '../providers/engineer_api_riverpod_provider.dart';
import '../providers/engineer_riverpod_provider.dart';

class EngineerDashboardScreen extends ConsumerStatefulWidget {
  final bool embeddedScroll;

  const EngineerDashboardScreen({super.key, this.embeddedScroll = false});

  @override
  ConsumerState<EngineerDashboardScreen> createState() =>
      _EngineerDashboardScreenState();
}

class _EngineerDashboardScreenState
    extends ConsumerState<EngineerDashboardScreen> {
  static const String _allSensorsValue = '__all__';
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
  _AnalyzedDetailSnapshot? _latestAnalyzedSnapshot;
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
  String _selectedSensorId = _allSensorsValue;

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
        _latestAnalyzedSnapshot = detail;
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

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  String _safeText(dynamic value, {String fallback = '--'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  bool _containsKeyword(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) return true;
    }
    return false;
  }

  bool _isOnlineStatus(String status) {
    final value = status.trim().toLowerCase();
    return value == 'active' ||
        value == 'online' ||
        value == 'healthy' ||
        value == 'running';
  }

  bool _isDeviceFaultStatus(String status) {
    final value = status.trim().toLowerCase();
    return _containsKeyword(value, const [
      'fault',
      'error',
      'offline',
      'inactive',
      'down',
      'disconnect',
      'fail',
      'unreachable',
      'unhealthy',
    ]);
  }

  String _normalizeAlertLevel(String level) {
    final value = level.trim().toLowerCase();
    if (value.contains('emergency')) return 'emergency';
    if (value.contains('critical')) return 'critical';
    if (value.contains('high')) return 'high';
    if (value.contains('warning') || value.contains('warn')) return 'warning';
    if (value.contains('info')) return 'info';
    return value.isEmpty ? 'normal' : value;
  }

  int _alertSeverityRank(String level) {
    switch (_normalizeAlertLevel(level)) {
      case 'emergency':
        return 5;
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'warning':
        return 2;
      case 'info':
        return 1;
      default:
        return 0;
    }
  }

  bool _isEscalationLevel(String level) {
    final normalized = _normalizeAlertLevel(level);
    return normalized == 'emergency' ||
        normalized == 'critical' ||
        normalized == 'high';
  }

  String _statusLabel(String value) {
    switch (_normalizeAlertLevel(value)) {
      case 'emergency':
        return 'Emergency';
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'warning':
        return 'Warning';
      case 'info':
        return 'Info';
      default:
        return 'Normal';
    }
  }

  bool _isDeviceFaultAlert(dynamic alert) {
    final message = _safeText(alert.message, fallback: '').toLowerCase();
    final parameter =
        _safeText(alert.sensorParameterId, fallback: '').toLowerCase();
    return _containsKeyword(message, const [
          'device',
          'gateway',
          'offline',
          'disconnect',
          'heartbeat',
          'power',
          'connectivity',
          'communication',
          'network',
        ]) ||
        _containsKeyword(parameter, const [
          'device',
          'gateway',
          'heartbeat',
          'power',
          'connect',
          'network',
        ]);
  }

  bool _isSensorFaultAlert(dynamic alert) {
    final message = _safeText(alert.message, fallback: '').toLowerCase();
    final parameter =
        _safeText(alert.sensorParameterId, fallback: '').toLowerCase();
    return _containsKeyword(message, const [
          'sensor',
          'tilt',
          'vibration',
          'calibration',
          'drift',
          'threshold',
          'noise',
          'stuck',
          'signal',
          'reading',
          'axis',
        ]) ||
        _containsKeyword(parameter, const [
          'sensor',
          'tilt',
          'vibration',
          'temperature',
          'reading',
          'axis',
          'magnitude',
        ]);
  }

  List<dynamic> _activeAlerts(dynamic db) {
    final value = db.getActiveAlerts();
    return value is List ? value : const <dynamic>[];
  }

  int _installedDevicesCount(dynamic db) {
    final devices = db.devices;
    return devices is List ? devices.length : 0;
  }

  int _installedDevicesInDays(dynamic db, {int days = 30}) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    final devices = db.devices;
    if (devices is! List) return 0;
    return devices.where((device) {
      final installedAt = _parseDateTime(device.installedAt);
      return installedAt != null && installedAt.isAfter(threshold);
    }).length;
  }

  int _installedSensorsInDays(dynamic db, {int days = 30}) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    final sensors = db.sensors;
    if (sensors is! List) return 0;
    return sensors.where((sensor) {
      final installedAt = _parseDateTime(sensor.installedAt);
      return installedAt != null && installedAt.isAfter(threshold);
    }).length;
  }

  int _onlineDeviceCount(dynamic db) {
    final devices = db.devices;
    if (devices is! List) return 0;
    final now = DateTime.now();
    var count = 0;
    for (final device in devices) {
      final status = _safeText(device.status, fallback: '').toLowerCase();
      if (_isOnlineStatus(status)) {
        count++;
        continue;
      }
      final heartbeat = _parseDateTime(device.lastHeartBeat);
      if (heartbeat != null &&
          now.difference(heartbeat.toLocal()).inMinutes <= 15) {
        count++;
      }
    }
    return count;
  }

  int _sensorFaultCount(dynamic db) {
    final alerts = _activeAlerts(db);
    final faultySensors = <String>{};
    for (final alert in alerts) {
      if (!_isSensorFaultAlert(alert)) continue;
      final sensorId = _safeText(alert.sensorId, fallback: '').trim();
      if (sensorId.isNotEmpty) faultySensors.add(sensorId);
    }

    if (faultySensors.isEmpty && _processedSnapshots.isNotEmpty) {
      final thresholds = _dashboardThresholds(db);
      final criticalCutoff = thresholds.$2;
      for (final snapshot in _processedSnapshots.reversed.take(40)) {
        if (snapshot.tilt.abs() >= criticalCutoff) {
          faultySensors.add(snapshot.sensorId);
        }
      }
    }

    return faultySensors.length;
  }

  int _deviceFaultCount(dynamic db) {
    final sensors = db.sensors is List ? db.sensors as List : const <dynamic>[];
    final devices = db.devices is List ? db.devices as List : const <dynamic>[];

    final sensorToDevice = <String, String>{};
    for (final sensor in sensors) {
      final sensorId = _safeText(sensor.id, fallback: '').trim();
      final deviceId = _safeText(sensor.deviceId, fallback: '').trim();
      if (sensorId.isNotEmpty && deviceId.isNotEmpty) {
        sensorToDevice[sensorId] = deviceId;
      }
    }

    final faultyDevices = <String>{};
    for (final device in devices) {
      final status = _safeText(device.status, fallback: '');
      if (_isDeviceFaultStatus(status)) {
        final deviceId = _safeText(device.id, fallback: '').trim();
        if (deviceId.isNotEmpty) faultyDevices.add(deviceId);
      }
    }

    var unmappedFaultAlerts = 0;
    for (final alert in _activeAlerts(db)) {
      if (!_isDeviceFaultAlert(alert)) continue;
      final sensorId = _safeText(alert.sensorId, fallback: '').trim();
      final deviceId = sensorToDevice[sensorId];
      if (deviceId != null && deviceId.isNotEmpty) {
        faultyDevices.add(deviceId);
      } else {
        unmappedFaultAlerts++;
      }
    }

    return faultyDevices.length + unmappedFaultAlerts;
  }

  int _escalationCount(dynamic db) {
    final alerts = _activeAlerts(db);
    var count = 0;
    for (final alert in alerts) {
      if (_isEscalationLevel(_safeText(alert.alertLevel, fallback: ''))) {
        count++;
      }
    }
    return count;
  }

  Map<String, String> _sensorHighestAlertLevel(dynamic db) {
    final highestLevel = <String, String>{};
    final highestRank = <String, int>{};

    for (final alert in _activeAlerts(db)) {
      final sensorId = _safeText(alert.sensorId, fallback: '').trim();
      if (sensorId.isEmpty) continue;
      final level = _normalizeAlertLevel(_safeText(alert.alertLevel));
      final rank = _alertSeverityRank(level);
      if (rank >= (highestRank[sensorId] ?? -1)) {
        highestRank[sensorId] = rank;
        highestLevel[sensorId] = level;
      }
    }
    return highestLevel;
  }

  String _durationLabel(Duration duration) {
    if (duration.inMinutes < 1) return '<1m';
    if (duration.inHours < 1) return '${duration.inMinutes}m';
    if (duration.inDays < 1) {
      final minutes = duration.inMinutes % 60;
      return minutes == 0
          ? '${duration.inHours}h'
          : '${duration.inHours}h ${minutes}m';
    }
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    return hours == 0 ? '${days}d' : '${days}d ${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(engineerDatabaseChangeNotifierProvider);
    final statsApi = ref.watch(engineerDashboardStatsApiProvider).valueOrNull;
    final activeAlerts = (statsApi?['activeAlerts'] as num?)?.toInt() ??
        _activeAlerts(db).length;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopStats(context, db, activeAlerts),
          const SizedBox(height: 18),
          _buildLiveSeriesCard(
            context,
            title: 'Sensor Live Records',
            icon: Icons.sensors,
            xData: _rawXData,
            yData: _rawYData,
            zData: _rawZData,
            yAxisLabel: 'Raw acceleration',
            xAxisLabel: 'Raw sample index',
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
            yAxisLabel: 'Processed angle (°)',
            xAxisLabel: 'Processed sample index',
          ),
          const SizedBox(height: 18),
          _buildKinematicsRow(context),
          const SizedBox(height: 18),
          _buildAnalyzedRow(context),
          const SizedBox(height: 18),
          _buildAnalyticsGrid(context, db),
          const SizedBox(height: 18),
          _buildDeepAnalysisCard(context, db),
          const SizedBox(height: 18),
          _buildScatterCard(context),
          const SizedBox(height: 18),
          _buildSensorReadingsCard(context),
          const SizedBox(height: 18),
          _buildBottomLiveStats(context, db),
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
    dynamic db,
    int activeAlerts,
  ) {
    final totalDevices = _installedDevicesCount(db);
    final recentInstalls = _installedDevicesInDays(db, days: 30);
    final deviceFaults = _deviceFaultCount(db);
    final sensorFaults = _sensorFaultCount(db);
    final escalations = _escalationCount(db);

    final cards = [
      _MetricData(
        title: 'INSTALLED DEVICES',
        value: totalDevices.toString(),
        subtitle: '$recentInstalls installed in last 30 days',
        icon: Icons.precision_manufacturing_outlined,
        tint: const Color(0xFF5973d8),
      ),
      _MetricData(
        title: 'DEVICE FAULTS',
        value: deviceFaults.toString(),
        subtitle: deviceFaults == 0
            ? 'No open device failures'
            : 'Open connectivity/power faults',
        icon: Icons.router_outlined,
        tint: const Color(0xFFd29a00),
      ),
      _MetricData(
        title: 'SENSOR FAULTS',
        value: sensorFaults.toString(),
        subtitle: sensorFaults == 0
            ? 'No active sensor faults'
            : 'Sensors requiring field inspection',
        icon: Icons.sensors_outlined,
        tint: const Color(0xFF0ea65b),
      ),
      _MetricData(
        title: 'ESCALATIONS',
        value: escalations.toString(),
        subtitle: '$activeAlerts active alerts in queue',
        icon: Icons.report_problem_outlined,
        tint: const Color(0xFFE54C4C),
        isHighlight: escalations > 0,
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

  Widget _buildAnalyzedRow(BuildContext context) {
    return _buildLiveSeriesCard(
      context,
      title: 'Analyzed Live Data',
      icon: Icons.psychology_alt_outlined,
      xData: _analyzedRollData,
      yData: _analyzedPitchData,
      zData: _analyzedTiltData,
      xLabel: 'Roll',
      yLabel: 'Pitch',
      zLabel: 'Tilt',
      yAxisLabel: 'Analyzed angle (°)',
      xAxisLabel: 'Analyzed sample index',
    );
  }

  Widget _buildVelocityCard(BuildContext context) {
    final velocityAll = [
      ..._analyzedAngularVelocityData,
      ..._processedAngularVelocityData,
    ];
    final hasVelocity = velocityAll.isNotEmpty;
    final minVelocity =
        hasVelocity ? velocityAll.map((e) => e.y).reduce(min) : -2.0;
    final maxVelocity =
        hasVelocity ? velocityAll.map((e) => e.y).reduce(max) : 2.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(context, 'Velocity Analytics', Icons.speed_outlined),
          const SizedBox(height: 8),
          Text(
            'Angular velocity ω = Δθ/Δt (deg/s) from analyzed and processed streams.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: hasVelocity
                ? LineChart(
                    LineChartData(
                      minY: minVelocity - 0.2,
                      maxY: max(maxVelocity + 0.2, minVelocity + 0.4),
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
                            'ω (deg/s)',
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
                            'Sample index',
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
                          spots: _analyzedAngularVelocityData,
                          isCurved: true,
                          color: const Color(0xFF0f9ca0),
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: _processedAngularVelocityData,
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
                      'Waiting for velocity stream...',
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(color: Color(0xFF0f9ca0), label: 'Analyzed ω'),
              _LegendItem(color: Color(0xFFF59E0B), label: 'Processed ω'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccelerationTrendCard(BuildContext context) {
    final accelerationAll = [
      ..._analyzedAccelerationData,
      ..._processedAccelerationData,
    ];
    final hasAcceleration = accelerationAll.isNotEmpty;
    final minAcc =
        hasAcceleration ? accelerationAll.map((e) => e.y).reduce(min) : -1.0;
    final maxAcc =
        hasAcceleration ? accelerationAll.map((e) => e.y).reduce(max) : 1.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Acceleration Analytics',
            Icons.timelapse_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'Angular acceleration α = Δω/Δt (deg/s²) from analyzed and processed streams.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: hasAcceleration
                ? LineChart(
                    LineChartData(
                      minY: minAcc - 0.1,
                      maxY: max(maxAcc + 0.1, minAcc + 0.2),
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
                            'α (deg/s²)',
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
                            'Sample index',
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
                          spots: _analyzedAccelerationData,
                          isCurved: true,
                          color: const Color(0xFF7C3AED),
                          barWidth: 2.4,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: _processedAccelerationData,
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
                      'Waiting for acceleration rate...',
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(color: Color(0xFF7C3AED), label: 'Analyzed α'),
              _LegendItem(color: Color(0xFFEF4444), label: 'Processed α'),
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
    final snapshot = _latestAnalyzedSnapshot;
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Analyzed Profile Radar',
            Icons.radar_outlined,
          ),
          const SizedBox(height: 8),
          if (snapshot == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  'Waiting for analytics-live profile data...',
                  style: TextStyle(color: _mutedTextColor(context)),
                ),
              ),
            )
          else ...[
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
                      'Roll',
                      'Pitch',
                      'Tilt',
                      'H-Mag',
                      '|X|',
                      '|Y|',
                      '|Z|',
                    ];
                    return RadarChartTitle(
                      text: titles[index],
                      angle: angle,
                    );
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor:
                          Theme.of(context).colorScheme.primary.withValues(
                                alpha: 0.20,
                              ),
                      borderColor: Theme.of(context).colorScheme.primary,
                      borderWidth: 2.2,
                      entryRadius: 3.2,
                      dataEntries: [
                        RadarEntry(
                            value: _radarScale(snapshot.roll?.abs(), 15)),
                        RadarEntry(
                            value: _radarScale(snapshot.pitch?.abs(), 15)),
                        RadarEntry(
                            value: _radarScale(snapshot.tilt?.abs(), 15)),
                        RadarEntry(
                          value: _radarScale(
                            snapshot.horizontalMagnitude?.abs(),
                            1.0,
                          ),
                        ),
                        RadarEntry(value: _radarScale(snapshot.x.abs(), 1.0)),
                        RadarEntry(value: _radarScale(snapshot.y.abs(), 1.0)),
                        RadarEntry(value: _radarScale(snapshot.z.abs(), 2.0)),
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
                _valueChip(
                  context,
                  'Roll',
                  snapshot.roll?.toStringAsFixed(3) ?? '--',
                ),
                _valueChip(
                  context,
                  'Pitch',
                  snapshot.pitch?.toStringAsFixed(3) ?? '--',
                ),
                _valueChip(
                  context,
                  'Tilt',
                  snapshot.tilt?.toStringAsFixed(3) ?? '--',
                ),
                _valueChip(
                  context,
                  'H-Mag',
                  snapshot.horizontalMagnitude?.toStringAsFixed(4) ?? '--',
                ),
                _valueChip(context, 'X', snapshot.x.toStringAsFixed(5)),
                _valueChip(context, 'Y', snapshot.y.toStringAsFixed(5)),
                _valueChip(context, 'Z', snapshot.z.toStringAsFixed(5)),
                _valueChip(context, 'Alerts', snapshot.alertCount.toString()),
                _valueChip(
                  context,
                  'Sensor',
                  snapshot.sensorId.isEmpty ? '--' : snapshot.sensorId,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _historicalTrendCard(BuildContext context) {
    final hasData = _processedMagnitudeData.isNotEmpty;
    final minY = hasData
        ? (_processedMagnitudeData.map((e) => e.y).reduce(min) - 0.3)
        : 0.0;
    final maxY = hasData
        ? (_processedMagnitudeData.map((e) => e.y).reduce(max) + 0.3)
        : 1.0;
    final maxX = hasData ? _processedMagnitudeData.last.x : 65.0;

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
              context, 'Magnitude Trend (Processed)', Icons.trending_up),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX <= 0 ? 1 : maxX,
                      minY: minY,
                      maxY: maxY <= minY ? minY + 1 : maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval:
                            ((maxY - minY).abs() / 8).clamp(0.05, 10.0),
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
                            'Magnitude',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2930),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval:
                                ((maxY - minY).abs() / 5).clamp(0.1, 20.0),
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
                            'Processed Samples',
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
                          spots: _processedMagnitudeData,
                          isCurved: true,
                          color: const Color(0xFF111D8A),
                          barWidth: 2.0,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('Waiting for processed magnitude...')),
          ),
        ],
      ),
    );
  }

  Widget _statusDistributionCard(BuildContext context, dynamic db) {
    final alerts = _activeAlerts(db);
    var sensorFaults = 0;
    var deviceFaults = 0;
    var otherFaults = 0;

    for (final alert in alerts) {
      if (_isDeviceFaultAlert(alert)) {
        deviceFaults++;
      } else if (_isSensorFaultAlert(alert)) {
        sensorFaults++;
      } else {
        otherFaults++;
      }
    }

    if (alerts.isEmpty) {
      otherFaults = 1;
    }

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Open Fault Distribution',
            Icons.memory_outlined,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: sensorFaults.toDouble(),
                    color: const Color(0xFFd39a00),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: deviceFaults.toDouble(),
                    color: const Color(0xFFea3e43),
                    title: '',
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: otherFaults.toDouble(),
                    color: const Color(0xFF0ca15f),
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
              _LegendItem(color: Color(0xFFd39a00), label: 'Sensor faults'),
              _LegendItem(color: Color(0xFFea3e43), label: 'Device faults'),
              _LegendItem(color: Color(0xFF0ca15f), label: 'Other alerts'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiltPatternCard(BuildContext context) {
    final bars = _processedZData.length > 24
        ? _processedZData.sublist(_processedZData.length - 24)
        : _processedZData;
    final maxTilt = bars.isEmpty
        ? 2.0
        : max(2.0, bars.map((e) => e.y.abs()).reduce(max) + 0.5);

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
                maxY: maxTilt,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxTilt / 4).clamp(0.5, 10.0),
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
                      '|Tilt| (°)',
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
                      'Recent sample index',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2930),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            fontSize: 10, color: _mutedTextColor(context)),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(bars.length, (i) {
                  final value = bars[i].y.abs();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value,
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

  Widget _thresholdMonitoringCard(BuildContext context, dynamic db) {
    final sensorAlertCounts = <String, int>{};
    for (final alert in _activeAlerts(db)) {
      final sensorId = _safeText(alert.sensorId, fallback: '').trim();
      if (sensorId.isEmpty) continue;
      sensorAlertCounts[sensorId] = (sensorAlertCounts[sensorId] ?? 0) + 1;
    }

    final bars = sensorAlertCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });
    final topBars = bars.take(7).toList(growable: false);
    final maxBar = topBars.isEmpty
        ? 3.0
        : max(
            3.0,
            topBars.map((entry) => entry.value).reduce(max).toDouble() + 1,
          );

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Escalation Queue By Sensor',
            Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: topBars.isEmpty
                ? Center(
                    child: Text(
                      'No escalations pending in active alerts.',
                      style: TextStyle(color: _mutedTextColor(context)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxBar,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxBar / 5).clamp(1.0, 20.0),
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
                            'Open alerts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2930),
                            ),
                          ),
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 34),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text(
                            'Sensors',
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
                                  if (i < 0 || i >= topBars.length) {
                                    return '--';
                                  }
                                  final sensorId = topBars[i].key;
                                  return sensorId.length > 6
                                      ? sensorId.substring(sensorId.length - 6)
                                      : sensorId;
                                }(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _mutedTextColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      barGroups: List.generate(topBars.length, (i) {
                        final value = topBars[i].value;
                        final color = value >= 3
                            ? const Color(0xFFea3e43)
                            : value >= 2
                                ? const Color(0xFFd39a00)
                                : const Color(0xFF0ca15f);
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: value.toDouble(),
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
    final points = <ScatterSpot>[];
    final start = max(0, _processedXData.length - 40);
    for (int i = start; i < _processedXData.length; i++) {
      points.add(
        ScatterSpot(
          _processedXData[i].y,
          i < _processedYData.length ? _processedYData[i].y : 0,
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
          _panelTitle(context, 'X & Y Axis Analysis', Icons.multiline_chart),
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
                      'Pitch (°)',
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
                      'Roll (°)',
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
                'Waiting for processed X/Y data...',
                style: TextStyle(color: _mutedTextColor(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorReadingsCard(BuildContext context) {
    final db = ref.watch(engineerDatabaseChangeNotifierProvider);
    final thresholds = _dashboardThresholds(db);
    final sensors = List.of(db.sensors);
    final devices = List.of(db.devices);
    final sites = List.of(db.sites);
    final zones = List.of(db.zones);
    final sensorOptions = <({String id, String label})>[];
    for (final sensor in sensors) {
      final sensorId = _safeText(sensor.id, fallback: '').trim();
      if (sensorId.isEmpty) continue;
      final serial = _safeText(sensor.serialNumber, fallback: '').trim();
      final shortId =
          sensorId.length > 8 ? '${sensorId.substring(0, 8)}…' : sensorId;
      final label = serial.isEmpty ? shortId : '$serial • $shortId';
      sensorOptions.add((id: sensorId, label: label));
    }
    sensorOptions.sort((a, b) => a.label.compareTo(b.label));
    final hasSelectedSensor = sensorOptions.any(
      (item) => item.id == _selectedSensorId,
    );
    final effectiveSelectedId =
        hasSelectedSensor ? _selectedSensorId : _allSensorsValue;

    final sensorById = <String, dynamic>{};
    for (final sensor in sensors) {
      final sensorId = _safeText(sensor.id, fallback: '').trim();
      if (sensorId.isNotEmpty) sensorById[sensorId] = sensor;
    }

    final deviceById = <String, dynamic>{};
    for (final device in devices) {
      final deviceId = _safeText(device.id, fallback: '').trim();
      if (deviceId.isNotEmpty) deviceById[deviceId] = device;
    }

    final siteById = <String, dynamic>{};
    for (final site in sites) {
      final siteId = _safeText(site.id, fallback: '').trim();
      if (siteId.isNotEmpty) siteById[siteId] = site;
    }

    final zoneById = <String, dynamic>{};
    for (final zone in zones) {
      final zoneId = _safeText(zone.id, fallback: '').trim();
      if (zoneId.isNotEmpty) zoneById[zoneId] = zone;
    }

    final highestAlertBySensor = _sensorHighestAlertLevel(db);

    final rows = _processedSnapshots.reversed
        .where((snapshot) {
          final sensorId = snapshot.sensorId.trim();
          return effectiveSelectedId == _allSensorsValue ||
              sensorId == effectiveSelectedId;
        })
        .take(8)
        .map((snapshot) {
      final shortId = snapshot.sensorId.length > 12
          ? '${snapshot.sensorId.substring(0, 12)}…'
          : snapshot.sensorId;
      final sensor = sensorById[snapshot.sensorId];
      final deviceId = _safeText(sensor?.deviceId, fallback: '').trim();
      final device = deviceById[deviceId];
      final siteId = _safeText(device?.siteId, fallback: '').trim();
      final zoneId = _safeText(device?.zoneId, fallback: '').trim();
      final siteName = _safeText(siteById[siteId]?.name);
      final zoneName = _safeText(zoneById[zoneId]?.name);
      final status = highestAlertBySensor[snapshot.sensorId] ??
          _levelForTilt(snapshot.tilt.abs(), thresholds);
      return [
        shortId,
        siteName,
        zoneName,
        '${snapshot.roll.toStringAsFixed(2)}°',
        '${snapshot.pitch.toStringAsFixed(2)}°',
        '${snapshot.tilt.toStringAsFixed(2)}°',
        status,
        _agoLabel(snapshot.receivedAt),
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
                'Live Sensor Fault Feed',
                Icons.show_chart_outlined,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFd6e1e6)
                      : const Color(0xFF23394A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: effectiveSelectedId,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _mutedTextColor(context),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: _allSensorsValue,
                        child: Text('All sensors'),
                      ),
                      ...sensorOptions.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: SizedBox(
                            width: 180,
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSensorId = value ?? _allSensorsValue;
                      });
                    },
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _mutedTextColor(context),
                    ),
                  ),
                ),
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
                  _tableHeading(context, 'Site'),
                  _tableHeading(context, 'Zone'),
                  _tableHeading(context, 'Roll (°)'),
                  _tableHeading(context, 'Pitch (°)'),
                  _tableHeading(context, 'Tilt (°)'),
                  _tableHeading(context, 'Status'),
                  _tableHeading(context, 'Last Update'),
                ],
                rows: rows.map((r) {
                  final status = _safeText(r[6], fallback: 'normal');
                  final normalizedStatus = _normalizeAlertLevel(status);
                  final isCritical = normalizedStatus == 'critical' ||
                      normalizedStatus == 'emergency';
                  final isWarning = !isCritical &&
                      (normalizedStatus == 'high' ||
                          normalizedStatus == 'warning');
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
                        _statusLabel(normalizedStatus),
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
                'Waiting for processed stream data...',
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
    final totalDevices = _installedDevicesCount(db);
    final onlineDevices = _onlineDeviceCount(db);
    final liveSensors = _processedSensorIds.length;
    final deviceFaults = _deviceFaultCount(db);
    final sensorFaults = _sensorFaultCount(db);
    final escalations = _escalationCount(db);
    final recentDeviceInstalls = _installedDevicesInDays(db, days: 30);
    final recentSensorInstalls = _installedSensorsInDays(db, days: 30);
    final availability =
        totalDevices == 0 ? 0.0 : (onlineDevices / totalDevices) * 100;
    final totalFaults = deviceFaults + sensorFaults;

    final cards = [
      _MiniStatData(
        title: 'ONLINE DEVICES',
        value: onlineDevices.toString(),
        unit: '/$totalDevices',
        detail: '${availability.toStringAsFixed(0)}% fleet availability',
        badge: onlineDevices > 0 ? 'Live' : 'Idle',
        icon: Icons.router_outlined,
        iconColor: const Color(0xFF5f78de),
      ),
      _MiniStatData(
        title: 'LIVE SENSORS',
        value: liveSensors.toString(),
        unit: 'sensors',
        detail: '$recentSensorInstalls installed in last 30 days',
        badge: liveSensors > 0 ? 'Live' : 'Idle',
        icon: Icons.monitor_heart_outlined,
        iconColor: const Color(0xFF0aa34f),
      ),
      _MiniStatData(
        title: 'OPEN FAULTS',
        value: totalFaults.toString(),
        unit: 'cases',
        detail: '$sensorFaults sensor + $deviceFaults device faults',
        badge: totalFaults > 0 ? 'Action' : 'Stable',
        icon: Icons.engineering_outlined,
        iconColor: const Color(0xFFd39a00),
      ),
      _MiniStatData(
        title: 'ESCALATION QUEUE',
        value: escalations.toString(),
        unit: 'alerts',
        detail: '$recentDeviceInstalls device installs in last 30 days',
        badge: escalations > 0 ? 'Urgent' : 'Normal',
        icon: Icons.report_problem_outlined,
        iconColor: const Color(0xFFe54c4c),
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
    // Prefer live processed tilt stream; fallback to backend sensor snapshots.
    final readings = _processedZData.isNotEmpty
        ? _processedZData.map((spot) => spot.y.abs()).toList()
        : (db.sensors as List)
            .map((sensor) => (sensor.lastReading as num).abs().toDouble())
            .toList();
    final bins = [0, 0, 0, 0];
    for (final value in readings) {
      // Real stream values are commonly around 6-10 degrees, so use
      // operationally meaningful bands instead of sub-degree bins.
      if (value < 2.0) {
        bins[0]++;
      } else if (value < 5.0) {
        bins[1]++;
      } else if (value < 10.0) {
        bins[2]++;
      } else {
        bins[3]++;
      }
    }
    final labels = ['0-2°', '2-5°', '5-10°', '>10°'];
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
            _processedZData.isNotEmpty
                ? 'Shows distribution from live processed tilt stream.'
                : 'Shows distribution from last known sensor readings.',
            style: TextStyle(fontSize: 12, color: _mutedTextColor(context)),
          ),
          const SizedBox(height: 12),
          if (readings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Waiting for tilt data...',
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

  Widget _buildDeepAnalysisCard(BuildContext context, dynamic db) {
    final activeAlerts = _activeAlerts(db);
    final totalDevices = _installedDevicesCount(db);
    final onlineDevices = _onlineDeviceCount(db);
    final totalSensors = db.sensors is List ? (db.sensors as List).length : 0;
    final liveSensors = _processedSensorIds.length;
    final deviceFaults = _deviceFaultCount(db);
    final sensorFaults = _sensorFaultCount(db);
    final escalations = _escalationCount(db);
    final recentDeviceInstalls = _installedDevicesInDays(db, days: 30);
    final recentSensorInstalls = _installedSensorsInDays(db, days: 30);

    final openAges = <Duration>[];
    final now = DateTime.now();
    for (final alert in activeAlerts) {
      final triggeredAt = _parseDateTime(alert.triggeredAt);
      if (triggeredAt == null) continue;
      final age = now.difference(triggeredAt);
      openAges.add(age.isNegative ? Duration.zero : age);
    }

    final averageOpenAge = openAges.isEmpty
        ? Duration.zero
        : Duration(
            minutes: (openAges
                        .map((age) => age.inMinutes.toDouble())
                        .reduce((a, b) => a + b) /
                    openAges.length)
                .round(),
          );
    final oldestOpenAge = openAges.isEmpty
        ? Duration.zero
        : openAges.reduce(
            (a, b) => a.compareTo(b) >= 0 ? a : b,
          );

    final availabilityPct =
        totalDevices == 0 ? 0.0 : (onlineDevices / totalDevices) * 100;
    final liveCoveragePct =
        totalSensors == 0 ? 0.0 : (liveSensors / totalSensors) * 100;
    final escalationPressure =
        activeAlerts.isEmpty ? 0.0 : (escalations / activeAlerts.length) * 100;

    final insights = <String>[
      'Installation footprint: $totalDevices devices deployed, with $recentDeviceInstalls new installs in the last 30 days.',
      'Fault backlog: $sensorFaults sensor faults and $deviceFaults device faults are currently open for engineer action.',
      'Escalation pressure: $escalations escalated alerts (${escalationPressure.toStringAsFixed(0)}% of open alerts).',
      'Response latency: average open age ${_durationLabel(averageOpenAge)}; oldest unresolved case ${_durationLabel(oldestOpenAge)}.',
      'Live coverage: $onlineDevices/$totalDevices devices online (${availabilityPct.toStringAsFixed(0)}%) and $liveSensors/$totalSensors sensors reporting (${liveCoveragePct.toStringAsFixed(0)}%).',
      'Install trend: $recentSensorInstalls sensors were installed in the last 30 days.',
    ];

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle(
            context,
            'Engineer Operations Analysis',
            Icons.insights_outlined,
          ),
          const SizedBox(height: 10),
          Text(
            'Operational diagnostics focused on install velocity, fault backlog, escalation pressure, and service response.',
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

  (double, double) _dashboardThresholds(dynamic db) {
    final rules = db
        .thresholdRulesForGraph(
            ThresholdGraphTarget.dashboardThresholdMonitoring)
        .map((rule) => rule.value)
        .toList()
      ..sort();
    final warning = rules.isNotEmpty ? rules.first : 2.8;
    final critical = rules.length > 1 ? rules[1] : warning + 1.2;
    return (warning, critical);
  }

  String _levelForTilt(double value, (double, double) thresholds) {
    if (value >= thresholds.$2) return 'critical';
    if (value >= thresholds.$1) return 'warning';
    return 'normal';
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
