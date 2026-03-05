import 'dart:math';

import 'package:flutter/material.dart';

import '../../super_admin/api/organization_api.dart' as org_api;
import '../../super_admin/api/users_api.dart';
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

class UserAdminDatabaseProvider extends ChangeNotifier {
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

  UserAdminDatabaseProvider() {
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

    sensorParameters = [
      SensorParameter(
        id: _uuid(),
        sensorTypeId: sensorTypes[0].id,
        name: 'tilt_x',
        unit: 'degrees',
        minValue: -15,
        maxValue: 15,
      ),
      SensorParameter(
        id: _uuid(),
        sensorTypeId: sensorTypes[0].id,
        name: 'tilt_y',
        unit: 'degrees',
        minValue: -15,
        maxValue: 15,
      ),
    ];

    thresholdProfiles = [
      ThresholdProfile(
        id: _uuid(),
        name: 'Standard Tilt',
        description: 'Default tilt thresholds',
      ),
      ThresholdProfile(
        id: _uuid(),
        name: 'High Sensitivity',
        description: 'Stricter thresholds',
      ),
    ];

    thresholdValues = [
      ThresholdValue(
        id: _uuid(),
        sensorParameterId: sensorParameters[0].id,
        thresholdProfileId: thresholdProfiles[0].id,
        minThreshold: -4,
        maxThreshold: 4,
        warningLevel: 2.5,
        criticalLevel: 4.0,
      ),
    ];

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
    final res = await org_api.OrgServiceApi.getAllOrganizations();
    final body = res.body;
    if (body is! List) {
      organizations = [];
      notifyListeners();
      return;
    }

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
    notifyListeners();
  }

  Future<void> loadSites() async {
    final res = await org_api.OrgServiceApi.getAllSites();
    final body = res.body;
    if (body is! List) {
      sites = [];
      notifyListeners();
      return;
    }

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

    final hasMissingOrganization = mappedSites.values.any(
      (s) => s.organizationId.trim().isEmpty,
    );
    if (hasMissingOrganization && organizations.isNotEmpty) {
      for (final org in organizations) {
        try {
          final orgSitesRes =
              await org_api.OrgServiceApi.getOrganizationSites(org.id);
          final orgBody = orgSitesRes.body;
          if (orgBody is! Map) continue;
          final rawSites = orgBody['sites'];
          if (rawSites is! List) continue;
          for (final raw in rawSites) {
            if (raw is! Map) continue;
            final id = _asString(raw['sitesID']);
            if (id.isEmpty) continue;
            final existing = mappedSites[id];
            mappedSites[id] = Site(
              id: id,
              organizationId: org.id,
              name: _asString(raw['name'], existing?.name ?? ''),
              location: _asString(raw['location'], existing?.location ?? ''),
              createdAt: _asDate(raw['createdAt'] ?? existing?.createdAt),
            );
          }
        } catch (_) {
          // Keep base site list when enrichment endpoint fails for one org.
        }
      }
    }

    sites = mappedSites.values.toList();
    notifyListeners();
  }

  Future<void> loadZones(String siteId) async {
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
    notifyListeners();
  }

  Future<void> loadUsers() async {
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
  }

  Future<void> createOrganization({
    required String name,
    required String email,
  }) async {
    await org_api.OrgServiceApi.createOrganization(name, email);
    await loadOrganizations();
  }

  Future<void> updateOrganization({
    required String organizationId,
    required String name,
    required String email,
  }) async {
    await org_api.OrgServiceApi.updateOrganization(organizationId, name, email);
    await loadOrganizations();
  }

  Future<void> deleteOrganization(String organizationId) async {
    await org_api.OrgServiceApi.deleteOrganization(organizationId);
    await loadOrganizations();
    await loadSites();
  }

  Future<void> createSite({
    required String organizationId,
    required String name,
    required String location,
  }) async {
    await org_api.OrgServiceApi.createSiteForOrganization(
      organizationId,
      name,
      location,
    );
    await loadSites();
  }

  Future<void> updateSite({
    required String siteId,
    required String organizationId,
    required String name,
    required String location,
  }) async {
    await org_api.OrgServiceApi.updateSite(
      siteId,
      name,
      location,
      orgId: organizationId,
    );
    await loadSites();
  }

  Future<void> deleteSite(String siteId) async {
    await org_api.OrgServiceApi.deleteSite(siteId);
    await loadSites();
    zones.removeWhere((z) => z.siteId == siteId);
    notifyListeners();
  }

  Future<void> createZone({
    required String siteId,
    required String name,
  }) async {
    await org_api.OrgServiceApi.createZone(siteId, name);
    await loadZones(siteId);
  }

  Future<void> updateZone({
    required String zoneId,
    required String siteId,
    required String name,
  }) async {
    await org_api.OrgServiceApi.updateZone(zoneId, name, siteId: siteId);
    await loadZones(siteId);
  }

  Future<void> deleteZone(String zoneId) async {
    await org_api.OrgServiceApi.deleteZone(zoneId);
    zones.removeWhere((z) => z.id == zoneId);
    devices.removeWhere((d) => d.zoneId == zoneId);
    notifyListeners();
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
        await org_api.OrgServiceApi.createSiteForOrganization(
          data['organization_id'] as String,
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
        devices.add(Device(
          id: _uuid(),
          deviceCode: data['device_code'] as String,
          siteId: data['site_id'] as String,
          zoneId: data['zone_id'] as String,
          status: data['status'] as String,
          installedAt: DateTime.now(),
        ));
        break;
      case 'sensors':
        sensors.add(Sensor(
          id: _uuid(),
          serialNumber: data['serial_number'] as String,
          deviceId: data['device_id'] as String,
          sensorTypeId: data['sensor_type_id'] as String,
          installedAt: DateTime.now(),
          lastReading: 0,
        ));
        break;
      case 'thresholds':
        thresholdProfiles.add(ThresholdProfile(
          id: _uuid(),
          name: data['name'] as String,
          description: data['description'] as String,
        ));
        break;
      case 'users':
        await UsersApi.createUser(
          name: data['name'] as String,
          email: data['email'] as String,
          role: _asString(data['role'], 'operator'),
          organizationId: data['organization_id'] as String,
          password: _asString(data['password'], 'Temp@12345'),
          maxUsersAllowed: data['maxUsersAllowed'] as int?,
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
        final index = devices.indexWhere((item) => item.id == id);
        if (index != -1) {
          devices[index] = devices[index].copyWith(
            deviceCode: data['device_code'] as String,
            siteId: data['site_id'] as String,
            zoneId: data['zone_id'] as String,
            status: data['status'] as String,
          );
        }
        break;
      case 'sensors':
        final index = sensors.indexWhere((item) => item.id == id);
        if (index != -1) {
          sensors[index] = sensors[index].copyWith(
            serialNumber: data['serial_number'] as String,
            deviceId: data['device_id'] as String,
            sensorTypeId: data['sensor_type_id'] as String,
          );
        }
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
        devices.removeWhere((d) => d.zoneId == id);
        break;
      case 'devices':
        devices.removeWhere((item) => item.id == id);
        break;
      case 'sensors':
        sensors.removeWhere((item) => item.id == id);
        break;
      case 'alerts':
        alerts.removeWhere((item) => item.id == id);
        break;
      case 'thresholds':
        thresholdProfiles.removeWhere((item) => item.id == id);
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
