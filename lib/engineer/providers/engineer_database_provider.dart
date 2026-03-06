import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../api/alerts_api.dart';
import '../api/device_api.dart';
import '../api/organization_api.dart' as org_api;
import '../api/sensor_api.dart';
import '../api/sensor_type_api.dart';
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
import '../../super_admin/shared/models/threshold_rule.dart';

class EngineerDatabaseProvider extends ChangeNotifier {
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

  EngineerDatabaseProvider() {
    _initializeData();
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

  Future<void> loadOrganizations() async {
    try {
      final res = await org_api.OrgServiceApi.getAllOrganizations();
      final body = res.body;
      if (body is! List) {
        organizations = [];
      } else {
        organizations = body.map((json) {
          final item = json as Map;
          return Organization(
            id: _asString(item['organizationId']),
            name: _asString(item['name'], 'Organization'),
            email: _asString(item['email']),
            status: _asString(item['status'], 'active').toLowerCase(),
            ownerUserId: _asString(item['ownerUserId']),
            createdAt: _asDate(item['createdAt']),
          );
        }).toList();
      }
    } catch (_) {
      organizations = [];
    }
    notifyListeners();
  }

  Future<void> loadSites() async {
    try {
      final res = await org_api.OrgServiceApi.getAllSites();
      final body = res.body;
      if (body is! List) {
        sites = [];
      } else {
        final mappedSites = <String, Site>{};
        for (final raw in body) {
          if (raw is! Map) continue;
          final org = raw['organization'];
          final id = _asString(raw['sitesID']);
          if (id.isEmpty) continue;
          mappedSites[id] = Site(
            id: id,
            organizationId: org is Map ? _asString(org['organizationId']) : '',
            name: _asString(raw['name']),
            location: _asString(raw['location']),
            createdAt: _asDate(raw['createdAt']),
          );
        }
        sites = mappedSites.values.toList();
      }
    } catch (_) {
      sites = [];
    }
    notifyListeners();
  }

  Future<void> loadZones(String siteId) async {
    try {
      final res = await org_api.OrgServiceApi.getZonesBySite(siteId);
      final body = res.body;
      if (body is! List) {
        zones.removeWhere((z) => z.siteId == siteId);
        notifyListeners();
        return;
      }
      final newZones = body.map((json) {
        final item = json as Map;
        final site = item['site'];
        return Zone(
          id: _asString(item['zoneId']),
          siteId: site is Map ? _asString(site['sitesID'], siteId) : siteId,
          name: _asString(item['name']),
        );
      }).toList();
      zones.removeWhere((z) => z.siteId == siteId);
      zones.addAll(newZones);
    } catch (_) {
      zones.removeWhere((z) => z.siteId == siteId);
    }
    notifyListeners();
  }

  Future<void> loadDevices() async {
    if (_loadDevicesTask != null) return _loadDevicesTask!;

    final task = () async {
      try {
        final body = await DeviceApi.getAllDevices();
        final loaded = body.map((json) {
          final payload = _asMap(json['data']);
          final data = payload.isNotEmpty ? payload : json;
          final rawSite = data['site'];
          final rawZone = data['zone'];

          return Device(
            id: _asString(
                data['id'] ?? data['deviceId'] ?? json['id'], _uuid()),
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
              data['lastHeartBeat'] ??
                  data['installed_at'] ??
                  data['createdAt'],
            ),
            serialNumber:
                _asString(data['serialNumber'] ?? data['serial_number']),
            firmwareVersion:
                _asString(data['firmwareVersion'] ?? data['firmware_version']),
            macAddress: _asString(data['macAddress'] ?? data['mac_address']),
            ipAddress: _asString(data['ipAddress'] ?? data['ip_address']),
            numberOfChannels: int.tryParse(
                  _asString(
                    data['numberOfChannels'] ?? data['number_of_channels'],
                    '0',
                  ),
                ) ??
                0,
            webHookUrl: _asString(data['webHookUrl'] ?? data['web_hook_url']),
            lat: double.tryParse(_asString(data['lat'], '0')) ?? 0.0,
            log: double.tryParse(_asString(data['log'], '0')) ?? 0.0,
            lastHeartBeat:
                _asString(data['lastHeartBeat'] ?? data['last_heart_beat']),
          );
        }).toList();

        final deduped = <String, Device>{};
        for (final item in loaded) {
          deduped[item.id] = item;
        }
        devices = deduped.values.toList();
      } catch (_) {
        devices = [];
      }
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
      try {
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
      } catch (_) {
        sensors = [];
        sensorTypes = [];
      }
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
    try {
      final body = await SensorTypeApi.getAllSensorTypes();
      final loaded = body.map((json) {
        return SensorType(
          id: _asString(
            json['sensorTypeId'] ?? json['id'],
            _uuid(),
          ),
          name: _asString(json['name'], 'Sensor Type'),
          category: _asString(json['category'], 'general'),
          description: _asString(json['description']),
        );
      }).toList();
      final deduped = <String, SensorType>{};
      for (final item in loaded) {
        deduped[item.id] = item;
      }
      sensorTypes = deduped.values.toList();
    } catch (_) {
      sensorTypes = [];
    }
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
      case 'organizations':
        organizations.add(Organization(
          id: _uuid(),
          name: data['name'] as String,
          email: data['email'] as String,
          status: data['status'] as String,
          ownerUserId: data['owner_user_id'] as String,
          createdAt: DateTime.now(),
        ));
        break;
      case 'sites':
        sites.add(Site(
          id: _uuid(),
          name: data['name'] as String,
          location: data['location'] as String,
          organizationId: data['organization_id'] as String,
          createdAt: DateTime.now(),
        ));
        break;
      case 'zones':
        zones.add(Zone(
          id: _uuid(),
          name: data['name'] as String,
          siteId: data['site_id'] as String,
        ));
        break;
      case 'devices':
        final siteId = _asString(data['site_id']);
        final site = sites.where((s) => s.id == siteId).firstOrNull;
        await DeviceApi.createDevice(
          deviceId: '',
          organizationId:
              _asString(data['organization_id'], site?.organizationId ?? ''),
          siteId: siteId,
          zoneId: _asString(data['zone_id']),
          serialNumber: _asString(data['serial_number'] ?? data['device_code']),
          firmwareVersion: _asString(data['firmware_version'], '1.0.0'),
          macAddress: _asString(data['mac_address']),
          ipAddress: _asString(data['ip_address']),
          numberOfChannels: _asInt(data['number_of_channels'], 1),
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
      case 'sensor_types':
        await SensorTypeApi.createSensorType(
          name: _asString(data['name'], 'Sensor Type'),
          category: _asString(data['category'], 'general'),
          description: _asString(data['description']),
        );
        await loadSensorTypes();
        break;
      case 'thresholds':
        thresholdProfiles.add(ThresholdProfile(
          id: _uuid(),
          name: data['name'] as String,
          description: data['description'] as String,
        ));
        break;
      case 'users':
        users.add(User(
          id: _uuid(),
          name: data['name'] as String,
          email: data['email'] as String,
          role: data['role'] as String,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        break;
      case 'audit':
        auditLogs.add(AuditLog(
          id: _uuid(),
          userId: data['user_id'] as String,
          action: data['action'] as String,
          resource: data['resource'] as String,
          timestamp: DateTime.now(),
          ip: data['ip'] as String,
        ));
        break;
      case 'alerts':
        await AlertsApi.createAlert(
          sensorId: _asString(data['sensor_id'] ?? data['sensorId']),
          sensorParameterId: _asString(
            data['sensor_parameter_id'] ?? data['sensorParameterId'],
          ),
          alertLevel: _asString(data['alert_level'] ?? data['alertLevel']),
          message: _asString(data['message']),
          assignedTo:
              _asString(data['assigned_to'] ?? data['assignedTo'], 'engineer'),
        );
        await loadAlerts();
        break;
    }
    notifyListeners();
  }

  Future<void> update(String view, String id, Map<String, dynamic> data) async {
    if (view == 'config') {
      config = config.copyWith(
        globalThreshold: (data['global_threshold'] as num).toDouble(),
        warningThreshold: (data['warning_threshold'] as num).toDouble(),
        criticalThreshold: (data['critical_threshold'] as num).toDouble(),
        retentionDays: data['retention_days'] as int,
        alertNotification: data['alert_notification'] as bool,
        backupEnabled: data['backup_enabled'] as bool,
        backupFrequency: data['backup_frequency'] as String,
        apiRateLimit: data['api_rate_limit'] as int,
      );
      notifyListeners();
      return;
    }

    switch (view) {
      case 'organizations':
        final index = organizations.indexWhere((item) => item.id == id);
        if (index != -1) {
          organizations[index] = organizations[index].copyWith(
            name: data['name'] as String,
            email: data['email'] as String,
            status: data['status'] as String,
          );
        }
        break;
      case 'sites':
        final index = sites.indexWhere((item) => item.id == id);
        if (index != -1) {
          sites[index] = sites[index].copyWith(
            name: data['name'] as String,
            location: data['location'] as String,
            organizationId: data['organization_id'] as String,
          );
        }
        break;
      case 'zones':
        final index = zones.indexWhere((item) => item.id == id);
        if (index != -1) {
          zones[index] = zones[index].copyWith(
            name: data['name'] as String,
            siteId: data['site_id'] as String,
          );
        }
        break;
      case 'devices':
        final existing = devices.where((item) => item.id == id).firstOrNull;
        final siteId = _asString(data['site_id'], existing?.siteId ?? '');
        final site = sites.where((s) => s.id == siteId).firstOrNull;
        await DeviceApi.updateDevice(
          deviceId: id,
          organizationId: _asString(
            data['organization_id'],
            site?.organizationId ?? '',
          ),
          siteId: siteId,
          zoneId: _asString(data['zone_id'], existing?.zoneId ?? ''),
          serialNumber: _asString(
            data['serial_number'] ??
                data['device_code'] ??
                existing?.deviceCode,
          ),
          firmwareVersion: _asString(data['firmware_version'], '1.0.0'),
          macAddress: _asString(data['mac_address']),
          ipAddress: _asString(data['ip_address']),
          numberOfChannels: _asInt(
            data['number_of_channels'],
            1,
          ),
          webHookUrl: _asString(data['web_hook_url']),
          lat: _asDouble(data['lat'], 0),
          log: _asDouble(data['log'], 0),
          lastHeartBeat: _asString(
            data['last_heart_beat'],
            DateTime.now().toIso8601String(),
          ),
          status: _asString(data['status'], existing?.status ?? 'active'),
        );
        await loadDevices();
        break;
      case 'sensors':
        final existing = sensors.where((item) => item.id == id).firstOrNull;
        await SensorApi.updateSensor(
          sensorId: id,
          deviceId: _asString(data['device_id'], existing?.deviceId ?? ''),
          sensorTypeId:
              _asString(data['sensor_type_id'], existing?.sensorTypeId ?? ''),
          name: _asString(data['name'] ?? data['serial_number'], 'Sensor'),
          serialNumber:
              _asString(data['serial_number'], existing?.serialNumber ?? ''),
          macAddress: _asString(data['mac_address']),
          channelNumber: int.tryParse(_asString(data['channel_number'])),
          lat: double.tryParse(_asString(data['lat'])),
          log: double.tryParse(_asString(data['log'])),
          status: _asString(data['status'], 'ACTIVE'),
          unit: _asString(data['unit']),
        );
        await loadSensors();
        break;
      case 'thresholds':
        final index = thresholdProfiles.indexWhere((item) => item.id == id);
        if (index != -1) {
          thresholdProfiles[index] = thresholdProfiles[index].copyWith(
            name: data['name'] as String,
            description: data['description'] as String,
          );
        }
        break;
      case 'users':
        final index = users.indexWhere((item) => item.id == id);
        if (index != -1) {
          users[index] = users[index].copyWith(
            name: data['name'] as String,
            email: data['email'] as String,
            role: data['role'] as String,
          );
        }
        break;
      case 'alerts':
        await AlertsApi.updateAlert(
          id: id,
          sensorId: _asString(data['sensor_id'] ?? data['sensorId']),
          sensorParameterId: _asString(
            data['sensor_parameter_id'] ?? data['sensorParameterId'],
          ),
          alertLevel: _asString(data['alert_level'] ?? data['alertLevel']),
          message: _asString(data['message']),
          assignedTo:
              _asString(data['assigned_to'] ?? data['assignedTo'], 'engineer'),
        );
        await loadAlerts();
        break;
    }
    notifyListeners();
  }

  Future<void> delete(String view, String id) async {
    switch (view) {
      case 'organizations':
        organizations.removeWhere((item) => item.id == id);
        sites.removeWhere((s) => s.organizationId == id);
        break;
      case 'sites':
        sites.removeWhere((item) => item.id == id);
        zones.removeWhere((z) => z.siteId == id);
        break;
      case 'zones':
        zones.removeWhere((item) => item.id == id);
        devices.removeWhere((d) => d.zoneId == id);
        break;
      case 'devices':
        await DeviceApi.deleteDevice(id);
        await loadDevices();
        break;
      case 'sensors':
        await SensorApi.deleteSensor(id);
        await loadSensors();
        break;
      case 'alerts':
        await AlertsApi.deleteAlert(id);
        await loadAlerts();
        break;
      case 'thresholds':
        thresholdProfiles.removeWhere((item) => item.id == id);
        break;
      case 'users':
        users.removeWhere((item) => item.id == id);
        break;
      case 'audit':
        auditLogs.removeWhere((item) => item.id == id);
        break;
    }
    notifyListeners();
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
      case 'organizations':
        return organizations.length;
      case 'sites':
        return sites.length;
      case 'sensors':
        return sensors.length;
      case 'alerts':
        return getActiveAlerts().length;
      default:
        return 0;
    }
  }
}
