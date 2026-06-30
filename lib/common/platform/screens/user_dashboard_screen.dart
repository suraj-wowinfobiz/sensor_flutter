import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/ops_theme.dart';
import '../models/alert.dart';
import '../models/device.dart';
import '../models/sensor.dart';
import '../models/site.dart';
import '../providers/super_admin_api_riverpod_provider.dart';
import '../providers/super_admin_backend_provider.dart';
import '../providers/super_admin_riverpod_provider.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  static const double _statusRowHeight = 344;
  static const double _overviewRowHeight = 396;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(superAdminBackendChangeNotifierProvider);
    final dashboardOverview =
        ref.watch(superAdminDashboardOverviewApiProvider).valueOrNull ??
            const {};
    final recentEvents =
        ref.watch(superAdminAnalyticsRecentEventsApiProvider).valueOrNull ??
            const <Map<String, dynamic>>[];

    final dashboard = _buildDashboardModel(
      db: db,
      dashboardOverview: dashboardOverview,
      recentEvents: recentEvents,
    );

    return OpsPage(
      title: 'Dashboard',
      subtitle: 'Real-time overview of your sites and sensor health',
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: const Text('Last 7 days'),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OpsKpiGrid(
            maxColumns: 6,
            minCardWidth: 145,
            cardHeight: 132,
            cards: [
              OpsKpiCard(
                label: 'Total Sensors',
                value: '${dashboard.totalSensors}',
                helper: 'Workspace sensors',
                icon: Icons.sensors_outlined,
              ),
              OpsKpiCard(
                label: 'Online',
                value: dashboard.healthPercent.toStringAsFixed(1),
                valueSuffix: '%',
                helper: 'Sensor health',
                icon: Icons.check_circle_outline_rounded,
                color: OpsColors.success,
              ),
              OpsKpiCard(
                label: 'Alerts',
                value: '${dashboard.openAlerts}',
                helper: 'Action required',
                icon: Icons.warning_amber_rounded,
                color: OpsColors.danger,
              ),
              OpsKpiCard(
                label: 'Active Sites',
                value: '${dashboard.activeSites}',
                helper: 'Tracked locations',
                icon: Icons.location_on_outlined,
                color: OpsColors.muted,
              ),
              OpsKpiCard(
                label: 'Max Vibration',
                value: dashboard.maxVibration == null
                    ? '--'
                    : _formatNumber(
                        dashboard.maxVibration!,
                        decimals: dashboard.maxVibration! >= 10 ? 1 : 2,
                      ),
                valueSuffix: dashboard.maxVibration == null ? null : 'mm/s',
                helper: 'Peak',
                icon: Icons.vibration_rounded,
                color: OpsColors.warning,
              ),
              OpsKpiCard(
                label: 'Avg Temp',
                value: dashboard.avgTemperature == null
                    ? '--'
                    : _formatNumber(dashboard.avgTemperature!, decimals: 1),
                valueSuffix: dashboard.avgTemperature == null ? null : 'C',
                helper: recentEvents.isEmpty
                    ? 'Analytics stream'
                    : '${recentEvents.length} recent events',
                icon: Icons.thermostat_rounded,
                color: OpsColors.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth <= 900;
              final left = OpsPanel(
                title: 'Sensor Status',
                padding: const EdgeInsets.all(24),
                child: _SensorStatusDonut(
                  online: dashboard.onlineSensors,
                  warning: dashboard.warningSensors,
                  offline: dashboard.offlineSensors,
                ),
              );
              final center = OpsPanel(
                title: 'Alerts Summary',
                subtitle: 'Last 7 days',
                padding: const EdgeInsets.all(24),
                child: _AlertSummary(
                  counts: dashboard.alertLevelCounts,
                  totalAlerts: dashboard.openAlerts,
                ),
              );
              final right = OpsPanel(
                title: 'Live Feed',
                trailing: const _ActiveBadge(),
                padding: const EdgeInsets.all(24),
                child: _LiveFeed(entries: dashboard.liveFeed),
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

              return SizedBox(
                height: _statusRowHeight,
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
              final siteOverview = OpsPanel(
                title: 'Site Overview',
                padding: const EdgeInsets.all(24),
                child: _SiteOverviewTable(rows: dashboard.siteRows),
              );
              final healthTrend = OpsPanel(
                title: 'Sensor Health Over Time',
                padding: const EdgeInsets.all(24),
                child: _HealthTrend(points: dashboard.trendPoints),
              );

              if (stacked) {
                return Column(
                  children: [
                    siteOverview,
                    const SizedBox(height: 16),
                    healthTrend,
                  ],
                );
              }

              return SizedBox(
                height: _overviewRowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 6, child: siteOverview),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: healthTrend),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const _DashboardFooter(),
        ],
      ),
    );
  }
}

_UserDashboardModel _buildDashboardModel({
  required SuperAdminBackendProvider db,
  required Map<String, dynamic> dashboardOverview,
  required List<Map<String, dynamic>> recentEvents,
}) {
  final openAlerts = db.alerts.where((alert) => !alert.isResolved).toList()
    ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
  final sensorById = {for (final sensor in db.sensors) sensor.id: sensor};
  final deviceById = {for (final device in db.devices) device.id: device};
  final siteById = {for (final site in db.sites) site.id: site};
  final affectedSensorIds = openAlerts
      .map((alert) => alert.sensorId.trim())
      .where((sensorId) => sensorId.isNotEmpty)
      .toSet();

  final totalSensors = db.sensors.length;
  final healthySensorsPercent =
      _asDouble(dashboardOverview['healthySensorsPercent']);
  final fallbackOnlineSensors = math
      .max(
        0,
        totalSensors - math.min(totalSensors, affectedSensorIds.length),
      )
      .toInt();
  final onlineSensors = totalSensors == 0
      ? 0
      : healthySensorsPercent != null
          ? ((totalSensors * healthySensorsPercent / 100).round())
              .clamp(0, totalSensors)
              .toInt()
          : fallbackOnlineSensors;
  final warningSensors = totalSensors == 0
      ? 0
      : math
          .min(
            affectedSensorIds.length,
            math.max(totalSensors - onlineSensors, 0),
          )
          .toInt();
  final offlineSensors = math
      .max(
        0,
        totalSensors - onlineSensors - warningSensors,
      )
      .toInt();
  final healthPercent = totalSensors == 0
      ? (healthySensorsPercent ?? 0).clamp(0, 100).toDouble()
      : ((onlineSensors / totalSensors) * 100).clamp(0, 100).toDouble();
  final activeSites = db.sites.isNotEmpty
      ? db.sites.length
      : db.devices
          .map((device) => device.siteId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .length;

  final alertLevelCounts = <String, int>{
    'critical': 0,
    'high': 0,
    'medium': 0,
    'low': 0,
  };
  for (final alert in openAlerts) {
    alertLevelCounts[_normalizeAlertLevel(alert.alertLevel)] =
        (alertLevelCounts[_normalizeAlertLevel(alert.alertLevel)] ?? 0) + 1;
  }

  final vibrationReadings = <double>[];
  final temperatureReadings = <double>[];
  final liveFeedEntries = <_LiveFeedEntry>[];
  final recentSiteMoments = <String, DateTime>{};
  final activeSensorsLast24hBySite = <String, Set<String>>{};
  final activeSensorsByDay = <String, Set<String>>{};
  final alertsByDay = <String, Set<String>>{};
  final now = DateTime.now();

  for (final event in recentEvents) {
    final sensorId = _extractSensorId(event);
    final sensor = sensorId == null ? null : sensorById[sensorId];
    final device = sensor == null ? null : deviceById[sensor.deviceId];
    final siteId = device?.siteId ?? '';
    final receivedAt = _extractEventDateTime(event);
    if (siteId.isNotEmpty && receivedAt != null) {
      final existing = recentSiteMoments[siteId];
      if (existing == null || receivedAt.isAfter(existing)) {
        recentSiteMoments[siteId] = receivedAt;
      }
      if (sensorId != null &&
          now.difference(receivedAt).inHours <= 24 &&
          sensorId.isNotEmpty) {
        activeSensorsLast24hBySite
            .putIfAbsent(siteId, () => <String>{})
            .add(sensorId);
      }
      final dayKey = _dayKey(receivedAt);
      if (sensorId != null && sensorId.isNotEmpty) {
        activeSensorsByDay.putIfAbsent(dayKey, () => <String>{}).add(sensorId);
      }
      if (_extractEventAlertCount(event) > 0 &&
          sensorId != null &&
          sensorId.isNotEmpty) {
        alertsByDay.putIfAbsent(dayKey, () => <String>{}).add(sensorId);
      }
    }

    final vibration = _extractMetricValue(event, _vibrationMetricAliases);
    if (vibration != null) {
      vibrationReadings.add(vibration);
    }
    final temperature = _extractMetricValue(event, _temperatureMetricAliases);
    if (temperature != null) {
      temperatureReadings.add(temperature);
    }

    if (liveFeedEntries.length < 4) {
      final metric = _extractPreferredMetric(event);
      if (metric != null) {
        final label = _feedTitle(
          metric: metric.label,
          siteName: siteId.isEmpty ? '' : siteById[siteId]?.name ?? '',
          sensor: sensor,
        );
        liveFeedEntries.add(
          _LiveFeedEntry(
            icon: metric.icon,
            iconColor: metric.color,
            label: label,
            timeLabel: _agoLabel(receivedAt),
            valueLabel: _formatMetricValue(metric),
            valueColor: metric.color,
          ),
        );
      }
    }
  }

  for (final alert in openAlerts) {
    final sensor = sensorById[alert.sensorId];
    final device = sensor == null ? null : deviceById[sensor.deviceId];
    final siteId = device?.siteId ?? '';
    if (siteId.isEmpty) continue;
    final dayKey = _dayKey(alert.triggeredAt);
    alertsByDay.putIfAbsent(dayKey, () => <String>{}).add(alert.sensorId);
  }

  final siteRows = _buildSiteRows(
    sites: db.sites,
    devices: db.devices,
    sensors: db.sensors,
    openAlerts: openAlerts,
    activeSensorsLast24hBySite: activeSensorsLast24hBySite,
    recentSiteMoments: recentSiteMoments,
  );

  final trendPoints = _buildTrendPoints(
    totalSensors: totalSensors,
    healthPercent: healthPercent,
    openAlertSensorCount: affectedSensorIds.length,
    activeSensorsByDay: activeSensorsByDay,
    alertsByDay: alertsByDay,
  );

  if (liveFeedEntries.isEmpty) {
    liveFeedEntries.add(
      _LiveFeedEntry(
        icon: Icons.timeline_rounded,
        iconColor: OpsColors.muted,
        label: recentEvents.isNotEmpty
            ? 'Waiting for sensor readings to map into the live feed'
            : 'No recent analytics events available',
        timeLabel: recentEvents.isNotEmpty ? 'Refreshing...' : 'No updates',
        valueLabel:
            recentEvents.isNotEmpty ? '${recentEvents.length} events' : '--',
        valueColor: OpsColors.muted,
      ),
    );
  }

  return _UserDashboardModel(
    totalSensors: totalSensors,
    onlineSensors: onlineSensors,
    warningSensors: warningSensors,
    offlineSensors: offlineSensors,
    healthPercent: healthPercent,
    openAlerts: openAlerts.length,
    activeSites: activeSites,
    maxVibration:
        vibrationReadings.isEmpty ? null : vibrationReadings.reduce(math.max),
    avgTemperature: temperatureReadings.isEmpty
        ? null
        : temperatureReadings.reduce((a, b) => a + b) /
            temperatureReadings.length,
    alertLevelCounts: alertLevelCounts,
    liveFeed: liveFeedEntries,
    siteRows: siteRows,
    trendPoints: trendPoints,
  );
}

List<_SiteOverviewRowData> _buildSiteRows({
  required List<Site> sites,
  required List<Device> devices,
  required List<Sensor> sensors,
  required List<Alert> openAlerts,
  required Map<String, Set<String>> activeSensorsLast24hBySite,
  required Map<String, DateTime> recentSiteMoments,
}) {
  final deviceSiteById = {
    for (final device in devices) device.id: device.siteId
  };
  final sensorsBySite = <String, List<Sensor>>{};
  for (final sensor in sensors) {
    final siteId = deviceSiteById[sensor.deviceId] ?? '';
    if (siteId.isEmpty) continue;
    sensorsBySite.putIfAbsent(siteId, () => <Sensor>[]).add(sensor);
  }

  final sensorById = {for (final sensor in sensors) sensor.id: sensor};
  final alertsBySite = <String, int>{};
  for (final alert in openAlerts) {
    final sensor = sensorById[alert.sensorId];
    if (sensor == null) continue;
    final siteId = deviceSiteById[sensor.deviceId] ?? '';
    if (siteId.isEmpty) continue;
    alertsBySite[siteId] = (alertsBySite[siteId] ?? 0) + 1;
  }

  final rows = <_SiteOverviewRowData>[];
  for (final site in sites) {
    final siteSensors = sensorsBySite[site.id] ?? const <Sensor>[];
    final totalSensors = siteSensors.length;
    final activeSensors = activeSensorsLast24hBySite[site.id]?.length ?? 0;
    final alerts = alertsBySite[site.id] ?? 0;
    final status = totalSensors == 0
        ? 'Offline'
        : alerts > 0
            ? 'Warning'
            : activeSensors > 0 || recentSiteMoments.containsKey(site.id)
                ? 'Online'
                : 'Offline';
    final onlineCount = totalSensors == 0
        ? 0
        : activeSensors > 0
            ? math.min(activeSensors, totalSensors).toInt()
            : math.max(totalSensors - alerts, 0).toInt();
    rows.add(
      _SiteOverviewRowData(
        site: site.name,
        status: status,
        sensors: '$onlineCount / $totalSensors',
        alerts: '$alerts',
        last: _agoLabel(recentSiteMoments[site.id]),
      ),
    );
  }

  rows.sort((a, b) {
    final statusPriority =
        _siteStatusPriority(a.status) - _siteStatusPriority(b.status);
    if (statusPriority != 0) return statusPriority;
    return a.site.compareTo(b.site);
  });

  return rows.take(5).toList();
}

List<_TrendPoint> _buildTrendPoints({
  required int totalSensors,
  required double healthPercent,
  required int openAlertSensorCount,
  required Map<String, Set<String>> activeSensorsByDay,
  required Map<String, Set<String>> alertsByDay,
}) {
  final now = DateTime.now();
  final currentAlertPercent = totalSensors == 0
      ? 0.0
      : ((openAlertSensorCount / totalSensors) * 100).clamp(0, 100).toDouble();
  final points = <_TrendPoint>[];

  for (var offset = 6; offset >= 0; offset--) {
    final day = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: offset),
    );
    final key = _dayKey(day);
    final activeForDay = activeSensorsByDay[key]?.length ?? 0;
    final alertsForDay = alertsByDay[key]?.length ?? 0;
    final onlinePercent = totalSensors == 0
        ? 0.0
        : activeForDay > 0
            ? ((activeForDay / totalSensors) * 100).clamp(0, 100).toDouble()
            : healthPercent;
    final warningPercent = totalSensors == 0
        ? 0.0
        : alertsForDay > 0
            ? ((alertsForDay / totalSensors) * 100).clamp(0, 100).toDouble()
            : currentAlertPercent;

    points.add(
      _TrendPoint(
        label: 'Day ${7 - offset}',
        onlinePercent: onlinePercent,
        warningPercent: warningPercent,
      ),
    );
  }

  return points;
}

String _feedTitle({
  required String metric,
  required String siteName,
  required Sensor? sensor,
}) {
  if (siteName.isNotEmpty) {
    return '$metric - $siteName';
  }
  if (sensor != null && sensor.serialNumber.trim().isNotEmpty) {
    return '$metric - ${sensor.serialNumber.trim()}';
  }
  return metric;
}

String _formatMetricValue(_MetricMetric metric) {
  final decimals = metric.unit == '%'
      ? 0
      : metric.unit == 'C'
          ? 1
          : 2;
  return '${_formatNumber(metric.value, decimals: decimals)} ${metric.unit}'
      .trim();
}

String _formatNumber(double value, {int decimals = 1}) {
  return value.toStringAsFixed(decimals);
}

int _siteStatusPriority(String status) {
  switch (status.toLowerCase()) {
    case 'warning':
      return 0;
    case 'offline':
      return 1;
    default:
      return 2;
  }
}

String _normalizeAlertLevel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.contains('critical')) return 'critical';
  if (normalized.contains('high')) return 'high';
  if (normalized.contains('medium')) return 'medium';
  return 'low';
}

String _dayKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime? _extractEventDateTime(Map<String, dynamic> event) {
  for (final candidate in _candidateMaps(event)) {
    for (final key in const [
      'receivedAt',
      'timestamp',
      'createdAt',
      'updatedAt',
      'eventTime',
      'time',
    ]) {
      final parsed = _asDateTime(candidate[key]);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _extractSensorId(Map<String, dynamic> event) {
  for (final candidate in _candidateMaps(event)) {
    final sensorId = (candidate['sensorId'] ?? candidate['sensor_id'] ?? '')
        .toString()
        .trim();
    if (sensorId.isNotEmpty) return sensorId;
  }
  return null;
}

int _extractEventAlertCount(Map<String, dynamic> event) {
  for (final candidate in _candidateMaps(event)) {
    final raw = candidate['alertCount'] ?? candidate['alertsCount'];
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

_MetricMetric? _extractPreferredMetric(Map<String, dynamic> event) {
  for (final definition in _metricDefinitions) {
    final value = _extractMetricValue(event, definition.aliases);
    if (value == null) continue;
    return _MetricMetric(
      label: definition.label,
      unit: definition.unit,
      value: value,
      icon: definition.icon,
      color: definition.color,
    );
  }
  return null;
}

double? _extractMetricValue(
  Map<String, dynamic> event,
  List<String> aliases,
) {
  final normalizedAliases =
      aliases.map(_normalizeMetricKey).where((key) => key.isNotEmpty).toSet();

  for (final candidate in _candidateMaps(event)) {
    for (final entry in candidate.entries) {
      if (normalizedAliases
          .contains(_normalizeMetricKey(entry.key.toString()))) {
        final parsed = _asDouble(entry.value);
        if (parsed != null) return parsed;
      }
    }

    final parameters = candidate['parameters'];
    if (parameters is Map) {
      for (final entry in parameters.entries) {
        if (normalizedAliases
            .contains(_normalizeMetricKey(entry.key.toString()))) {
          final parsed = _asDouble(entry.value);
          if (parsed != null) return parsed;
        }
      }
    }

    final series = candidate['series'];
    if (series is List) {
      for (final item in series) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        if (!normalizedAliases.contains(_normalizeMetricKey(name))) continue;
        final parsed = _asDouble(item['value']);
        if (parsed != null) return parsed;
      }
    }

    final evaluations = candidate['evaluations'];
    if (evaluations is List) {
      for (final item in evaluations) {
        if (item is! Map) continue;
        final name =
            item['parameterName']?.toString() ?? item['name']?.toString() ?? '';
        if (!normalizedAliases.contains(_normalizeMetricKey(name))) continue;
        final parsed = _asDouble(item['value']);
        if (parsed != null) return parsed;
      }
    }
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

String _normalizeMetricKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    final raw = value.toDouble();
    final milliseconds =
        raw > 1000000000000 ? raw.round() : (raw * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final direct = DateTime.tryParse(text);
  if (direct != null) return direct;

  final number = double.tryParse(text);
  if (number == null) return null;
  final milliseconds =
      number > 1000000000000 ? number.round() : (number * 1000).round();
  return DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

String _agoLabel(DateTime? when) {
  if (when == null) return 'No updates';
  final delta = DateTime.now().difference(when.toLocal());
  if (delta.inSeconds < 10) return 'Just now';
  if (delta.inMinutes < 1) return '${delta.inSeconds}s ago';
  if (delta.inHours < 1) return '${delta.inMinutes} mins ago';
  if (delta.inDays < 1) return '${delta.inHours} hrs ago';
  return '${delta.inDays} days ago';
}

const List<String> _vibrationMetricAliases = [
  'vibRMS',
  'vibrationRms',
  'vibration.vibrationRms',
  'horizontalMagnitude',
  'accelerationMagnitude',
];

const List<String> _temperatureMetricAliases = [
  'temperature',
  'temperatureC',
  'temp',
  'tempC',
];

const List<_MetricDefinition> _metricDefinitions = [
  _MetricDefinition(
    label: 'Temperature',
    unit: 'C',
    icon: Icons.device_thermostat_rounded,
    color: OpsColors.primary,
    aliases: _temperatureMetricAliases,
  ),
  _MetricDefinition(
    label: 'Humidity',
    unit: '%',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF3B82F6),
    aliases: ['humidity', 'humidityPercent', 'rh'],
  ),
  _MetricDefinition(
    label: 'Vibration',
    unit: 'mm/s',
    icon: Icons.vibration_rounded,
    color: OpsColors.danger,
    aliases: _vibrationMetricAliases,
  ),
  _MetricDefinition(
    label: 'Tilt',
    unit: 'deg',
    icon: Icons.architecture_rounded,
    color: OpsColors.amber,
    aliases: ['tiltFromVerticalDegrees', 'inclinationDegrees', 'tilt'],
  ),
];

class _SensorStatusDonut extends StatelessWidget {
  const _SensorStatusDonut({
    required this.online,
    required this.warning,
    required this.offline,
  });

  final int online;
  final int warning;
  final int offline;

  @override
  Widget build(BuildContext context) {
    final total = math.max(online + warning + offline, 1);
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _DonutPainter(
                  online: online / total,
                  warning: warning / total,
                  offline: offline / total,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${online + warning + offline}',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text('TOTAL', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        _legend('Online', online, total, OpsColors.success),
        _legend('Warning', warning, total, OpsColors.amber),
        _legend('Offline', offline, total, OpsColors.danger),
      ],
    );
  }

  Widget _legend(String label, int value, int total, Color color) {
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
            '$value (${((value / total) * 100).round()}%)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.online,
    required this.warning,
    required this.offline,
  });

  final double online;
  final double warning;
  final double offline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    var start = -math.pi / 2;
    for (final segment in [
      (offline, OpsColors.danger),
      (warning, OpsColors.amber),
      (online, OpsColors.success),
    ]) {
      paint.color = segment.$2;
      final sweep = math.max(segment.$1, .02) * math.pi * 2;
      canvas.drawArc(rect.deflate(14), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.online != online ||
        oldDelegate.warning != warning ||
        oldDelegate.offline != offline;
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({
    required this.counts,
    required this.totalAlerts,
  });

  final Map<String, int> counts;
  final int totalAlerts;

  @override
  Widget build(BuildContext context) {
    final total = math.max(totalAlerts, 1);
    final critical = counts['critical'] ?? 0;
    final high = counts['high'] ?? 0;
    final medium = counts['medium'] ?? 0;
    final low = counts['low'] ?? 0;

    return Column(
      children: [
        _CategoryRow('Critical', critical, critical / total, OpsColors.danger),
        _CategoryRow('High', high, high / total, const Color(0xFFF97316)),
        _CategoryRow('Medium', medium, medium / total, OpsColors.amber),
        _CategoryRow('Low', low, low / total, OpsColors.primary),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(this.label, this.value, this.factor, this.color);

  final String label;
  final int value;
  final double factor;
  final Color color;

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
              value: factor.isFinite ? factor.clamp(0, 1) : 0,
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

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

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

class _LiveFeed extends StatelessWidget {
  const _LiveFeed({required this.entries});

  final List<_LiveFeedEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.indexed.map((entry) {
        final index = entry.$1;
        final row = entry.$2;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: index == entries.length - 1
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFECEEF0))),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: row.iconColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(row.icon, color: row.iconColor, size: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(row.timeLabel,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                row.valueLabel,
                style: TextStyle(
                  color: row.valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SiteOverviewTable extends StatelessWidget {
  const _SiteOverviewTable({required this.rows});

  final List<_SiteOverviewRowData> rows;

  @override
  Widget build(BuildContext context) {
    final displayRows = rows.isEmpty
        ? const [
            _SiteOverviewRowData(
              site: 'No sites found',
              status: 'Offline',
              sensors: '0 / 0',
              alerts: '0',
              last: 'No updates',
            ),
          ]
        : rows;

    return Column(
      children: [
        const _SiteRow(
          site: 'SITE',
          status: 'STATUS',
          sensors: 'SENSORS',
          alerts: 'ALERTS',
          last: 'LAST',
          header: true,
        ),
        const Divider(height: 16),
        ...displayRows.map(
          (row) => _SiteRow(
            site: row.site,
            status: row.status,
            sensors: row.sensors,
            alerts: row.alerts,
            last: row.last,
          ),
        ),
      ],
    );
  }
}

class _SiteRow extends StatelessWidget {
  const _SiteRow({
    required this.site,
    required this.status,
    required this.sensors,
    required this.alerts,
    required this.last,
    this.header = false,
  });

  final String site;
  final String status;
  final String sensors;
  final String alerts;
  final String last;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final alertColor = alerts == '0'
        ? OpsColors.muted
        : alerts == '1'
            ? OpsColors.warning
            : OpsColors.danger;
    final textStyle = TextStyle(
      color: header ? OpsColors.outline : OpsColors.text,
      fontWeight: header ? FontWeight.w800 : FontWeight.w600,
      fontSize: header ? 11 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(site, style: textStyle)),
          Expanded(
            flex: 2,
            child: header
                ? Text(status, style: textStyle)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: OpsStatusBadge(status),
                  ),
          ),
          Expanded(
            child: Text(
              sensors,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
          Expanded(
            child: Text(
              alerts,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(
                color: header ? OpsColors.outline : alertColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              last,
              style: textStyle.copyWith(
                color: header ? OpsColors.outline : OpsColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTrend extends StatelessWidget {
  const _HealthTrend({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 286,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                _LegendDot('Online', OpsColors.success),
                SizedBox(width: 14),
                _LegendDot('Warning', OpsColors.amber),
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
              painter: _TrendPainter(points: points),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 38,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map((point) => Text(point.label))
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.color);

  final String label;
  final Color color;

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

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points});

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = OpsColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawLine(
      canvas,
      size,
      points.map((point) => point.onlinePercent).toList(growable: false),
      OpsColors.success,
    );
    _drawLine(
      canvas,
      size,
      points.map((point) => point.warningPercent).toList(growable: false),
      OpsColors.amber,
    );
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

    final denominator = math.max(values.length - 1, 1);
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / denominator;
      final y = size.height - (values[i].clamp(0, 100) / 100 * size.height);
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
        Offset(math.min(x + dash, end.dx), end.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) return true;
    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return false;
  }
}

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

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
          Text('Data updates every 60 seconds',
              style: TextStyle(color: OpsColors.muted)),
        ],
      ),
    );
  }
}

class _UserDashboardModel {
  const _UserDashboardModel({
    required this.totalSensors,
    required this.onlineSensors,
    required this.warningSensors,
    required this.offlineSensors,
    required this.healthPercent,
    required this.openAlerts,
    required this.activeSites,
    required this.maxVibration,
    required this.avgTemperature,
    required this.alertLevelCounts,
    required this.liveFeed,
    required this.siteRows,
    required this.trendPoints,
  });

  final int totalSensors;
  final int onlineSensors;
  final int warningSensors;
  final int offlineSensors;
  final double healthPercent;
  final int openAlerts;
  final int activeSites;
  final double? maxVibration;
  final double? avgTemperature;
  final Map<String, int> alertLevelCounts;
  final List<_LiveFeedEntry> liveFeed;
  final List<_SiteOverviewRowData> siteRows;
  final List<_TrendPoint> trendPoints;
}

class _LiveFeedEntry {
  const _LiveFeedEntry({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.timeLabel,
    required this.valueLabel,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String timeLabel;
  final String valueLabel;
  final Color valueColor;
}

class _SiteOverviewRowData {
  const _SiteOverviewRowData({
    required this.site,
    required this.status,
    required this.sensors,
    required this.alerts,
    required this.last,
  });

  final String site;
  final String status;
  final String sensors;
  final String alerts;
  final String last;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.onlinePercent,
    required this.warningPercent,
  });

  final String label;
  final double onlinePercent;
  final double warningPercent;

  @override
  bool operator ==(Object other) {
    return other is _TrendPoint &&
        other.label == label &&
        other.onlinePercent == onlinePercent &&
        other.warningPercent == warningPercent;
  }

  @override
  int get hashCode => Object.hash(label, onlinePercent, warningPercent);
}

class _MetricDefinition {
  const _MetricDefinition({
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
    required this.aliases,
  });

  final String label;
  final String unit;
  final IconData icon;
  final Color color;
  final List<String> aliases;
}

class _MetricMetric {
  const _MetricMetric({
    required this.label,
    required this.unit,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String unit;
  final double value;
  final IconData icon;
  final Color color;
}
