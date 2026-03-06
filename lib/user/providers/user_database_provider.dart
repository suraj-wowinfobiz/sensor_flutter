import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../super_admin/api/device_api.dart';
import '../../super_admin/api/sensor_api.dart';
import '../../super_admin/shared/models/threshold_rule.dart';
import '../api/alerts_api.dart';
import '../api/thresholds_api.dart';
import '../models/alert.dart';
import '../models/audit_log.dart';
import '../models/config.dart';
import '../models/device.dart';
import '../models/organization.dart';
import '../models/sensor.dart';
import '../models/sensor_parameter.dart';
import '../models/sensor_type.dart';
import '../models/site.dart';
import '../models/threshold_profile.dart';
import '../models/threshold_value.dart';
import '../models/user.dart';
import '../models/zone.dart';

class UserDatabaseProvider extends ChangeNotifier {
  late List<Organization> organizations;
  late List<Site> sites;
  late List<Zone> zones;
  late List<Device> devices;
  late List<SensorType> sensorTypes;
  late List<Sensor> sensors;
  late List<SensorParameter> sensorParameters;
  late List<ThresholdProfile> thresholdProfiles;
  late List<ThresholdValue> thresholdValues;
  late List<Alert> alerts;
  late List<User> users;
  late List<AuditLog> auditLogs;
  late Config config;

  String currentView = 'dashboard';
  Future<void>? _loadDevicesTask;
  Future<void>? _loadSensorsTask;

  int _thresholdRuleSeed = 4;
  final List<ThresholdRule> _thresholdRules = [
    const ThresholdRule(
      id: 'warning',
      label: 'Warning',
      value: 2.8,
      sound: 'Soft Chime',
      color: Color(0xFFD39A00),
      graphTargets: {
        ThresholdGraphTarget.analyticsMain,
        ThresholdGraphTarget.dashboardRealtime,
        ThresholdGraphTarget.dashboardThresholdMonitoring,
      },
    ),
    const ThresholdRule(
      id: 'critical',
      label: 'Critical',
      value: 4.0,
      sound: 'Siren',
      color: Color(0xFFE54C4C),
      graphTargets: {
        ThresholdGraphTarget.analyticsMain,
        ThresholdGraphTarget.dashboardRealtime,
        ThresholdGraphTarget.dashboardThresholdMonitoring,
      },
    ),
    const ThresholdRule(
      id: 'emergency',
      label: 'Emergency',
      value: 5.2,
      sound: 'Emergency Bell',
      color: Color(0xFF7A4FD6),
      graphTargets: {
        ThresholdGraphTarget.analyticsMain,
        ThresholdGraphTarget.dashboardRealtime,
        ThresholdGraphTarget.dashboardThresholdMonitoring,
      },
    ),
  ];

  UserDatabaseProvider() {
    _initializeData();
  }

  void _initializeData() {
    organizations = [];
    sites = [];
    zones = [];
    devices = [];
    sensorTypes = [];
    sensors = [];
    sensorParameters = [];
    thresholdProfiles = [];
    thresholdValues = [];
    users = [];
    alerts = [];
    auditLogs = [];

    config = Config(
      globalThreshold: 3.0,
      warningThreshold: 2.6,
      criticalThreshold: 4.2,
      retentionDays: 90,
      alertNotification: true,
      backupEnabled: true,
      backupFrequency: 'daily',
      apiRateLimit: 1000,
    );
  }

  void setCurrentView(String view) {
    if (view == currentView) return;
    currentView = view;
    notifyListeners();
  }

  String _uuid() {
    const chars = '0123456789abcdef';
    final random = Random();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.split('').map((c) {
      if (c == 'x') return chars[random.nextInt(16)];
      if (c == 'y') return chars[random.nextInt(4) + 8];
      return c;
    }).join();
  }

  String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? fallback : parsed;
  }

  DateTime _asDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {
        // Ignore malformed payloads.
      }
    }
    return const <String, dynamic>{};
  }

  Future<void> loadOrganizations() async {
    organizations = [];
    notifyListeners();
  }

  Future<void> loadSites() async {
    sites = [];
    notifyListeners();
  }

  Future<void> loadZones(String siteId) async {
    zones.removeWhere((z) => z.siteId == siteId);
    notifyListeners();
  }

  Future<void> loadUsers() async {
    users = [];
    notifyListeners();
  }

  Future<void> loadDevices() async {
    if (_loadDevicesTask != null) return _loadDevicesTask!;

    final task = () async {
      final body = await DeviceApi.getAllDevices();
      final loaded = body.map((json) {
        final payload = _asMap(json['data']);
        final data = payload.isNotEmpty ? payload : json;
        final rawSite = data['site'];
        final rawZone = data['zone'];

        return Device(
          id: _asString(data['id'] ?? data['deviceId'] ?? json['id'], _uuid()),
          siteId: _asString(
            data['siteId'] ?? data['site_id'] ?? data['sitesID'],
            rawSite is Map ? _asString(rawSite['sitesID']) : '',
          ),
          zoneId: _asString(
            data['zoneId'] ?? data['zone_id'],
            rawZone is Map ? _asString(rawZone['zoneId']) : '',
          ),
          deviceCode: _asString(
            data['serialNumber'] ?? data['device_code'] ?? data['name'],
            'DEV-${_uuid().substring(0, 8)}',
          ),
          status: _asString(data['status'], 'active').toLowerCase(),
          installedAt: _asDate(
            data['lastHeartBeat'] ?? data['installed_at'] ?? data['createdAt'],
          ),
        );
      }).toList();

      final deduped = <String, Device>{};
      for (final item in loaded) {
        deduped[item.id] = item;
      }
      devices = deduped.values.toList();
    }();

    _loadDevicesTask = task;
    try {
      await task;
    } finally {
      _loadDevicesTask = null;
    }
    notifyListeners();
  }

  Future<void> loadSensors() async {
    if (_loadSensorsTask != null) return _loadSensorsTask!;

    final task = () async {
      final body = await SensorApi.getAllSensors();
      final loadedSensors = <Sensor>[];
      final mappedTypes = <String, SensorType>{};

      for (final json in body) {
        final rawType = json['sensorType'];
        final sensorTypeId = _asString(
          json['sensorTypeId'] ??
              json['sensor_type_id'] ??
              (rawType is Map ? rawType['sensorTypeId'] : null),
        );

        loadedSensors.add(
          Sensor(
            id: _asString(json['sensorId'] ?? json['id'], _uuid()),
            deviceId: _asString(json['deviceId'] ?? json['device_id']),
            sensorTypeId: sensorTypeId,
            serialNumber: _asString(
              json['name'] ?? json['serial_number'],
              'SEN-${_uuid().substring(0, 8)}',
            ),
            installedAt: _asDate(json['createdAt'] ?? json['installed_at']),
            lastReading: _asDouble(json['last_reading']),
          ),
        );

        if (rawType is Map && sensorTypeId.isNotEmpty) {
          mappedTypes[sensorTypeId] = SensorType(
            id: sensorTypeId,
            name: _asString(rawType['name'], 'Sensor Type'),
            category: _asString(rawType['category'], 'general'),
            description: _asString(rawType['description']),
          );
        }
      }

      final dedupedSensors = <String, Sensor>{};
      for (final sensor in loadedSensors) {
        dedupedSensors[sensor.id] = sensor;
      }
      sensors = dedupedSensors.values.toList();

      for (final sensor in sensors) {
        if (sensor.sensorTypeId.isEmpty ||
            mappedTypes.containsKey(sensor.sensorTypeId)) {
          continue;
        }
        mappedTypes[sensor.sensorTypeId] = SensorType(
          id: sensor.sensorTypeId,
          name:
              'Sensor Type ${sensor.sensorTypeId.substring(0, sensor.sensorTypeId.length < 6 ? sensor.sensorTypeId.length : 6)}',
          category: 'general',
          description: '',
        );
      }

      sensorTypes = mappedTypes.values.toList();
    }();

    _loadSensorsTask = task;
    try {
      await task;
    } finally {
      _loadSensorsTask = null;
    }
    notifyListeners();
  }

  Future<void> loadSensorTypes() async {
    final byId = <String, SensorType>{};
    for (final sensor in sensors) {
      if (sensor.sensorTypeId.isEmpty) continue;
      byId[sensor.sensorTypeId] = SensorType(
        id: sensor.sensorTypeId,
        name: byId[sensor.sensorTypeId]?.name ??
            'Sensor Type ${sensor.sensorTypeId.substring(0, sensor.sensorTypeId.length < 6 ? sensor.sensorTypeId.length : 6)}',
        category: 'general',
        description: '',
      );
    }
    sensorTypes = byId.values.toList();
    notifyListeners();
  }

  Future<void> loadThresholdProfiles() async {
    try {
      final body = await ThresholdsApi.getProfiles();
      thresholdProfiles = body.map((json) {
        return ThresholdProfile(
          id: _asString(json['thresholdProfileId'] ?? json['id'], _uuid()),
          name: _asString(json['name'], 'Profile'),
          description: _asString(json['description']),
        );
      }).toList();
    } catch (_) {
      thresholdProfiles = [];
    }
    notifyListeners();
  }

  Future<void> loadThresholdValues() async {
    try {
      final body = await ThresholdsApi.getThresholds();
      thresholdValues = body.map((json) {
        return ThresholdValue(
          id: _asString(
            json['thresholdValueId'] ?? json['thresholdId'] ?? json['id'],
            _uuid(),
          ),
          sensorParameterId: _asString(
            json['sensorParameterId'] ??
                json['sensorParamterId'] ??
                json['sensor_parameter_id'],
          ),
          thresholdProfileId: _asString(
            json['thresholdProfileId'] ?? json['threshold_profile_id'],
          ),
          minThreshold:
              _asDouble(json['minThresholdValue'] ?? json['min_threshold']),
          maxThreshold:
              _asDouble(json['maxThresholdValue'] ?? json['max_threshold']),
          warningLevel: _asDouble(
            json['warningLevel'] ??
                json['warrningLevel'] ??
                json['warning_level'],
          ),
          criticalLevel:
              _asDouble(json['criticalLevel'] ?? json['critical_level']),
        );
      }).toList();
    } catch (_) {
      thresholdValues = [];
    }
    notifyListeners();
  }

  Future<void> loadAlerts() async {
    try {
      alerts = await AlertsApi.getAlerts();
    } catch (_) {
      alerts = [];
    }
    notifyListeners();
  }

  Future<void> create(String view, Map<String, dynamic> data) async {
    switch (view) {
      case 'devices':
        await DeviceApi.createDevice(
          deviceId: _asString(data['device_id']),
          organizationId: _asString(data['organization_id']),
          siteId: _asString(data['site_id']),
          zoneId: _asString(data['zone_id']),
          serialNumber: _asString(data['serial_number']),
          firmwareVersion: _asString(data['firmware_version']),
          macAddress: _asString(data['mac_address']),
          ipAddress: _asString(data['ip_address']),
          numberOfChannels: _asInt(data['number_of_channels']),
          webHookUrl: _asString(data['web_hook_url']),
          lat: _asDouble(data['lat']),
          log: _asDouble(data['log']),
          lastHeartBeat: _asString(data['last_heart_beat']),
          status: _asString(data['status'], 'active'),
        );
        await loadDevices();
        break;
      case 'sensors':
        final sensorId = _asString(data['sensor_id'] ?? data['sensorId']);
        await SensorApi.createSensor(
          sensorId: sensorId.isEmpty ? null : sensorId,
          deviceId: _asString(data['device_id']),
          sensorTypeId: _asString(data['sensor_type_id']),
          name: _asString(data['name'] ?? data['serial_number'], 'Sensor'),
          serialNumber: _asString(data['serial_number']),
          macAddress: _asString(data['mac_address']),
          channelNumber: int.tryParse(_asString(data['channel_number'])),
          lat: double.tryParse(_asString(data['lat'])),
          log: double.tryParse(_asString(data['log'])),
          status: _asString(data['status'], 'ACTIVE'),
          unit: _asString(data['unit']),
        );
        await loadSensors();
        break;
      default:
        // User app is API-read focused for devices and sensors only.
        break;
    }
  }

  Future<void> update(String view, String id, Map<String, dynamic> data) async {
    switch (view) {
      case 'devices':
        await DeviceApi.updateDevice(
          deviceId: id,
          organizationId: _asString(data['organization_id']),
          siteId: _asString(data['site_id']),
          zoneId: _asString(data['zone_id']),
          serialNumber: _asString(data['serial_number'] ?? data['device_code']),
          firmwareVersion: _asString(data['firmware_version'], '1.0.0'),
          macAddress: _asString(data['mac_address']),
          ipAddress: _asString(data['ip_address']),
          numberOfChannels: _asInt(data['number_of_channels']),
          webHookUrl: _asString(data['web_hook_url']),
          lat: _asDouble(data['lat']),
          log: _asDouble(data['log']),
          lastHeartBeat: _asString(
            data['last_heart_beat'],
            DateTime.now().toIso8601String(),
          ),
          status: _asString(data['status'], 'active'),
        );
        await loadDevices();
        break;
      case 'sensors':
        await SensorApi.updateSensor(
          sensorId: id,
          deviceId: _asString(data['device_id']),
          sensorTypeId: _asString(data['sensor_type_id']),
          name: _asString(data['name'] ?? data['serial_number'], 'Sensor'),
          serialNumber: _asString(data['serial_number']),
          macAddress: _asString(data['mac_address']),
          channelNumber: int.tryParse(_asString(data['channel_number'])),
          lat: double.tryParse(_asString(data['lat'])),
          log: double.tryParse(_asString(data['log'])),
          status: _asString(data['status'], 'ACTIVE'),
          unit: _asString(data['unit']),
        );
        await loadSensors();
        break;
      default:
        break;
    }
  }

  Future<void> delete(String view, String id) async {
    switch (view) {
      case 'devices':
        await DeviceApi.deleteDevice(id);
        await loadDevices();
        break;
      case 'sensors':
        await SensorApi.deleteSensor(id);
        await loadSensors();
        break;
      default:
        break;
    }
  }

  Future<void> resolveAlert(String id) async {
    try {
      await AlertsApi.resolveAlert(id);
    } catch (_) {
      // Keep UI responsive and still clear local list entry.
    }
    alerts.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  List<Alert> getActiveAlerts() => alerts.where((a) => !a.isResolved).toList();

  String nextThresholdRuleId() => 'custom_${_thresholdRuleSeed++}';

  List<ThresholdRule> get thresholdRules =>
      List<ThresholdRule>.unmodifiable(_thresholdRules);

  List<ThresholdRule> get sortedThresholdRules {
    final sorted = List<ThresholdRule>.from(_thresholdRules)
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted;
  }

  List<ThresholdRule> thresholdRulesForGraph(ThresholdGraphTarget target) {
    return sortedThresholdRules
        .where((rule) => rule.graphTargets.contains(target))
        .toList();
  }

  void saveThresholdRule(ThresholdRule rule) {
    final index = _thresholdRules.indexWhere((r) => r.id == rule.id);
    if (index == -1) {
      _thresholdRules.add(rule);
    } else {
      _thresholdRules[index] = rule;
    }
    notifyListeners();
  }

  void deleteThresholdRule(String id) {
    _thresholdRules.removeWhere((rule) => rule.id == id);
    notifyListeners();
  }

  int getStats(String type) {
    switch (type) {
      case 'sensors':
        return sensors.length;
      case 'alerts':
        return getActiveAlerts().length;
      default:
        return 0;
    }
  }
}
