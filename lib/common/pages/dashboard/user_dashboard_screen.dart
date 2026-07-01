import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../../platform/api/api_client.dart';
import '../../platform/models/sensor.dart';
import '../../platform/models/sensor_parameter.dart';
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
  static const int _maxChartPoints = 48;
  static const int _maxHydratedReadingCache = 240;
  static const Duration _uiRefreshInterval = Duration(milliseconds: 120);

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
  final Map<String, List<FlSpot>> _configuredMetricSeries =
      <String, List<FlSpot>>{};
  final Set<String> _rawHydratedReadingIds = <String>{};
  final Set<String> _configuredHydratedReadingIds = <String>{};
  final Queue<String> _rawHydratedReadingOrder = Queue<String>();
  final Queue<String> _configuredHydratedReadingOrder = Queue<String>();
  final Map<String, int> _configuredMetricIndices = <String, int>{};

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
  Timer? _uiRefreshTimer;
  bool _uiRefreshScheduled = false;

  DateTime? _lastProcessedAt;
  DateTime? _lastAnalyzedAt;
  String _rawEndpointPath = '/api/v1/ingestion/readings/live';
  String _processedEndpointPath = '/api/v1/processing/readings/live';
  String _analyticsEndpointPath = '/api/v1/analytics/events/live';
  String _sensorName = 'Workspace Sensor';
  String _primarySensorId = '';
  List<SensorParameter> _configuredParameters = const <SensorParameter>[];
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
    await _primeHistoricalLiveCharts();
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
        db.loadSensorParameters(),
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
          : '/api/v1/ingestion/readings/live/${sensor.endpointKey.trim()}/{userId}',
    );
    _processedEndpointPath = _resolveLivePath(
      explicitPath: sensor.processingLiveEndpoint,
      fallbackPath: sensor.endpointKey.trim().isEmpty
          ? '/api/v1/processing/readings/live'
          : '/api/v1/processing/readings/live/${sensor.endpointKey.trim()}/{userId}',
    );
    _analyticsEndpointPath = _resolveLivePath(
      explicitPath: sensor.analyticsLiveEndpoint,
      fallbackPath: sensor.endpointKey.trim().isEmpty
          ? '/api/v1/analytics/events/live'
          : '/api/v1/analytics/events/live/${sensor.endpointKey.trim()}/{userId}',
    );
    final matchingParameters = db.sensorParameters
        .where((parameter) =>
            parameter.sensorTypeId.trim() == sensor.sensorTypeId.trim())
        .where((parameter) => parameter.formulaType.trim().isNotEmpty)
        .toList()
      ..sort((left, right) {
        final selectedId = sensor.sensorParameterId.trim();
        final leftSelected = left.id.trim() == selectedId;
        final rightSelected = right.id.trim() == selectedId;
        if (leftSelected != rightSelected) {
          return leftSelected ? -1 : 1;
        }
        final useCompare = left.useFor.trim().toLowerCase().compareTo(
              right.useFor.trim().toLowerCase(),
            );
        if (useCompare != 0) return useCompare;
        return left.name.trim().toLowerCase().compareTo(
              right.name.trim().toLowerCase(),
            );
      });
    _configuredParameters = matchingParameters;
    _configuredMetricSeries
      ..clear()
      ..addEntries(
        matchingParameters.map(
          (parameter) => MapEntry(parameter.id.trim(), <FlSpot>[]),
        ),
      );
    _configuredMetricIndices
      ..clear()
      ..addEntries(
        matchingParameters.map(
          (parameter) => MapEntry(parameter.id.trim(), 0),
        ),
      );
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
    if (sensor.name.trim().isNotEmpty) {
      return sensor.name.trim();
    }
    if (sensor.serialNumber.trim().isNotEmpty) {
      return sensor.serialNumber.trim();
    }
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
      if (!_isLiveRawReadingPayload(data)) return;
      if (!_matchesPrimarySensor(data)) return;
      if (_hydrateRawAndConfiguredSeries(data)) {
        _scheduleUiRefresh();
      }
    });

    await _processedSseService!.connect();
    _processedSubscription = _processedSseService!.stream.listen((data) {
      if (!mounted) return;
      if (!_isLiveProcessedReadingPayload(data)) return;
      if (!_matchesPrimarySensor(data)) return;
      final historyChanged = _hydrateRawAndConfiguredSeries(data);
      final snapshot = _extractProcessedSnapshot(data);
      if (snapshot == null) {
        if (historyChanged) {
          _scheduleUiRefresh();
        }
        return;
      }
      final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final dt = (_previousProcessedTimestampSec == null)
          ? null
          : nowSec - _previousProcessedTimestampSec!;
      final velocity = (_previousProcessedTilt == null || dt == null || dt <= 0)
          ? 0.0
          : (snapshot.tilt - _previousProcessedTilt!) / dt;
      final acceleration =
          (_previousProcessedVelocity == null || dt == null || dt <= 0)
              ? 0.0
              : (velocity - _previousProcessedVelocity!) / dt;

      _appendPoint(_processedRollData, _processedIndex, snapshot.roll);
      _appendPoint(_processedPitchData, _processedIndex, snapshot.pitch);
      _appendPoint(_processedTiltData, _processedIndex, snapshot.tilt);
      _appendPoint(_processedVelocityData, _processedIndex, velocity);
      _appendPoint(_processedAccelerationData, _processedIndex, acceleration);
      _processedIndex++;
      _previousProcessedTilt = snapshot.tilt;
      _previousProcessedTimestampSec = nowSec;
      _previousProcessedVelocity = velocity;
      _lastProcessedAt = snapshot.receivedAt;
      _scheduleUiRefresh();
    });

    await _analyticsSseService!.connect();
    _analyticsSubscription = _analyticsSseService!.stream.listen((data) {
      if (!mounted) return;
      if (!_isLiveAnalyticsPayload(data)) return;
      if (!_matchesPrimarySensor(data)) return;
      final historyChanged = _hydrateRawAndConfiguredSeries(data);
      final snapshot = _extractAnalyzedSnapshot(data);
      if (snapshot == null) {
        if (historyChanged) {
          _scheduleUiRefresh();
        }
        return;
      }
      final dt = (_previousAnalyzedTimestamp == null)
          ? null
          : _deltaSeconds(snapshot.timestamp - _previousAnalyzedTimestamp!);
      final velocity = (_previousAnalyzedTilt == null || dt == null || dt <= 0)
          ? 0.0
          : (snapshot.tilt - _previousAnalyzedTilt!) / dt;
      final acceleration =
          (_previousAnalyzedVelocity == null || dt == null || dt <= 0)
              ? 0.0
              : (velocity - _previousAnalyzedVelocity!) / dt;

      _appendPoint(_analyzedRollData, _analyzedIndex, snapshot.roll);
      _appendPoint(_analyzedPitchData, _analyzedIndex, snapshot.pitch);
      _appendPoint(_analyzedTiltData, _analyzedIndex, snapshot.tilt);
      _appendPoint(_analyzedVelocityData, _analyzedIndex, velocity);
      _appendPoint(
        _analyzedAccelerationData,
        _analyzedIndex,
        acceleration,
      );
      _analyzedIndex++;
      _previousAnalyzedTilt = snapshot.tilt;
      _previousAnalyzedTimestamp = snapshot.timestamp;
      _previousAnalyzedVelocity = velocity;
      _lastAnalyzedAt = DateTime.now();
      _scheduleUiRefresh();
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

  Future<void> _primeHistoricalLiveCharts() async {
    final sensorId = _primarySensorId.trim();
    if (sensorId.isEmpty) {
      return;
    }

    var historyChanged = false;

    try {
      final processedResponse = await ApiClient.get(
        '/api/v1/processing/readings',
        queryParameters: {'sensorId': sensorId, 'limit': _maxChartPoints},
      );
      final processedBody = processedResponse.body;
      final processedRecords =
          processedBody is Map ? processedBody['records'] : null;
      if (processedRecords is List) {
        for (final item in processedRecords.reversed) {
          if (!_matchesPrimarySensor(item)) continue;
          historyChanged =
              _hydrateRawAndConfiguredSeries(item) || historyChanged;
          final snapshot = _extractProcessedSnapshot(item);
          if (snapshot == null) continue;
          final timestampSec =
              _timestampToSeconds(_timestampFromPayload(item)) ??
                  snapshot.receivedAt.millisecondsSinceEpoch / 1000.0;
          final dt = (_previousProcessedTimestampSec == null)
              ? null
              : timestampSec - _previousProcessedTimestampSec!;
          final velocity =
              (_previousProcessedTilt == null || dt == null || dt <= 0)
                  ? 0.0
                  : (snapshot.tilt - _previousProcessedTilt!) / dt;
          final acceleration =
              (_previousProcessedVelocity == null || dt == null || dt <= 0)
                  ? 0.0
                  : (velocity - _previousProcessedVelocity!) / dt;

          if (!mounted) return;
          _appendPoint(_processedRollData, _processedIndex, snapshot.roll);
          _appendPoint(_processedPitchData, _processedIndex, snapshot.pitch);
          _appendPoint(_processedTiltData, _processedIndex, snapshot.tilt);
          _appendPoint(_processedVelocityData, _processedIndex, velocity);
          _appendPoint(
            _processedAccelerationData,
            _processedIndex,
            acceleration,
          );
          _processedIndex++;
          _previousProcessedTilt = snapshot.tilt;
          _previousProcessedTimestampSec = timestampSec;
          _previousProcessedVelocity = velocity;
          _lastProcessedAt = snapshot.receivedAt;
          historyChanged = true;
        }
      }
    } catch (_) {
      // If history is unavailable, the live stream will still populate data.
    }

    if (historyChanged) {
      _scheduleUiRefresh(force: true);
    }
  }

  void _appendPoint(List<FlSpot> points, int index, double value) {
    points.add(FlSpot(index.toDouble(), value));
    while (points.length > _maxChartPoints) {
      points.removeAt(0);
    }
  }

  bool _isLiveRawReadingPayload(dynamic payload) {
    if (payload is! Map) {
      return false;
    }
    if (payload['type'] != null) {
      return false;
    }
    return _readingIdFromPayload(payload) != null;
  }

  bool _isLiveProcessedReadingPayload(dynamic payload) {
    if (payload is! Map) {
      return false;
    }
    if (payload['type'] != null) {
      return false;
    }
    if (_readingIdFromPayload(payload) == null) {
      return false;
    }
    return payload['processedPayload'] is Map;
  }

  bool _isLiveAnalyticsPayload(dynamic payload) {
    if (payload is! Map) {
      return false;
    }
    if (payload['type'] != null) {
      return false;
    }
    final eventType = payload['eventType']?.toString().trim();
    if (eventType != null &&
        eventType.isNotEmpty &&
        eventType != 'analytics-live') {
      return false;
    }
    return _readingIdFromPayload(payload) != null;
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
      final rawSensorId = (rawPayload['sensorId'] ?? rawPayload['sensor_id'])
          ?.toString()
          .trim();
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

  bool _hydrateRawAndConfiguredSeries(dynamic payload) {
    final context = _extractFormulaContext(payload);
    if (context == null) {
      return false;
    }
    final readingKey = _hydrationKeyFromPayload(payload, context);
    final shouldHydrateRaw =
        readingKey == null || !_rawHydratedReadingIds.contains(readingKey);
    final shouldHydrateConfigured = readingKey == null ||
        !_configuredHydratedReadingIds.contains(readingKey);

    if (!shouldHydrateRaw && !shouldHydrateConfigured) {
      return false;
    }

    var changed = false;
    if (shouldHydrateRaw &&
        context.x != null &&
        context.y != null &&
        context.z != null) {
      _appendPoint(_rawXData, _rawIndex, context.x!);
      _appendPoint(_rawYData, _rawIndex, context.y!);
      _appendPoint(_rawZData, _rawIndex, context.z!);
      _rawIndex++;
      if (readingKey != null) {
        _rememberHydratedReading(
          _rawHydratedReadingIds,
          _rawHydratedReadingOrder,
          readingKey,
        );
      }
      changed = true;
    }

    if (shouldHydrateConfigured) {
      var appendedAny = false;
      for (final parameter in _configuredParameters) {
        final metric = _computeConfiguredMetric(parameter, context);
        if (metric == null) continue;
        final parameterId = parameter.id.trim();
        final series =
            _configuredMetricSeries.putIfAbsent(parameterId, () => <FlSpot>[]);
        final index = _configuredMetricIndices[parameterId] ?? 0;
        _appendPoint(series, index, metric);
        _configuredMetricIndices[parameterId] = index + 1;
        appendedAny = true;
      }
      if (appendedAny && readingKey != null) {
        _rememberHydratedReading(
          _configuredHydratedReadingIds,
          _configuredHydratedReadingOrder,
          readingKey,
        );
      }
      changed = changed || appendedAny;
    }

    return changed;
  }

  String? _hydrationKeyFromPayload(
    dynamic payload,
    _FormulaContext context,
  ) {
    final readingId = _readingIdFromPayload(payload);
    if (readingId != null) {
      return 'reading:$readingId';
    }

    final sensorId = _sensorIdFromPayload(payload);
    final timestamp = _timestampToSeconds(_timestampFromPayload(payload));
    final parts = <String>[
      if (sensorId != null && sensorId.isNotEmpty) 'sensor:$sensorId',
      if (timestamp != null) 'ts:${timestamp.toStringAsFixed(6)}',
      if (context.x != null) 'x:${context.x!.toStringAsFixed(6)}',
      if (context.y != null) 'y:${context.y!.toStringAsFixed(6)}',
      if (context.z != null) 'z:${context.z!.toStringAsFixed(6)}',
      if (context.roll != null) 'roll:${context.roll!.toStringAsFixed(6)}',
      if (context.pitch != null) 'pitch:${context.pitch!.toStringAsFixed(6)}',
      if (context.tilt != null) 'tilt:${context.tilt!.toStringAsFixed(6)}',
    ];

    if (parts.isEmpty) {
      return null;
    }
    return parts.join('|');
  }

  void _rememberHydratedReading(
    Set<String> cache,
    Queue<String> order,
    String readingId,
  ) {
    if (cache.contains(readingId)) return;
    cache.add(readingId);
    order.addLast(readingId);
    while (order.length > _maxHydratedReadingCache) {
      final oldest = order.removeFirst();
      cache.remove(oldest);
    }
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
          final name =
              item['parameterName']?.toString() ?? item['name']?.toString();
          final value = _toDouble(item['value']);
          if (name == null || value == null) continue;
          values[name] = value;
        }
      }

      final processedPayload = map['processedPayload'] is Map
          ? map['processedPayload'] as Map<dynamic, dynamic>
          : null;
      final tiltPayload =
          processedPayload != null && processedPayload['tilt'] is Map
              ? processedPayload['tilt'] as Map<dynamic, dynamic>
              : null;
      final inclinoPayload =
          processedPayload != null && processedPayload['inclinometer'] is Map
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

      final timestamp = _timestampToSeconds(map['timestamp']) ??
          _timestampToSeconds(map['eventTime']) ??
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
        'records',
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

  double? _computeConfiguredMetric(
    SensorParameter parameter,
    _FormulaContext context,
  ) {
    final formula = parameter.formulaType.trim();
    if (formula.isEmpty) return null;
    switch (formula) {
      case 'x':
        return context.x;
      case 'y':
        return context.y;
      case 'z':
        return context.z;
      case 'average_xyz':
        if (context.x == null || context.y == null || context.z == null) {
          return null;
        }
        return (context.x! + context.y! + context.z!) / 3.0;
      case 'magnitude_xyz':
        if (context.x == null || context.y == null || context.z == null) {
          return null;
        }
        return math.sqrt(
          (context.x! * context.x!) +
              (context.y! * context.y!) +
              (context.z! * context.z!),
        );
      case 'tilt_angle_deg':
        if (context.x == null || context.y == null || context.z == null) {
          return null;
        }
        final horizontal = math.sqrt(
          (context.x! * context.x!) + (context.y! * context.y!),
        );
        return math.atan2(horizontal, context.z!) * 180 / math.pi;
      default:
        return _FormulaParser(
          expression: formula,
          variables: context.variables,
        ).parse();
    }
  }

  _FormulaContext? _extractFormulaContext(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final rawPayload = map['rawPayload'];
      final rawParameters = rawPayload is Map ? rawPayload['parameters'] : null;

      final values = <String, double>{};
      void collectValue(String key, dynamic value) {
        final parsed = _toDouble(value);
        if (parsed != null) {
          values[key] = parsed;
        }
      }

      if (rawParameters is Map) {
        for (final entry in rawParameters.entries) {
          collectValue(entry.key.toString(), entry.value);
        }
      }

      final parameters = map['parameters'];
      if (parameters is Map) {
        for (final entry in parameters.entries) {
          collectValue(entry.key.toString(), entry.value);
        }
      }

      final processedPayload = map['processedPayload'] is Map
          ? map['processedPayload'] as Map
          : null;
      if (processedPayload != null) {
        _collectNumericValues(values, processedPayload);
      }

      final eventMap = map['event'];
      if (eventMap is Map) {
        _collectNumericValues(values, eventMap);
      }

      final evaluations =
          eventMap is Map ? eventMap['evaluations'] : map['evaluations'];
      if (evaluations is List) {
        for (final item in evaluations) {
          if (item is! Map) continue;
          final name = item['parameterName']?.toString() ??
              item['name']?.toString() ??
              '';
          if (name.isEmpty) continue;
          collectValue(name, item['value']);
        }
      }

      collectValue('x', map['x']);
      collectValue('y', map['y']);
      collectValue('z', map['z']);

      final x = _firstDouble([
        values['x'],
        values['ax'],
        values['accelX'],
        values['acc_x'],
        values['rawPayload.parameters.x'],
      ]);
      final y = _firstDouble([
        values['y'],
        values['ay'],
        values['accelY'],
        values['acc_y'],
        values['rawPayload.parameters.y'],
      ]);
      final z = _firstDouble([
        values['z'],
        values['az'],
        values['accelZ'],
        values['acc_z'],
        values['rawPayload.parameters.z'],
      ]);
      final roll = _firstDouble([
        values['rollDegrees'],
        values['roll'],
        values['tilt.rollDegrees'],
      ]);
      final pitch = _firstDouble([
        values['pitchDegrees'],
        values['pitch'],
        values['tilt.pitchDegrees'],
      ]);
      final tilt = _firstDouble([
        values['tiltFromVerticalDegrees'],
        values['inclinationDegrees'],
        values['tilt'],
        values['tilt.tiltFromVerticalDegrees'],
      ]);
      final horizontalMagnitude = _firstDouble([
        values['horizontalMagnitude'],
        values['accelerationMagnitude'],
      ]);

      final hasAnyValue = x != null ||
          y != null ||
          z != null ||
          roll != null ||
          pitch != null ||
          tilt != null ||
          horizontalMagnitude != null ||
          values.isNotEmpty;
      if (!hasAnyValue) {
        continue;
      }

      return _FormulaContext(
        x: x,
        y: y,
        z: z,
        roll: roll,
        pitch: pitch,
        tilt: tilt,
        horizontalMagnitude: horizontalMagnitude,
        values: values,
      );
    }
    return null;
  }

  void _collectNumericValues(
    Map<String, double> target,
    Map<dynamic, dynamic> source, {
    String prefix = '',
  }) {
    for (final entry in source.entries) {
      final rawKey = entry.key?.toString().trim() ?? '';
      if (rawKey.isEmpty) continue;
      final key = prefix.isEmpty ? rawKey : '$prefix.$rawKey';
      final value = entry.value;
      final parsed = _toDouble(value);
      if (parsed != null) {
        target[key] = parsed;
        continue;
      }
      if (value is Map) {
        _collectNumericValues(target, value, prefix: key);
      }
    }
  }

  String? _readingIdFromPayload(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final readingId =
          (map['readingId'] ?? map['reading_id'])?.toString().trim();
      if (readingId != null && readingId.isNotEmpty) {
        return readingId;
      }
    }
    return null;
  }

  String? _sensorIdFromPayload(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      final sensorId = _sensorIdFromMap(map);
      if (sensorId != null && sensorId.isNotEmpty) {
        return sensorId;
      }
    }
    return null;
  }

  dynamic _timestampFromPayload(dynamic payload) {
    for (final map in _candidateMaps(payload)) {
      if (map.containsKey('timestamp')) {
        return map['timestamp'];
      }
      if (map.containsKey('eventTime')) {
        return map['eventTime'];
      }
      final rawPayload = map['rawPayload'];
      if (rawPayload is Map && rawPayload.containsKey('timestamp')) {
        return rawPayload['timestamp'];
      }
    }
    return null;
  }

  double? _timestampToSeconds(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return value.toDouble() > 1000000000000
          ? value.toDouble() / 1000.0
          : value.toDouble();
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final numeric = double.tryParse(raw);
    if (numeric != null) {
      return numeric > 1000000000000 ? numeric / 1000.0 : numeric;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.millisecondsSinceEpoch / 1000.0;
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _disconnectStreams();
    super.dispose();
  }

  void _scheduleUiRefresh({bool force = false}) {
    if (!mounted) return;
    if (force) {
      _uiRefreshTimer?.cancel();
      _uiRefreshScheduled = false;
      setState(() {});
      return;
    }
    if (_uiRefreshScheduled) return;
    _uiRefreshScheduled = true;
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer(_uiRefreshInterval, () {
      _uiRefreshScheduled = false;
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final scopedSensors = _scopedSensors(db);
    final scopedAlerts = _scopedActiveAlerts(db);

    final activeAlerts = scopedAlerts.length;
    final avgTilt = _averageAbsolute(_processedTiltData) ??
        _averageSensorReading(scopedSensors);
    final maxTilt =
        _maxAbsolute(_processedTiltData) ?? _maxSensorReading(scopedSensors);
    final systemHealth =
        (100 - (activeAlerts * 6) - ((_latestTiltValue()?.abs() ?? 0) * 1.8))
            .clamp(0, 100)
            .toDouble();
    final showNoAssignmentState = _sensorAccessLoaded &&
        _assignedSensorIds.isEmpty &&
        _sensorAccessError == null;

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
          if (_configuredParameters.isNotEmpty) ...[
            _buildConfiguredMetricsSection(context),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
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
              final stacked = constraints.maxWidth < 900;
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

              if (stacked) {
                return analyzedCard;
              }

              return analyzedCard;
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
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
    final minY =
        hasData ? allSpots.map((spot) => spot.y).reduce(math.min) : 0.0;
    final maxY =
        hasData ? allSpots.map((spot) => spot.y).reduce(math.max) : 10.0;
    final span = (maxY - minY).abs();
    final chartMinY = minY - math.max(span * 0.12, 0.5);
    final chartMaxY = maxY + math.max(span * 0.12, 0.5);
    final minX = allSpots.isEmpty
        ? 0.0
        : allSpots.map((spot) => spot.x).reduce(math.min);
    final maxX = allSpots.isEmpty
        ? 12.0
        : allSpots.map((spot) => spot.x).reduce(math.max);

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
                    duration: Duration.zero,
                    LineChartData(
                      clipData: const FlClipData.all(),
                      minX: minX,
                      maxX: maxX <= minX ? minX + 1 : maxX,
                      minY: chartMinY,
                      maxY: chartMaxY <= chartMinY ? chartMinY + 1 : chartMaxY,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval:
                            (((chartMaxY - chartMinY).abs()) / 5)
                                .clamp(0.5, 9999),
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

  Widget _buildConfiguredMetricsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 900;
        final children = _configuredParameters
            .map((parameter) => _buildConfiguredMetricCard(context, parameter))
            .toList(growable: false);

        if (!twoColumns) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < children.length; i += 2) ...[
              if (i + 1 < children.length)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: children[i]),
                    const SizedBox(width: 16),
                    Expanded(child: children[i + 1]),
                  ],
                )
              else
                children[i],
              if (i + 2 < children.length) const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildConfiguredMetricCard(
    BuildContext context,
    SensorParameter parameter,
  ) {
    final parameterId = parameter.id.trim();
    final series = _configuredMetricSeries[parameterId] ?? const <FlSpot>[];
    final title = parameter.calculationName.trim().isEmpty
        ? parameter.name
        : parameter.calculationName.trim();
    final subtitle = parameter.formulaType.trim().isEmpty
        ? 'Configured custom calculation'
        : 'Formula: ${parameter.formulaType}';
    final hasData = series.isNotEmpty;
    final graphType = parameter.graphType.trim().isEmpty
        ? 'line'
        : parameter.graphType.trim().toLowerCase();

    return OpsPanel(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 300,
        child: hasData
            ? (graphType == 'bar'
                ? _buildConfiguredBarChart(series)
                : _buildConfiguredLineChart(
                    series: series,
                    label: title +
                        (parameter.unit.trim().isEmpty
                            ? ''
                            : ' (${parameter.unit.trim()})'),
                  ))
            : _emptyState('Waiting for configured calculation samples...'),
      ),
    );
  }

  Widget _buildConfiguredLineChart({
    required List<FlSpot> series,
    required String label,
  }) {
    final minY = series.map((spot) => spot.y).reduce(math.min);
    final maxY = series.map((spot) => spot.y).reduce(math.max);
    final span = (maxY - minY).abs();
    final chartMinY = minY - math.max(span * 0.12, 0.5);
    final chartMaxY = maxY + math.max(span * 0.12, 0.5);
    final minX = series.map((spot) => spot.x).reduce(math.min);
    final maxX = series.map((spot) => spot.x).reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            _LegendItem(
              color: const Color(0xFF8E44EC),
              label: label,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LineChart(
            duration: Duration.zero,
            LineChartData(
              clipData: const FlClipData.all(),
              minX: minX,
              maxX: maxX <= minX ? minX + 1 : maxX,
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
              titlesData: const FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                _lineBar(series, const Color(0xFF8E44EC)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfiguredBarChart(List<FlSpot> series) {
    final latest = series.last.y;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: latest,
                color: const Color(0xFF8E44EC),
                width: 36,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
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
    final minX = all.isEmpty ? 0.0 : all.map((spot) => spot.x).reduce(math.min);
    final maxX =
        all.isEmpty ? 12.0 : all.map((spot) => spot.x).reduce(math.max);

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
                    duration: Duration.zero,
                    LineChartData(
                      clipData: const FlClipData.all(),
                      minX: minX,
                      maxX: maxX <= minX ? minX + 1 : maxX,
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

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    final safeSpots = spots.isEmpty ? const [FlSpot(0, 0)] : spots;
    return LineChartBarData(
      spots: safeSpots,
      isCurved: safeSpots.length <= 12,
      preventCurveOverShooting: true,
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
    return sensors.map((sensor) => sensor.lastReading.abs()).reduce(math.max);
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

  double? _latestTiltValue() {
    if (_processedTiltData.isNotEmpty) {
      return _processedTiltData.last.y;
    }
    if (_analyzedTiltData.isNotEmpty) {
      return _analyzedTiltData.last.y;
    }
    return null;
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

class _FormulaContext {
  const _FormulaContext({
    required this.x,
    required this.y,
    required this.z,
    required this.roll,
    required this.pitch,
    required this.tilt,
    required this.horizontalMagnitude,
    required this.values,
  });

  final double? x;
  final double? y;
  final double? z;
  final double? roll;
  final double? pitch;
  final double? tilt;
  final double? horizontalMagnitude;
  final Map<String, double> values;

  Map<String, double> get variables {
    final result = <String, double>{...values};
    void putIfValue(String key, double? value) {
      if (value != null) {
        result[key] = value;
      }
    }

    putIfValue('x', x);
    putIfValue('y', y);
    putIfValue('z', z);
    putIfValue('roll', roll);
    putIfValue('rollDegrees', roll);
    putIfValue('pitch', pitch);
    putIfValue('pitchDegrees', pitch);
    putIfValue('tilt', tilt);
    putIfValue('tiltDegrees', tilt);
    putIfValue('tiltFromVerticalDegrees', tilt);
    putIfValue('horizontalMagnitude', horizontalMagnitude);
    return result;
  }
}

class _FormulaParser {
  _FormulaParser({
    required this.expression,
    required this.variables,
  });

  final String expression;
  final Map<String, double> variables;
  int _index = 0;

  double? parse() {
    try {
      final value = _parseExpression();
      _skipWhitespace();
      if (_index != expression.length) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      _skipWhitespace();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      _skipWhitespace();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();
        if (divisor == 0) {
          throw const FormatException('Division by zero');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    _skipWhitespace();
    if (_match('+')) return _parseFactor();
    if (_match('-')) return -_parseFactor();

    var value = _parsePrimary();
    _skipWhitespace();
    while (_match('^')) {
      value = math.pow(value, _parseFactor()).toDouble();
      _skipWhitespace();
    }
    return value;
  }

  double _parsePrimary() {
    _skipWhitespace();
    if (_match('(')) {
      final value = _parseExpression();
      _expect(')');
      return value;
    }

    if (_isIdentifierStart(_currentChar)) {
      final identifier = _parseIdentifier();
      _skipWhitespace();
      if (_match('(')) {
        final args = <double>[];
        _skipWhitespace();
        if (!_match(')')) {
          do {
            args.add(_parseExpression());
            _skipWhitespace();
          } while (_match(','));
          _expect(')');
        }
        return _callFunction(identifier, args);
      }
      final normalized = identifier.trim();
      if (variables.containsKey(normalized)) {
        return variables[normalized]!;
      }
      throw FormatException('Unknown variable: $identifier');
    }

    return _parseNumber();
  }

  double _parseNumber() {
    final start = _index;
    var hasDot = false;
    while (_index < expression.length) {
      final char = expression[_index];
      if (char == '.') {
        if (hasDot) break;
        hasDot = true;
        _index++;
        continue;
      }
      if (!_isDigit(char)) break;
      _index++;
    }
    if (start == _index) {
      throw const FormatException('Expected number');
    }
    return double.parse(expression.substring(start, _index));
  }

  String _parseIdentifier() {
    final start = _index;
    while (_index < expression.length) {
      final char = expression[_index];
      if (!_isIdentifierPart(char)) break;
      _index++;
    }
    return expression.substring(start, _index);
  }

  double _callFunction(String name, List<double> args) {
    switch (name.trim().toLowerCase()) {
      case 'sqrt':
        return math.sqrt(args.first);
      case 'abs':
        return args.first.abs();
      case 'sin':
        return math.sin(args.first);
      case 'cos':
        return math.cos(args.first);
      case 'tan':
        return math.tan(args.first);
      case 'atan':
        return math.atan(args.first);
      case 'atan2':
        return math.atan2(args[0], args[1]);
      case 'pow':
        return math.pow(args[0], args[1]).toDouble();
      case 'min':
        return math.min(args[0], args[1]);
      case 'max':
        return math.max(args[0], args[1]);
      default:
        throw FormatException('Unknown function: $name');
    }
  }

  void _skipWhitespace() {
    while (_index < expression.length && expression[_index].trim().isEmpty) {
      _index++;
    }
  }

  bool _match(String expected) {
    if (_index >= expression.length || expression[_index] != expected) {
      return false;
    }
    _index++;
    return true;
  }

  void _expect(String expected) {
    if (!_match(expected)) {
      throw FormatException('Expected $expected');
    }
  }

  String? get _currentChar =>
      _index < expression.length ? expression[_index] : null;

  bool _isDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;

  bool _isIdentifierStart(String? value) {
    if (value == null) return false;
    final code = value.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        value == '_';
  }

  bool _isIdentifierPart(String value) {
    return _isIdentifierStart(value) || _isDigit(value) || value == '.';
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
