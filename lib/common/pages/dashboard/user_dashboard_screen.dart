import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../../platform/models/sensor.dart';
import '../../platform/api/users_api.dart';
import '../../platform/providers/super_admin_backend_provider.dart';
import '../../platform/providers/super_admin_riverpod_provider.dart';
import '../../platform/services/generic_sse_service.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key, this.embeddedScroll = false});

  final bool embeddedScroll;

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  final List<FlSpot> _rawXData = <FlSpot>[];
  final List<FlSpot> _rawYData = <FlSpot>[];
  final List<FlSpot> _rawZData = <FlSpot>[];
  final List<FlSpot> _processedRollData = <FlSpot>[];
  final List<FlSpot> _processedPitchData = <FlSpot>[];
  final List<FlSpot> _processedTiltData = <FlSpot>[];
  final List<FlSpot> _analyzedRollData = <FlSpot>[];
  final List<FlSpot> _analyzedPitchData = <FlSpot>[];
  final List<FlSpot> _analyzedTiltData = <FlSpot>[];
  final List<FlSpot> _processedVelocityData = <FlSpot>[];
  final List<FlSpot> _processedAccelerationData = <FlSpot>[];
  final List<FlSpot> _analyzedVelocityData = <FlSpot>[];
  final List<FlSpot> _analyzedAccelerationData = <FlSpot>[];

  GenericSseService? _rawSseService;
  GenericSseService? _processedSseService;
  GenericSseService? _analyticsSseService;
  StreamSubscription<dynamic>? _rawSubscription;
  StreamSubscription<dynamic>? _processedSubscription;
  StreamSubscription<dynamic>? _analyticsSubscription;

  int _rawIndex = 0;
  int _processedIndex = 0;
  int _analyzedIndex = 0;

  double? _previousProcessedTilt;
  double? _previousProcessedTimestampSec;
  double? _previousProcessedVelocity;
  double? _previousAnalyzedTilt;
  double? _previousAnalyzedTimestamp;
  double? _previousAnalyzedVelocity;

  DateTime? _lastProcessedAt;
  DateTime? _lastAnalyzedAt;
  String _rawEndpointPath = '/api/v1/ingestion/readings/live';
  String _processedEndpointPath = '/api/v1/processing/readings/live';
  String _analyticsEndpointPath = '/api/v1/analytics/events/live';
  String _sensorName = 'Workspace Sensor';
  String _primarySensorId = '';
  Set<String> _assignedSensorIds = <String>{};
  bool _sensorAccessLoaded = false;
  String? _sensorAccessError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await _primeDashboardData();
    await _connectStreams();
  }

  Future<void> _primeDashboardData() async {
    final db = ref.read(superAdminBackendChangeNotifierProvider);
    List<String> assignedSensorIds = const [];
    String? sensorAccessError;
    try {
      await Future.wait([
        db.loadDevices(),
        db.loadSensors(),
        db.loadSites(),
      ]);
      assignedSensorIds = await UsersApi.getMySensorAccess();
    } catch (_) {
      // Keep the dashboard usable even if one preload fails.
      sensorAccessError = 'Unable to load assigned sensor access.';
    }

    final assignedSet = assignedSensorIds.map((id) => id.trim()).where((id) {
      return id.isNotEmpty;
    }).toSet();
    final scopedSensors = _scopedSensorsFrom(
      db.sensors,
      assignedSet,
    );
    final sensor = _primarySensor(scopedSensors);

    if (mounted) {
      setState(() {
        _assignedSensorIds = assignedSet;
        _sensorAccessLoaded = true;
        _sensorAccessError = sensorAccessError;
      });
    }

    if (scopedSensors.isEmpty) {
    _sensorName = sensorAccessError == null
        ? 'No assigned sensors'
        : 'Sensor access unavailable';
      _primarySensorId = '';
      _rawEndpointPath = '';
      _processedEndpointPath = '';
      _analyticsEndpointPath = '';
      return;
    }

    _sensorName = _sensorLabel(sensor);
    _primarySensorId = sensor.id.trim();
    _rawEndpointPath = _resolveLivePath(
      explicitPath: sensor.ingestionLiveEndpoint,
      fallbackPath: sensor.endpointKey.trim().isEmpty
          ? '/api/v1/ingestion/readings/live'
          : '/api/v1/ingestion/readings/live/${sensor.endpointKey.trim()}',
    );
    // These exact live endpoints are permit-all in backend security config.
    // The sensor-scoped /{endpointKey} variants require auth/role checks and
    // can reject normal user tokens, so we subscribe to the public feeds and
    // filter events locally to the assigned primary sensor.
    _processedEndpointPath = '/api/v1/processing/readings/live';
    _analyticsEndpointPath = '/api/v1/analytics/events/live';
  }

  Sensor _primarySensor(List<Sensor> sensors) {
    return sensors.firstWhere(
      (sensor) =>
          sensor.ingestionLiveEndpoint.trim().isNotEmpty ||
          sensor.processingLiveEndpoint.trim().isNotEmpty ||
          sensor.analyticsLiveEndpoint.trim().isNotEmpty ||
          sensor.endpointKey.trim().isNotEmpty,
      orElse: () => Sensor(
        id: '',
        deviceId: '',
        sensorTypeId: '',
        name: '',
        serialNumber: '',
        installedAt: DateTime.fromMillisecondsSinceEpoch(0),
        lastReading: 0,
      ),
    );
  }

  String _sensorLabel(Sensor sensor) {
    if (sensor.name.trim().isNotEmpty) return sensor.name.trim();
    if (sensor.serialNumber.trim().isNotEmpty) return sensor.serialNumber.trim();
    return 'Workspace Sensor';
  }

  Future<void> _connectStreams() async {
    if (_rawEndpointPath.isEmpty &&
        _processedEndpointPath.isEmpty &&
        _analyticsEndpointPath.isEmpty) {
      return;
    }
    await _disconnectStreams();

    _rawSseService = GenericSseService(_rawEndpointPath);
    _processedSseService = GenericSseService(_processedEndpointPath);
    _analyticsSseService = GenericSseService(_analyticsEndpointPath);

    await _rawSseService!.connect();
    _rawSubscription = _rawSseService!.stream.listen((data) {
      if (!mounted) return;
      if (!_matchesPrimarySensor(data)) return;
      final xyz = _extractRawXyz(data);
      if (xyz == null) return;
      setState(() {
        _appendPoint(_rawXData, _rawIndex, xyz.$1);
        _appendPoint(_rawYData, _rawIndex, xyz.$2);
        _appendPoint(_rawZData, _rawIndex, xyz.$3);
        _rawIndex = _rawXData.length;
      });
    });

    await _processedSseService!.connect();
    _processedSubscription = _processedSseService!.stream.listen((data) {
      if (!mounted) return;
      if (!_matchesPrimarySensor(data)) return;
      final snapshot = _extractProcessedSnapshot(data);
      if (snapshot == null) return;
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final dt = (_previousProcessedTimestampSec == null)
          ? null
          : nowSec - _previousProcessedTimestampSec!;
      final velocity =
          (_previousProcessedTilt == null || dt == null || dt <= 0)
              ? 0.0
              : (snapshot.tilt - _previousProcessedTilt!) / dt;
      final acceleration =
          (_previousProcessedVelocity == null || dt == null || dt <= 0)
              ? 0.0
              : (velocity - _previousProcessedVelocity!) / dt;

      setState(() {
        _appendPoint(_processedRollData, _processedIndex, snapshot.roll);
        _appendPoint(_processedPitchData, _processedIndex, snapshot.pitch);
        _appendPoint(_processedTiltData, _processedIndex, snapshot.tilt);
        _appendPoint(_processedVelocityData, _processedIndex, velocity);
        _appendPoint(_processedAccelerationData, _processedIndex, acceleration);
        _processedIndex = _processedTiltData.length;
        _previousProcessedTilt = snapshot.tilt;
        _previousProcessedTimestampSec = nowSec;
        _previousProcessedVelocity = velocity;
        _lastProcessedAt = snapshot.receivedAt;
      });
    });

    await _analyticsSseService!.connect();
    _analyticsSubscription = _analyticsSseService!.stream.listen((data) {
      if (!mounted) return;
      if (!_matchesPrimarySensor(data)) return;
      final snapshot = _extractAnalyzedSnapshot(data);
      if (snapshot == null) return;
      final dt = (_previousAnalyzedTimestamp == null)
          ? null
          : _deltaSeconds(snapshot.timestamp - _previousAnalyzedTimestamp!);
      final velocity =
          (_previousAnalyzedTilt == null || dt == null || dt <= 0)
              ? 0.0
              : (snapshot.tilt - _previousAnalyzedTilt!) / dt;
      final acceleration =
          (_previousAnalyzedVelocity == null || dt == null || dt <= 0)
              ? 0.0
              : (velocity - _previousAnalyzedVelocity!) / dt;

      setState(() {
        _appendPoint(_analyzedRollData, _analyzedIndex, snapshot.roll);
        _appendPoint(_analyzedPitchData, _analyzedIndex, snapshot.pitch);
        _appendPoint(_analyzedTiltData, _analyzedIndex, snapshot.tilt);
        _appendPoint(_analyzedVelocityData, _analyzedIndex, velocity);
        _appendPoint(
          _analyzedAccelerationData,
          _analyzedIndex,
          acceleration,
        );
        _analyzedIndex = _analyzedTiltData.length;
        _previousAnalyzedTilt = snapshot.tilt;
        _previousAnalyzedTimestamp = snapshot.timestamp;
        _previousAnalyzedVelocity = velocity;
        _lastAnalyzedAt = DateTime.now();
      });
    });
  }

  Future<void> _disconnectStreams() async {
    await _rawSubscription?.cancel();
    await _processedSubscription?.cancel();
    await _analyticsSubscription?.cancel();
    _rawSubscription = null;
    _processedSubscription = null;
    _analyticsSubscription = null;
    _rawSseService?.dispose();
    _processedSseService?.dispose();
    _analyticsSseService?.dispose();
    _rawSseService = null;
    _processedSseService = null;
    _analyticsSseService = null;
  }

  void _appendPoint(List<FlSpot> points, int index, double value) {
    points.add(FlSpot(index.toDouble(), value));
    while (points.length > 65) {
      points.removeAt(0);
    }
    for (var i = 0; i < points.length; i++) {
      points[i] = FlSpot(i.toDouble(), points[i].y);
    }
  }

  (double, double, double)? _extractRawXyz(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final rawPayload = map['rawPayload'];
      if (rawPayload is Map) {
        final params = rawPayload['parameters'];
        if (params is Map) {
          final x = _toDouble(params['x']);
          final y = _toDouble(params['y']);
          final z = _toDouble(params['z']);
          if (x != null && y != null && z != null) {
            return (x, y, z);
          }
        }
      }

      final params = map['parameters'];
      if (params is Map) {
        final x = _toDouble(params['x']);
        final y = _toDouble(params['y']);
        final z = _toDouble(params['z']);
        if (x != null && y != null && z != null) {
          return (x, y, z);
        }
      }

      final x = _toDouble(map['x']);
      final y = _toDouble(map['y']);
      final z = _toDouble(map['z']);
      if (x != null && y != null && z != null) {
        return (x, y, z);
      }
    }
    return null;
  }

  bool _matchesPrimarySensor(dynamic payload) {
    final expectedSensorId = _primarySensorId.trim();
    if (expectedSensorId.isEmpty) return true;
    for (final map in _candidateMaps(payload)) {
      final sensorId = _sensorIdFromMap(map);
      if (sensorId == expectedSensorId) {
        return true;
      }
    }
    return false;
  }

  String? _sensorIdFromMap(Map<String, dynamic> map) {
    final direct = (map['sensorId'] ?? map['sensor_id'])?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final rawPayload = map['rawPayload'];
    if (rawPayload is Map) {
      final rawSensorId =
          (rawPayload['sensorId'] ?? rawPayload['sensor_id'])?.toString().trim();
      if (rawSensorId != null && rawSensorId.isNotEmpty) return rawSensorId;
    }

    final processedPayload = map['processedPayload'];
    if (processedPayload is Map) {
      final processedSensorId =
          (processedPayload['sensorId'] ?? processedPayload['sensor_id'])
              ?.toString()
              .trim();
      if (processedSensorId != null && processedSensorId.isNotEmpty) {
        return processedSensorId;
      }
    }

    final nestedEvent = map['event'];
    if (nestedEvent is Map) {
      final nestedSensorId =
          (nestedEvent['sensorId'] ?? nestedEvent['sensor_id'])
              ?.toString()
              .trim();
      if (nestedSensorId != null && nestedSensorId.isNotEmpty) {
        return nestedSensorId;
      }
    }

    return null;
  }

  _ProcessedSnapshot? _extractProcessedSnapshot(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final processed = map['processedPayload'];
      if (processed is! Map) continue;

      final tiltPayload =
          processed['tilt'] is Map ? processed['tilt'] as Map : null;
      final inclinoPayload = processed['inclinometer'] is Map
          ? processed['inclinometer'] as Map
          : null;

      final roll = _firstDouble([
        processed['rollDegrees'],
        tiltPayload?['rollDegrees'],
        processed['roll'],
        tiltPayload?['roll'],
        processed['x'],
        tiltPayload?['x'],
      ]);
      final pitch = _firstDouble([
        processed['pitchDegrees'],
        tiltPayload?['pitchDegrees'],
        processed['pitch'],
        tiltPayload?['pitch'],
        processed['y'],
        tiltPayload?['y'],
      ]);
      final tilt = _firstDouble([
        processed['tiltFromVerticalDegrees'],
        tiltPayload?['tiltFromVerticalDegrees'],
        processed['inclinationDegrees'],
        inclinoPayload?['inclinationDegrees'],
        processed['tiltDegrees'],
        tiltPayload?['tiltDegrees'],
        processed['tilt'],
        processed['z'],
        tiltPayload?['z'],
        inclinoPayload?['z'],
      ]);
      if (roll == null || pitch == null || tilt == null) continue;

      return _ProcessedSnapshot(
        roll: roll,
        pitch: pitch,
        tilt: tilt,
        receivedAt: DateTime.now(),
      );
    }
    return null;
  }

  _AnalyzedSnapshot? _extractAnalyzedSnapshot(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final values = <String, double>{};

      final series = map['series'];
      if (series is List) {
        for (final item in series) {
          if (item is! Map) continue;
          final name = item['name']?.toString();
          final value = _toDouble(item['value']);
          if (name == null || value == null) continue;
          values[name] = value;
        }
      }

      final evaluations = map['evaluations'];
      if (evaluations is List) {
        for (final item in evaluations) {
          if (item is! Map) continue;
          final name = item['parameterName']?.toString() ??
              item['name']?.toString();
          final value = _toDouble(item['value']);
          if (name == null || value == null) continue;
          values[name] = value;
        }
      }

      final processedPayload = map['processedPayload'] is Map
          ? map['processedPayload'] as Map<dynamic, dynamic>
          : null;
      final tiltPayload = processedPayload != null &&
              processedPayload['tilt'] is Map
          ? processedPayload['tilt'] as Map<dynamic, dynamic>
          : null;
      final inclinoPayload = processedPayload != null &&
              processedPayload['inclinometer'] is Map
          ? processedPayload['inclinometer'] as Map<dynamic, dynamic>
          : null;

      final roll = _firstDouble([
        values['rollDegrees'],
        values['roll'],
        values['tilt.rollDegrees'],
        values['processedPayload.rollDegrees'],
        values['processedPayload.tilt.rollDegrees'],
        processedPayload?['rollDegrees'],
        tiltPayload?['rollDegrees'],
        processedPayload?['x'],
        tiltPayload?['x'],
      ]);
      final pitch = _firstDouble([
        values['pitchDegrees'],
        values['pitch'],
        values['tilt.pitchDegrees'],
        values['processedPayload.pitchDegrees'],
        values['processedPayload.tilt.pitchDegrees'],
        processedPayload?['pitchDegrees'],
        tiltPayload?['pitchDegrees'],
        processedPayload?['y'],
        tiltPayload?['y'],
      ]);
      final tilt = _firstDouble([
        values['tiltFromVerticalDegrees'],
        values['inclinationDegrees'],
        values['tilt'],
        values['tilt.tiltFromVerticalDegrees'],
        values['inclinometer.inclinationDegrees'],
        values['processedPayload.tiltFromVerticalDegrees'],
        values['processedPayload.inclinationDegrees'],
        values['processedPayload.tilt.tiltFromVerticalDegrees'],
        values['processedPayload.inclinometer.inclinationDegrees'],
        processedPayload?['tiltFromVerticalDegrees'],
        tiltPayload?['tiltFromVerticalDegrees'],
        processedPayload?['inclinationDegrees'],
        inclinoPayload?['inclinationDegrees'],
        processedPayload?['z'],
        tiltPayload?['z'],
      ]);
      if (roll == null || pitch == null || tilt == null) continue;

      final timestamp = _toDouble(map['timestamp']) ??
          _toDouble(map['eventTime']) ??
          DateTime.now().millisecondsSinceEpoch / 1000.0;

      return _AnalyzedSnapshot(
        roll: roll,
        pitch: pitch,
        tilt: tilt,
        timestamp: timestamp,
      );
    }
    return null;
  }

  double? _firstDouble(List<dynamic> values) {
    for (final value in values) {
      final parsed = _toDouble(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  Iterable<Map<String, dynamic>> _candidateMaps(
    dynamic payload, {
    int depth = 0,
  }) sync* {
    if (payload == null || depth > 6) return;

    if (payload is Map<String, dynamic>) {
      yield payload;
      for (final key in const [
        'body',
        'data',
        'payload',
        'event',
        'rawPayload',
        'processedPayload',
        'parameters',
      ]) {
        final next = payload[key];
        if (next != null) {
          yield* _candidateMaps(next, depth: depth + 1);
        }
      }
      return;
    }

    if (payload is Map) {
      yield* _candidateMaps(payload.cast<String, dynamic>(), depth: depth);
      return;
    }

    if (payload is List) {
      for (final item in payload) {
        yield* _candidateMaps(item, depth: depth + 1);
      }
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double? _deltaSeconds(double rawDelta) {
    if (rawDelta <= 0) return null;
    if (rawDelta > 1000) return rawDelta / 1000.0;
    return rawDelta;
  }

  @override
  void dispose() {
    _disconnectStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final scopedSensors = _scopedSensors(db);
    final scopedAlerts = _scopedActiveAlerts(db);
    final scopedDeviceIds = scopedSensors.map((sensor) => sensor.deviceId).toSet();
    final assignedDevices = db.devices
        .where((device) => scopedDeviceIds.contains(device.id))
        .toList();
    final scopedSiteIds = assignedDevices
        .map((device) => device.siteId.trim())
        .where((siteId) => siteId.isNotEmpty)
        .toSet();

    final activeAlerts = scopedAlerts.length;
    final avgTilt =
        _averageAbsolute(_processedTiltData) ?? _averageSensorReading(scopedSensors);
    final maxTilt =
        _maxAbsolute(_processedTiltData) ?? _maxSensorReading(scopedSensors);
    final latestTilt = _processedTiltData.isNotEmpty
        ? _processedTiltData.last.y
        : _analyzedTiltData.isNotEmpty
            ? _analyzedTiltData.last.y
            : null;
    final latestVelocity = _processedVelocityData.isNotEmpty
        ? _processedVelocityData.last.y
        : _analyzedVelocityData.isNotEmpty
            ? _analyzedVelocityData.last.y
            : null;
    final latestAcceleration = _processedAccelerationData.isNotEmpty
        ? _processedAccelerationData.last.y
        : _analyzedAccelerationData.isNotEmpty
            ? _analyzedAccelerationData.last.y
            : null;
    final systemHealth =
        (100 - (activeAlerts * 6) - ((latestTilt?.abs() ?? 0) * 1.8))
            .clamp(0, 100)
            .toDouble();
    final showNoAssignmentState =
        _sensorAccessLoaded && _assignedSensorIds.isEmpty && _sensorAccessError == null;

    final content = OpsPage(
      title: 'Dashboard',
      subtitle: _sensorAccessError != null
          ? 'Assigned sensor access could not be loaded'
          : showNoAssignmentState
              ? 'No sensors are assigned to this user yet'
              : 'Live telemetry for sensors assigned to this user',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.sensors_outlined, size: 16),
          label: Text(_sensorName),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(_agoLabel(_lastProcessedAt ?? _lastAnalyzedAt)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sensorAccessError != null || showNoAssignmentState)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OpsColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OpsColors.border),
              ),
              child: Text(
                _sensorAccessError ??
                    'This user has no assigned sensors, so the dashboard is waiting for access to be granted.',
                style: const TextStyle(
                  color: OpsColors.muted,
                  height: 1.5,
                ),
              ),
            ),
          OpsKpiGrid(
            maxColumns: 4,
            minCardWidth: 180,
            cardHeight: 132,
            cards: [
              OpsKpiCard(
                label: 'Avg Tilt Angle',
                value: avgTilt.toStringAsFixed(2),
                valueSuffix: 'deg',
                helper: 'Only assigned sensor readings',
                icon: Icons.architecture_rounded,
                color: OpsColors.primary,
              ),
              OpsKpiCard(
                label: 'Max Tilt Angle',
                value: maxTilt.toStringAsFixed(2),
                valueSuffix: 'deg',
                helper: 'Highest live window reading',
                icon: Icons.show_chart_rounded,
                color: OpsColors.warning,
              ),
              OpsKpiCard(
                label: 'System Health',
                value: systemHealth.toStringAsFixed(0),
                valueSuffix: '%',
                helper: '$activeAlerts active alerts',
                icon: Icons.monitor_heart_outlined,
                color: OpsColors.success,
              ),
              OpsKpiCard(
                label: 'Last Update',
                value: _lastProcessedAt == null && _lastAnalyzedAt == null
                    ? 'Idle'
                    : 'SSE',
                helper: _agoLabel(_lastProcessedAt ?? _lastAnalyzedAt),
                icon: Icons.timeline_rounded,
                color: OpsColors.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1180;
              final rawCard = _buildSeriesCard(
                context,
                title: 'Sensor Live Records',
                subtitle: 'Raw acceleration stream',
                xData: _rawXData,
                yData: _rawYData,
                zData: _rawZData,
                xLabel: 'X',
                yLabel: 'Y',
                zLabel: 'Z',
                yAxisLabel: 'Raw acceleration',
                xAxisLabel: 'Raw sample index',
              );
              final processedCard = _buildSeriesCard(
                context,
                title: 'Processed Live Data',
                subtitle: 'Roll, pitch, and tilt from backend processing',
                xData: _processedRollData,
                yData: _processedPitchData,
                zData: _processedTiltData,
                xLabel: 'Roll',
                yLabel: 'Pitch',
                zLabel: 'Tilt',
                yAxisLabel: 'Processed angle (deg)',
                xAxisLabel: 'Processed sample index',
              );

              if (stacked) {
                return Column(
                  children: [
                    rawCard,
                    const SizedBox(height: 16),
                    processedCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: rawCard),
                  const SizedBox(width: 16),
                  Expanded(child: processedCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1180;
              final analyzedCard = _buildSeriesCard(
                context,
                title: 'Analyzed Live Data',
                subtitle: 'Analytics event stream values',
                xData: _analyzedRollData,
                yData: _analyzedPitchData,
                zData: _analyzedTiltData,
                xLabel: 'Roll',
                yLabel: 'Pitch',
                zLabel: 'Tilt',
                yAxisLabel: 'Analyzed angle (deg)',
                xAxisLabel: 'Analyzed sample index',
              );
              final snapshotCard = _buildSnapshotCard(
                latestTilt: latestTilt,
                latestVelocity: latestVelocity,
                latestAcceleration: latestAcceleration,
                activeAlerts: activeAlerts,
                totalSensors: scopedSensors.length,
                totalDevices: assignedDevices.length,
                totalSites: scopedSiteIds.length,
              );

              if (stacked) {
                return Column(
                  children: [
                    analyzedCard,
                    const SizedBox(height: 16),
                    snapshotCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: analyzedCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: snapshotCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 1180;
              final velocityCard = _buildMetricChartCard(
                context,
                title: 'Velocity Analytics',
                subtitle: 'Angular velocity from processed and analyzed tilt',
                primaryLabel: 'Processed w',
                secondaryLabel: 'Analyzed w',
                primaryData: _processedVelocityData,
                secondaryData: _analyzedVelocityData,
                primaryColor: OpsColors.primary,
                secondaryColor: OpsColors.success,
                yAxisLabel: 'deg/s',
              );
              final accelerationCard = _buildMetricChartCard(
                context,
                title: 'Acceleration Analytics',
                subtitle:
                    'Angular acceleration from processed and analyzed tilt',
                primaryLabel: 'Processed a',
                secondaryLabel: 'Analyzed a',
                primaryData: _processedAccelerationData,
                secondaryData: _analyzedAccelerationData,
                primaryColor: OpsColors.warning,
                secondaryColor: OpsColors.danger,
                yAxisLabel: 'deg/s2',
              );

              if (stacked) {
                return Column(
                  children: [
                    velocityCard,
                    const SizedBox(height: 16),
                    accelerationCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: velocityCard),
                  const SizedBox(width: 16),
                  Expanded(child: accelerationCard),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (widget.embeddedScroll) return content;
    return content;
  }

  Widget _buildSeriesCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<FlSpot> xData,
    required List<FlSpot> yData,
    required List<FlSpot> zData,
    required String xLabel,
    required String yLabel,
    required String zLabel,
    required String yAxisLabel,
    required String xAxisLabel,
  }) {
    final allSpots = [...xData, ...yData, ...zData];
    final hasData = allSpots.isNotEmpty;
    final minY = hasData ? allSpots.map((spot) => spot.y).reduce(math.min) : 0.0;
    final maxY = hasData ? allSpots.map((spot) => spot.y).reduce(math.max) : 10.0;
    final span = (maxY - minY).abs();
    final chartMinY = minY - math.max(span * 0.12, 0.5);
    final chartMaxY = maxY + math.max(span * 0.12, 0.5);
    final maxX = allSpots.isEmpty ? 12.0 : allSpots.map((spot) => spot.x).reduce(math.max);

    return OpsPanel(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(color: const Color(0xFF2E8BFF), label: xLabel),
              _LegendItem(color: const Color(0xFF11A95D), label: yLabel),
              _LegendItem(color: const Color(0xFFE58500), label: zLabel),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX <= 0 ? 1 : maxX,
                      minY: chartMinY,
                      maxY: chartMaxY <= chartMinY ? chartMinY + 1 : chartMaxY,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval:
                            (((chartMaxY - chartMinY).abs()) / 5).clamp(0.5, 9999),
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: OpsColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: OpsColors.border),
                          bottom: BorderSide(color: OpsColors.border),
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
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: OpsColors.muted,
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, _) => Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                color: OpsColors.muted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(
                            xAxisLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: OpsColors.muted,
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 10,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: OpsColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        _lineBar(xData, const Color(0xFF2E8BFF)),
                        _lineBar(yData, const Color(0xFF11A95D)),
                        _lineBar(zData, const Color(0xFFE58500)),
                      ],
                    ),
                  )
                : _emptyState('Waiting for live sensor samples...'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String primaryLabel,
    required String secondaryLabel,
    required List<FlSpot> primaryData,
    required List<FlSpot> secondaryData,
    required Color primaryColor,
    required Color secondaryColor,
    required String yAxisLabel,
  }) {
    final all = [...primaryData, ...secondaryData];
    final hasData = all.isNotEmpty;
    final minY = hasData ? all.map((spot) => spot.y).reduce(math.min) : -1.0;
    final maxY = hasData ? all.map((spot) => spot.y).reduce(math.max) : 1.0;
    final span = (maxY - minY).abs();
    final chartMinY = minY - math.max(span * 0.14, 0.3);
    final chartMaxY = maxY + math.max(span * 0.14, 0.3);
    final maxX = all.isEmpty ? 12.0 : all.map((spot) => spot.x).reduce(math.max);

    return OpsPanel(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(color: primaryColor, label: primaryLabel),
              _LegendItem(color: secondaryColor, label: secondaryLabel),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 300,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX <= 0 ? 1 : maxX,
                      minY: chartMinY,
                      maxY: chartMaxY <= chartMinY ? chartMinY + 1 : chartMaxY,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: OpsColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: OpsColors.border),
                          bottom: BorderSide(color: OpsColors.border),
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
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: OpsColors.muted,
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, _) => Text(
                              value.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 10,
                                color: OpsColors.muted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        _lineBar(primaryData, primaryColor),
                        _lineBar(secondaryData, secondaryColor),
                      ],
                    ),
                  )
                : _emptyState('Waiting for analytics samples...'),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard({
    required double? latestTilt,
    required double? latestVelocity,
    required double? latestAcceleration,
    required int activeAlerts,
    required int totalSensors,
    required int totalDevices,
    required int totalSites,
  }) {
    final items = <({String label, String value, String helper})>[
      (
        label: 'Latest Tilt',
        value: latestTilt == null ? '--' : '${latestTilt.toStringAsFixed(2)} deg',
        helper: 'Most recent processed or analyzed tilt',
      ),
      (
        label: 'Latest Velocity',
        value: latestVelocity == null
            ? '--'
            : '${latestVelocity.toStringAsFixed(3)} deg/s',
        helper: 'Computed from live tilt deltas',
      ),
      (
        label: 'Latest Acceleration',
        value: latestAcceleration == null
            ? '--'
            : '${latestAcceleration.toStringAsFixed(3)} deg/s2',
        helper: 'Second-order live change rate',
      ),
      (
        label: 'Workspace',
        value: '$totalSensors sensors / $totalDevices devices / $totalSites sites',
        helper: '$activeAlerts active alerts across assigned sensors',
      ),
      (
        label: 'Raw SSE',
        value: _rawEndpointPath,
        helper: 'Current raw stream endpoint',
      ),
      (
        label: 'Analytics SSE',
        value: _analyticsEndpointPath,
        helper: 'Current analytics stream endpoint',
      ),
    ];

    return OpsPanel(
      title: 'Live Snapshot',
      subtitle: 'Backend and SSE linked values',
      padding: const EdgeInsets.all(24),
      child: Column(
        children: items
            .map(
              (item) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: OpsColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OpsColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: OpsColors.outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: OpsColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.helper,
                      style: const TextStyle(
                        fontSize: 12,
                        color: OpsColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    final safeSpots = spots.isEmpty ? const [FlSpot(0, 0)] : spots;
    return LineChartBarData(
      spots: safeSpots,
      isCurved: true,
      color: color,
      barWidth: 2.4,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _emptyState(String label) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: OpsColors.muted),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Sensor> _scopedSensors(SuperAdminBackendProvider db) {
    return _scopedSensorsFrom(db.sensors, _assignedSensorIds);
  }

  List<Sensor> _scopedSensorsFrom(
    List<Sensor> sensors,
    Set<String> assignedSensorIds,
  ) {
    if (!_sensorAccessLoaded && assignedSensorIds.isEmpty) {
      return const <Sensor>[];
    }
    if (assignedSensorIds.isEmpty) {
      return const <Sensor>[];
    }
    return sensors
        .where((sensor) => assignedSensorIds.contains(sensor.id.trim()))
        .toList();
  }

  List<dynamic> _scopedActiveAlerts(SuperAdminBackendProvider db) {
    final allowedIds = _assignedSensorIds;
    if (!_sensorAccessLoaded || allowedIds.isEmpty) {
      return const [];
    }
    return db
        .getActiveAlerts()
        .where((alert) => allowedIds.contains(alert.sensorId.trim()))
        .toList();
  }

  double _averageSensorReading(List<Sensor> sensors) {
    if (sensors.isEmpty) return 0.0;
    final total = sensors
        .map((sensor) => sensor.lastReading.abs())
        .reduce((a, b) => a + b);
    return total / sensors.length;
  }

  double _maxSensorReading(List<Sensor> sensors) {
    if (sensors.isEmpty) return 0.0;
    return sensors
        .map((sensor) => sensor.lastReading.abs())
        .reduce(math.max);
  }

  double? _averageAbsolute(List<FlSpot> values) {
    if (values.isEmpty) return null;
    final total = values.map((spot) => spot.y.abs()).reduce((a, b) => a + b);
    return total / values.length;
  }

  double? _maxAbsolute(List<FlSpot> values) {
    if (values.isEmpty) return null;
    return values.map((spot) => spot.y.abs()).reduce(math.max);
  }

  String _agoLabel(DateTime? when) {
    if (when == null) return 'No updates';
    final seconds = DateTime.now().difference(when).inSeconds;
    if (seconds < 5) return 'Just now';
    if (seconds < 60) return '${seconds}s ago';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ago';
    return '${hours ~/ 24}d ago';
  }
}

String _resolveLivePath({
  required String explicitPath,
  required String fallbackPath,
}) {
  final trimmed = explicitPath.trim();
  if (trimmed.isEmpty) return fallbackPath;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    return uri.path.isEmpty ? fallbackPath : uri.path;
  }
  return trimmed;
}

class _ProcessedSnapshot {
  const _ProcessedSnapshot({
    required this.roll,
    required this.pitch,
    required this.tilt,
    required this.receivedAt,
  });

  final double roll;
  final double pitch;
  final double tilt;
  final DateTime receivedAt;
}

class _AnalyzedSnapshot {
  const _AnalyzedSnapshot({
    required this.roll,
    required this.pitch,
    required this.tilt,
    required this.timestamp,
  });

  final double roll;
  final double pitch;
  final double tilt;
  final double timestamp;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: OpsColors.muted,
          ),
        ),
      ],
    );
  }
}
