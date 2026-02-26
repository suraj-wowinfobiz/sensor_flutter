import 'dart:math';

import 'package:flutter/material.dart';

import '../api/device_api.dart';
import '../api/organization_api.dart' as org_api;
import '../api/sensor_api.dart';
import '../api/thresholds_api.dart';
import '../api/users_api.dart';
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
import '../shared/models/threshold_rule.dart';

class SuperAdminBackendProvider extends ChangeNotifier {
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

  SuperAdminBackendProvider() {
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

  void _initializeData() {
    organizations = [];
    sites = [];
    zones = [];

    devices = [];

    sensorTypes = const [
      SensorType(
        id: 'type_tilt',
        name: 'Tilt X/Y',
        category: 'inclinometer',
        description: 'Biaxial tilt sensor',
      ),
      SensorType(
        id: 'type_temp',
        name: 'Temperature',
        category: 'thermal',
        description: 'Temperature sensor',
      ),
    ];

    sensors = [];
    sensorParameters = [];
    thresholdProfiles = [];
    thresholdValues = [];
    users = [
      User(
        id: _uuid(),
        name: 'Admin User',
        role: 'admin',
        email: 'admin@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
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
      if (res.body == null) {
        organizations = [];
        notifyListeners();
        return;
      }
      organizations = (res.body as List).map((json) => Organization(
        id: json['organizationId'],
        name: json['name'],
        email: json['email'],
        status: json['status']?.toLowerCase() ?? 'active',
        ownerUserId: '',
        createdAt: DateTime.parse(json['createdAt']),
      )).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading organizations: $e');
      organizations = [];
      notifyListeners();
    }
  }

  Future<void> loadSites() async {
    try {
      final res = await org_api.OrgServiceApi.getAllSites();
      if (res.body == null) {
        sites = [];
        notifyListeners();
        return;
      }
      final mappedSites = <String, Site>{};
      for (final json in (res.body as List)) {
        final org = json['organization'];
        final site = Site(
          id: json['sitesID'],
          organizationId: org != null && org is Map ? org['organizationId'] : '',
          name: json['name'],
          location: json['location'],
          createdAt: DateTime.parse(json['createdAt']),
        );
        mappedSites[site.id] = site;
      }

      // Some backend responses from /site/ do not include organization relation.
      // Enrich missing organizationId by querying sites scoped per organization.
      final hasMissingOrganization = mappedSites.values.any(
        (s) => s.organizationId.trim().isEmpty,
      );
      if (hasMissingOrganization && organizations.isNotEmpty) {
        for (final org in organizations) {
          try {
            final orgSitesRes =
                await org_api.OrgServiceApi.getOrganizationSites(org.id);
            final body = orgSitesRes.body;
            if (body is! Map) continue;
            final rawSites = body['sites'];
            if (rawSites is! List) continue;
            for (final raw in rawSites) {
              if (raw is! Map) continue;
              final id = _asString(raw['sitesID']);
              if (id.isEmpty) continue;
              final existing = mappedSites[id];
              final createdAtRaw = raw['createdAt'];
              final createdAt = createdAtRaw is String
                  ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
                  : (existing?.createdAt ?? DateTime.now());
              mappedSites[id] = Site(
                id: id,
                organizationId: org.id,
                name: _asString(raw['name'], existing?.name ?? ''),
                location: _asString(raw['location'], existing?.location ?? ''),
                createdAt: createdAt,
              );
            }
          } catch (_) {
            // Ignore per-org enrichment failures and keep base list.
          }
        }
      }

      sites = mappedSites.values.toList();
      notifyListeners();
    } catch (e) {
      print('Error loading sites: $e');
      sites = [];
      notifyListeners();
    }
  }

  Future<void> loadZones(String siteId) async {
    try {
      final res = await org_api.OrgServiceApi.getZonesBySite(siteId);
      if (res.body == null) {
        zones.removeWhere((z) => z.siteId == siteId);
        notifyListeners();
        return;
      }
      final newZones = (res.body as List).map((json) {
        final site = json['site'];
        return Zone(
          id: json['zoneId'],
          siteId: site != null && site is Map ? site['sitesID'] : siteId,
          name: json['name'],
        );
      }).toList();
      zones.removeWhere((z) => z.siteId == siteId);
      zones.addAll(newZones);
      notifyListeners();
    } catch (e) {
      print('Error loading zones: $e');
    }
  }

  Future<void> loadUsers() async {
    try {
      final body = await UsersApi.getUsers();
      users = body.map((json) {
        return User(
          id: _asString(json['id'] ?? json['userId'], _uuid()),
          name: _asString(json['name'], 'User'),
          role: _asString(json['role'], 'operator').toLowerCase(),
          email: _asString(json['email']),
          createdAt: _asDate(json['createdAt'] ?? json['created_at']),
          updatedAt: _asDate(json['updatedAt'] ?? json['updated_at']),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading users: $e');
      users = [];
      notifyListeners();
    }
  }

  Future<void> loadDevices() async {
    try {
      final loadedDevices = <Device>[];
      for (final site in sites) {
        final body = await DeviceApi.getDevicesBySite(site.id);
        loadedDevices.addAll(body.map((json) {
          return Device(
            id: _asString(json['id'], _uuid()),
            siteId: _asString(json['siteId'] ?? json['site_id'], site.id),
            zoneId: _asString(json['zoneId'] ?? json['zone_id']),
            deviceCode: _asString(
              json['serialNumber'] ?? json['device_code'],
              'DEV-${_uuid().substring(0, 8)}',
            ),
            status: _asString(json['status'], 'active').toLowerCase(),
            installedAt: _asDate(
              json['lastHeartBeat'] ?? json['installed_at'] ?? json['createdAt'],
            ),
          );
        }));
      }
      final deduped = <String, Device>{};
      for (final device in loadedDevices) {
        deduped[device.id] = device;
      }
      devices = deduped.values.toList();
      notifyListeners();
    } catch (e) {
      print('Error loading devices: $e');
      devices = [];
      notifyListeners();
    }
  }

  Future<void> loadSensors() async {
    try {
      final loadedSensors = <Sensor>[];
      for (final device in devices) {
        final body = await SensorApi.getSensorsByDevice(device.id);
        loadedSensors.addAll(body.map((json) {
          return Sensor(
            id: _asString(json['sensorId'] ?? json['id'], _uuid()),
            deviceId: _asString(json['deviceId'] ?? json['device_id'], device.id),
            sensorTypeId:
                _asString(json['sensorTypeId'] ?? json['sensor_type_id']),
            serialNumber: _asString(
              json['name'] ?? json['serial_number'],
              'SEN-${_uuid().substring(0, 8)}',
            ),
            installedAt: _asDate(json['createdAt'] ?? json['installed_at']),
            lastReading: (json['last_reading'] as num?)?.toDouble() ?? 0,
          );
        }));
      }
      final deduped = <String, Sensor>{};
      for (final sensor in loadedSensors) {
        deduped[sensor.id] = sensor;
      }
      sensors = deduped.values.toList();
      notifyListeners();
    } catch (e) {
      print('Error loading sensors: $e');
      sensors = [];
      notifyListeners();
    }
  }

  Future<void> loadThresholdProfiles() async {
    try {
      final body = await ThresholdsApi.getProfiles();
      thresholdProfiles = body.map((json) {
        return ThresholdProfile(
          id: _asString(
            json['thresholdProfileId'] ?? json['id'],
            _uuid(),
          ),
          name: _asString(json['name'], 'Profile'),
          description: _asString(json['description']),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading threshold profiles: $e');
      thresholdProfiles = [];
      notifyListeners();
    }
  }

  Future<void> create(String view, Map<String, dynamic> data) async {
    switch (view) {
      case 'organizations':
        await org_api.OrgServiceApi.createOrganization(
          data['name'] as String,
          data['email'] as String,
        );
        await loadOrganizations();
        break;
      case 'sites':
        final organizationId = data['organization_id'] as String;
        await org_api.OrgServiceApi.createSiteForOrganization(
          organizationId,
          data['name'] as String,
          data['location'] as String,
        );
        await loadSites();
        break;
      case 'zones':
        final siteId = data['site_id'] as String;
        await org_api.OrgServiceApi.createZone(
          siteId,
          data['name'] as String,
        );
        await loadZones(siteId);
        break;
      case 'devices':
        await DeviceApi.createDevice(
          siteId: data['site_id'] as String,
          serialNumber: _asString(data['serial_number'] ?? data['device_code']),
          firmwareVersion: _asString(data['firmware_version'], '1.0.0'),
          status: _asString(data['status'], 'active').toUpperCase(),
        );
        await loadDevices();
        break;
      case 'sensors':
        await SensorApi.createSensor(
          deviceId: data['device_id'] as String,
          sensorTypeId: data['sensor_type_id'] as String,
          name: _asString(data['serial_number'], 'Sensor'),
          status: _asString(data['status'], 'ACTIVE'),
          unit: _asString(data['unit'], ''),
        );
        await loadSensors();
        break;
      case 'thresholds':
        await ThresholdsApi.createProfile(
          name: data['name'] as String,
          description: data['description'] as String,
        );
        await loadThresholdProfiles();
        break;
      case 'users':
        await UsersApi.createUser(
          name: data['name'] as String,
          email: data['email'] as String,
          role: _asString(data['role'], 'operator'),
          organizationId: _asString(
            data['organization_id'] ?? data['organizationId'],
            organizations.isNotEmpty ? organizations.first.id : '',
          ),
          password: _asString(data['password'], 'Temp@12345'),
        );
        await loadUsers();
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
        await org_api.OrgServiceApi.updateOrganization(
          id,
          data['name'] as String,
          data['email'] as String,
        );
        await loadOrganizations();
        break;
      case 'sites':
        await org_api.OrgServiceApi.updateSite(
          id,
          data['name'] as String,
          data['location'] as String,
          orgId: data['organization_id'] as String,
        );
        await loadSites();
        break;
      case 'zones':
        await org_api.OrgServiceApi.updateZone(
          id,
          data['name'] as String,
          siteId: data['site_id'] as String,
        );
        await loadZones(data['site_id'] as String);
        break;
      case 'devices':
        await DeviceApi.updateDevice(
          deviceId: id,
          siteId: data['site_id'] as String,
          serialNumber: _asString(data['serial_number'] ?? data['device_code']),
          firmwareVersion: _asString(data['firmware_version'], '1.0.0'),
          status: _asString(data['status'], 'active').toUpperCase(),
        );
        await loadDevices();
        break;
      case 'sensors':
        await SensorApi.updateSensor(
          sensorId: id,
          deviceId: data['device_id'] as String,
          sensorTypeId: data['sensor_type_id'] as String,
          name: _asString(data['serial_number'], 'Sensor'),
          status: _asString(data['status'], 'ACTIVE'),
          unit: _asString(data['unit'], ''),
        );
        await loadSensors();
        break;
      case 'thresholds':
        await ThresholdsApi.updateProfile(
          id: id,
          name: data['name'] as String,
          description: data['description'] as String,
        );
        await loadThresholdProfiles();
        break;
      case 'users':
        await UsersApi.updateUser(
          id: id,
          name: data['name'] as String,
          email: data['email'] as String,
          role: _asString(data['role'], 'operator'),
        );
        await loadUsers();
        break;
    }
    notifyListeners();
  }

  Future<void> delete(String view, String id) async {
    switch (view) {
      case 'organizations':
        await org_api.OrgServiceApi.deleteOrganization(id);
        await loadOrganizations();
        await loadSites();
        break;
      case 'sites':
        await org_api.OrgServiceApi.deleteSite(id);
        await loadSites();
        zones.removeWhere((z) => z.siteId == id);
        break;
      case 'zones':
        await org_api.OrgServiceApi.deleteZone(id);
        zones.removeWhere((item) => item.id == id);
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
        alerts.removeWhere((item) => item.id == id);
        break;
      case 'thresholds':
        await ThresholdsApi.deleteProfile(id);
        await loadThresholdProfiles();
        break;
      case 'users':
        await UsersApi.deleteUser(id);
        await loadUsers();
        break;
      case 'audit':
        auditLogs.removeWhere((item) => item.id == id);
        break;
    }
    notifyListeners();
  }

  void resolveAlert(String id) {
    final index = alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      alerts[index] = alerts[index].copyWith(resolvedAt: DateTime.now());
      notifyListeners();
    }
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
