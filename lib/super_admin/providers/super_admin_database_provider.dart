import 'dart:math';

import 'package:flutter/material.dart';

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

class DatabaseProvider extends ChangeNotifier {
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

  DatabaseProvider() {
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

  void _initializeData() {
    organizations = [
      Organization(
        id: _uuid(),
        name: 'Smart Building Solutions',
        email: 'contact@sbs.com',
        status: 'active',
        ownerUserId: _uuid(),
        createdAt: DateTime.now(),
      ),
      Organization(
        id: _uuid(),
        name: 'Industrial Monitoring Inc',
        email: 'info@imi.com',
        status: 'active',
        ownerUserId: _uuid(),
        createdAt: DateTime.now(),
      ),
      Organization(
        id: _uuid(),
        name: 'Environmental Systems Ltd',
        email: 'admin@ensys.com',
        status: 'inactive',
        ownerUserId: _uuid(),
        createdAt: DateTime.now(),
      ),
    ];

    sites = [
      Site(
        id: _uuid(),
        organizationId: organizations[0].id,
        name: 'HQ Building (NYC)',
        location: 'New York',
        createdAt: DateTime.now(),
      ),
      Site(
        id: _uuid(),
        organizationId: organizations[0].id,
        name: 'R&D Center (Boston)',
        location: 'Boston',
        createdAt: DateTime.now(),
      ),
      Site(
        id: _uuid(),
        organizationId: organizations[1].id,
        name: 'Factory A (Detroit)',
        location: 'Detroit',
        createdAt: DateTime.now(),
      ),
    ];

    zones = [
      Zone(id: _uuid(), siteId: sites[0].id, name: 'Zone A - Structural'),
      Zone(id: _uuid(), siteId: sites[0].id, name: 'Zone B - HVAC'),
      Zone(id: _uuid(), siteId: sites[1].id, name: 'Lab Zone 1'),
      Zone(id: _uuid(), siteId: sites[2].id, name: 'Assembly Zone'),
    ];

    devices = [
      Device(
        id: _uuid(),
        siteId: sites[0].id,
        zoneId: zones[0].id,
        deviceCode: 'GATEWAY-001',
        status: 'active',
        installedAt: DateTime.now(),
      ),
      Device(
        id: _uuid(),
        siteId: sites[0].id,
        zoneId: zones[1].id,
        deviceCode: 'GATEWAY-002',
        status: 'active',
        installedAt: DateTime.now(),
      ),
      Device(
        id: _uuid(),
        siteId: sites[1].id,
        zoneId: zones[2].id,
        deviceCode: 'GATEWAY-003',
        status: 'maintenance',
        installedAt: DateTime.now(),
      ),
    ];

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
    for (int i = 1; i <= 12; i++) {
      sensors.add(
        Sensor(
          id: _uuid(),
          deviceId: devices[i % 3].id,
          sensorTypeId: sensorTypes[0].id,
          serialNumber: 'TILT-2024-${1000 + i}',
          installedAt: DateTime.now(),
          lastReading: Random().nextDouble() * 5,
        ),
      );
    }

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

    users = [
      User(
        id: _uuid(),
        name: 'Sarah Connor',
        role: 'operator',
        email: 'sarah@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      User(
        id: _uuid(),
        name: 'Mike Ryan',
        role: 'engineer',
        email: 'mike@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      User(
        id: _uuid(),
        name: 'Admin User',
        role: 'admin',
        email: 'admin@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    alerts = [
      Alert(
        id: _uuid(),
        sensorId: sensors[0].id,
        sensorParameterId: sensorParameters[0].id,
        alertLevel: 'warning',
        message: 'Tilt above warning threshold',
        triggeredAt: DateTime.now(),
      ),
      Alert(
        id: _uuid(),
        sensorId: sensors[2].id,
        sensorParameterId: sensorParameters[0].id,
        alertLevel: 'critical',
        message: 'Critical tilt detected',
        triggeredAt: DateTime.now(),
      ),
      Alert(
        id: _uuid(),
        sensorId: sensors[5].id,
        sensorParameterId: sensorParameters[0].id,
        alertLevel: 'warning',
        message: 'Unstable readings',
        triggeredAt: DateTime.now().subtract(const Duration(hours: 1)),
        resolvedAt: DateTime.now(),
      ),
    ];

    auditLogs = [];
    for (int i = 1; i <= 10; i++) {
      auditLogs.add(
        AuditLog(
          id: _uuid(),
          userId: users[i % 3].id,
          action: ['CREATE', 'UPDATE', 'DELETE', 'LOGIN'][i % 4],
          resource: ['Organization', 'Site', 'Sensor', 'User'][i % 4],
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          ip: '192.168.1.${100 + i}',
        ),
      );
    }

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

  void create(String view, Map<String, dynamic> data) {
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
    }
    notifyListeners();
  }

  void update(String view, String id, Map<String, dynamic> data) {
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
        final index = users.indexWhere((item) => item.id == id);
        if (index != -1) {
          users[index] = users[index].copyWith(
            name: data['name'] as String,
            email: data['email'] as String,
            role: data['role'] as String,
          );
        }
        break;
    }
    notifyListeners();
  }

  void delete(String view, String id) {
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
        users.removeWhere((item) => item.id == id);
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
