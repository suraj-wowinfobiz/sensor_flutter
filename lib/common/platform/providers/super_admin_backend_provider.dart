import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../api/device_api.dart';
import '../api/organization_api.dart' as org_api;
import '../api/sensor_api.dart';
import '../api/sensor_parameter_api.dart';
import '../api/sensor_type_api.dart';
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
  Future<void>? _loadOrganizationsTask;
  Future<void>? _loadSitesTask;
  Future<void>? _loadDevicesTask;
  Future<void>? _loadSensorsTask;
  int _thresholdRuleSeed = 4;
  final List<ThresholdRule> _thresholdRules = [];

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

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> _devicePayloadFrom(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {
        // Ignore malformed JSON string and fallback to empty map.
      }
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  Site? _siteFromPayload(
    dynamic raw, {
    String fallbackOrganizationId = '',
  }) {
    final json = _asMap(raw);
    if (json.isEmpty) return null;

    final id = _asString(json['sitesID'] ?? json['siteId'] ?? json['id']);
    if (id.isEmpty) return null;

    final organization = _asMap(json['organization']);
    final organizationId = _asString(
      json['organizationId'] ??
          json['organization_id'] ??
          organization['organizationId'] ??
          organization['id'],
      fallbackOrganizationId,
    );

    return Site(
      id: id,
      organizationId: organizationId,
      name: _asString(json['name']),
      location: _asString(json['location'], 'N/A'),
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
    );
  }

  void _upsertSite(Site site) {
    final index = sites.indexWhere((item) => item.id == site.id);
    if (index >= 0) {
      sites[index] = site;
      return;
    }
    sites = [...sites, site];
  }

  void _refreshSitesSoon() {
    unawaited(() async {
      try {
        await loadSites();
      } catch (e) {
        print('Error refreshing sites: $e');
      }
    }());
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
    if (_loadOrganizationsTask != null) return _loadOrganizationsTask!;
    final task = () async {
      try {
        final res = await org_api.OrgServiceApi.getAllOrganizations();
        if (res.body == null) {
          organizations = [];
          return;
        }
        organizations = (res.body as List)
            .map((json) => Organization(
                  id: json['organizationId'],
                  name: json['name'],
                  email: json['email'],
                  status: json['status']?.toLowerCase() ?? 'active',
                  ownerUserId: '',
                  createdAt: DateTime.parse(json['createdAt']),
                ))
            .toList();
      } catch (e) {
        print('Error loading organizations: $e');
        organizations = [];
      }
    }();
    _loadOrganizationsTask = task;
    try {
      await task;
    } finally {
      _loadOrganizationsTask = null;
    }
    notifyListeners();
  }

  Future<void> loadSites() async {
    if (_loadSitesTask != null) return _loadSitesTask!;
    final task = () async {
      try {
        if (organizations.isEmpty) {
          sites = [];
          return;
        }

        final mappedSites = <String, Site>{};

        for (final org in organizations) {
          try {
            final orgSitesRes =
                await org_api.OrgServiceApi.getOrganizationSites(
              org.id,
            );
            final body = _asMap(orgSitesRes.body);
            final rawSites = body['sites'];
            if (rawSites is! List) continue;

            for (final raw in rawSites) {
              final site = _siteFromPayload(
                raw,
                fallbackOrganizationId: org.id,
              );
              if (site == null) continue;
              mappedSites[site.id] = site;
            }
          } catch (_) {
            // Keep loading other organizations even if one scoped call fails.
          }
        }

        sites = mappedSites.values.toList();
      } catch (e) {
        print('Error loading sites: $e');
        sites = [];
      }
    }();
    _loadSitesTask = task;
    try {
      await task;
    } finally {
      _loadSitesTask = null;
    }
    notifyListeners();
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
    } catch (e) {
      print('Error loading zones: $e');
    }
    notifyListeners();
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
    } catch (e) {
      print('Error loading users: $e');
      users = [];
    }
    notifyListeners();
  }

  Future<void> loadDevices() async {
    if (_loadDevicesTask != null) return _loadDevicesTask!;
    final task = () async {
      try {
        final body = await DeviceApi.getAllDevices();
        final loadedDevices = body.map((json) {
          // Backend returns {data: {...}, id: ..., organizationId: ...}
          // Also handles `data` as JSON string.
          final nested = _devicePayloadFrom(json['data']);
          final data = nested.isNotEmpty ? nested : json;
          final rawSite = data['site'];
          final rawZone = data['zone'];
          final resolvedSiteId = _asString(
            data['siteId'] ?? data['site_id'] ?? data['sitesID'],
            rawSite is Map ? _asString(rawSite['sitesID']) : '',
          );
          final resolvedZoneId = _asString(
            data['zoneId'] ?? data['zone_id'],
            rawZone is Map ? _asString(rawZone['zoneId']) : '',
          );
          return Device(
            id: _asString(
                data['id'] ?? data['deviceId'] ?? json['id'], _uuid()),
            siteId: resolvedSiteId,
            zoneId: resolvedZoneId,
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
            numberOfChannels: int.tryParse(_asString(
                    data['numberOfChannels'] ?? data['number_of_channels'],
                    '0')) ??
                0,
            webHookUrl: _asString(data['webHookUrl'] ?? data['web_hook_url']),
            lat: double.tryParse(_asString(data['lat'], '0')) ?? 0.0,
            log: double.tryParse(_asString(data['log'], '0')) ?? 0.0,
            lastHeartBeat:
                _asString(data['lastHeartBeat'] ?? data['last_heart_beat']),
          );
        }).toList();
        final deduped = <String, Device>{};
        for (final device in loadedDevices) {
          deduped[device.id] = device;
        }
        devices = deduped.values.toList();
      } catch (e) {
        print('Error loading devices: $e');
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
        final loadedSensors = body.map((json) {
          final rawType = json['sensorType'];
          return Sensor(
            id: _asString(json['sensorId'] ?? json['id'], _uuid()),
            deviceId: _asString(json['deviceId'] ?? json['device_id']),
            sensorTypeId: _asString(
              json['sensorTypeId'] ??
                  json['sensor_type_id'] ??
                  (rawType is Map ? rawType['sensorTypeId'] : null),
            ),
            serialNumber: _asString(
              json['name'] ?? json['serial_number'],
              'SEN-${_uuid().substring(0, 8)}',
            ),
            installedAt: _asDate(json['createdAt'] ?? json['installed_at']),
            lastReading: (json['last_reading'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        final deduped = <String, Sensor>{};
        for (final sensor in loadedSensors) {
          deduped[sensor.id] = sensor;
        }
        sensors = deduped.values.toList();
      } catch (e) {
        print('Error loading sensors: $e');
        sensors = [];
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
    } catch (e) {
      print('Error loading sensor types: $e');
      sensorTypes = [];
    }
    notifyListeners();
  }

  Future<void> loadSensorParameters() async {
    try {
      final body = await SensorParameterApi.getAllSensorParameters();
      final loaded = body
          .map((json) => SensorParameter.fromJson(json))
          .where((item) => item.id.trim().isNotEmpty)
          .toList();
      final deduped = <String, SensorParameter>{};
      for (final item in loaded) {
        deduped[item.id] = item;
      }
      sensorParameters = deduped.values.toList();
    } catch (e) {
      print('Error loading sensor parameters: $e');
      sensorParameters = [];
    }
    notifyListeners();
  }

  Future<void> loadThresholdProfiles() async {
    try {
      final body = await ThresholdsApi.getProfiles().timeout(
        const Duration(seconds: 6),
        onTimeout: () => const <Map<String, dynamic>>[],
      );
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
    } catch (e) {
      print('Error loading threshold profiles: $e');
      thresholdProfiles = [];
    }
    notifyListeners();
  }

  Future<void> loadThresholdValues() async {
    try {
      final body = await ThresholdsApi.getThresholds().timeout(
        const Duration(seconds: 6),
        onTimeout: () => const <Map<String, dynamic>>[],
      );
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
          minThreshold: _asDouble(
            json['minThresholdValue'] ?? json['min_threshold'],
          ),
          maxThreshold: _asDouble(
            json['maxThresholdValue'] ?? json['max_threshold'],
          ),
          warningLevel: _asDouble(
            json['warningLevel'] ??
                json['warrningLevel'] ??
                json['warning_level'],
          ),
          criticalLevel: _asDouble(
            json['criticalLevel'] ?? json['critical_level'],
          ),
        );
      }).toList();
    } catch (e) {
      print('Error loading threshold values: $e');
      thresholdValues = [];
    }
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
        final organizationId = data['organization_id'] as String;
        final res = await org_api.OrgServiceApi.createSiteForOrganization(
          organizationId,
          data['name'] as String,
          data['location'] as String,
        );
        final createdSite = _siteFromPayload(
          res.body,
          fallbackOrganizationId: organizationId,
        );
        if (createdSite != null) {
          _upsertSite(createdSite);
        }
        notifyListeners();
        _refreshSitesSoon();
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
        final siteId = data['site_id'] as String;
        final site = sites.where((s) => s.id == siteId).firstOrNull;
        await DeviceApi.createDevice(
          deviceId: '',
          organizationId:
              _asString(data['organization_id'], site?.organizationId ?? ''),
          siteId: siteId,
          zoneId: _asString(data['zone_id']),
          serialNumber: _asString(data['serial_number']),
          firmwareVersion: _asString(data['firmware_version']),
          macAddress: _asString(data['mac_address']),
          ipAddress: _asString(data['ip_address']),
          numberOfChannels:
              int.tryParse(_asString(data['number_of_channels'])) ?? 0,
          webHookUrl: _asString(data['web_hook_url']),
          lat: double.tryParse(_asString(data['lat'])) ?? 0,
          log: double.tryParse(_asString(data['log'])) ?? 0,
          lastHeartBeat: _asString(data['last_heart_beat']),
          status: _asString(data['status'], 'active'),
        );
        await loadDevices();
        break;
      case 'sensors':
        final sensorId = _asString(data['sensor_id'] ?? data['sensorId']);
        final sensorParameterId =
            _asString(data['sensor_parameter_id'] ?? data['sensorParameterId']);
        await SensorApi.createSensor(
          sensorId: sensorId.isEmpty ? null : sensorId,
          deviceId: data['device_id'] as String,
          sensorTypeId: data['sensor_type_id'] as String,
          sensorParameterId:
              sensorParameterId.isEmpty ? null : sensorParameterId,
          name: _asString(data['name'] ?? data['serial_number'], 'Sensor'),
          serialNumber: _asString(data['serial_number']),
          macAddress: _asString(data['mac_address']),
          channelNumber: int.tryParse(_asString(data['channel_number'])),
          lat: double.tryParse(_asString(data['lat'])),
          log: double.tryParse(_asString(data['log'])),
          status: _asString(data['status'], 'ACTIVE'),
          unit: _asString(data['unit'], ''),
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
      case 'sensor_parameters':
        final typeId =
            _asString(data['sensorTypeId'] ?? data['sensor_type_id']);
        if (typeId.isEmpty) {
          throw ArgumentError('sensorTypeId is required to create parameter');
        }
        await SensorParameterApi.createSensorParameter(
          sensorTypeId: typeId,
          name: _asString(data['name'], 'Parameter'),
          unit: _asString(data['unit']),
          minValue: _asDouble(data['minValue'] ?? data['min_value']),
          maxValue: _asDouble(data['maxValue'] ?? data['max_value']),
        );
        await loadSensorParameters();
        break;
      case 'thresholds':
        await ThresholdsApi.createProfile(
          name: data['name'] as String,
          description: data['description'] as String,
        );
        await loadThresholdProfiles();
        break;
      case 'threshold_values':
        await ThresholdsApi.createThreshold(
          minThresholdValue: _asDouble(data['minThresholdValue']),
          sensorParameterId: _asString(
            data['sensorParameterId'] ?? data['sensorParamterId'],
          ),
          thresholdProfileId: _asString(data['thresholdProfileId']),
          maxThresholdValue: _asDouble(data['maxThresholdValue']),
          warningLevel:
              _asDouble(data['warningLevel'] ?? data['warrningLevel']),
          criticalLevel: _asDouble(data['criticalLevel']),
          warrningLevel: _asDouble(data['warrningLevel']),
          sensorParamterId: _asString(data['sensorParamterId']),
        );
        await loadThresholdValues();
        break;
      case 'users':
        final rawRole = _asString(data['role'], 'admin');
        final role = rawRole.toLowerCase();
        final organizationId =
            _asString(data['organization_id'] ?? data['organizationId']);
        final name = data['name'] as String;
        final email = data['email'] as String;
        final password = _asString(data['password'], 'Temp@12345');
        final maxUsersAllowed = int.tryParse(
          _asString(data['maxUsersAllowed'] ?? data['max_users_allowed'], '20'),
        );

        if (organizationId.isEmpty) {
          throw ArgumentError('organization_id is required to create user');
        }

        if (role == 'admin') {
          await UsersApi.createAdminUser(
            name: name,
            email: email,
            organizationId: organizationId,
            password: password,
            maxUsersAllowed: maxUsersAllowed,
          );
        } else if (role == 'engineer' ||
            role == 'user' ||
            role == 'vendor_engineer') {
          final createRole = role == 'user' ? 'user' : 'vendor_engineer';
          await UsersApi.createUser(
            name: name,
            email: email,
            role: createRole,
            organizationId: organizationId,
            password: password,
            maxUsersAllowed: maxUsersAllowed,
          );
        } else if (role == 'vendor') {
          await UsersApi.createVendor(
            name: name,
            email: email,
            organizationId: organizationId,
            password: password,
            maxUsersAllowed: maxUsersAllowed,
          );
        } else {
          throw ArgumentError('Unsupported user role: $role');
        }
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
        notifyListeners();
        break;
    }
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
        final existingSite = sites.where((item) => item.id == id).firstOrNull;
        if (existingSite != null) {
          _upsertSite(
            existingSite.copyWith(
              name: data['name'] as String,
              location: data['location'] as String,
              organizationId: data['organization_id'] as String,
            ),
          );
        }
        notifyListeners();
        _refreshSitesSoon();
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
        final siteId = data['site_id'] as String;
        final site = sites.where((s) => s.id == siteId).firstOrNull;
        await DeviceApi.updateDevice(
          deviceId: id,
          organizationId:
              _asString(data['organization_id'], site?.organizationId ?? ''),
          siteId: siteId,
          zoneId: _asString(data['zone_id']),
          serialNumber: _asString(data['serial_number'] ?? data['device_code']),
          firmwareVersion: _asString(data['firmware_version'], '1.0.0'),
          macAddress: _asString(data['mac_address']),
          ipAddress: _asString(data['ip_address']),
          numberOfChannels:
              int.tryParse(_asString(data['number_of_channels'], '0')) ?? 0,
          webHookUrl: _asString(data['web_hook_url']),
          lat: double.tryParse(_asString(data['lat'], '0')) ?? 0,
          log: double.tryParse(_asString(data['log'], '0')) ?? 0,
          lastHeartBeat: _asString(
              data['last_heart_beat'], DateTime.now().toIso8601String()),
          status: _asString(data['status'], 'active'),
        );
        await loadDevices();
        break;
      case 'sensors':
        final sensorParameterId =
            _asString(data['sensor_parameter_id'] ?? data['sensorParameterId']);
        await SensorApi.updateSensor(
          sensorId: id,
          deviceId: data['device_id'] as String,
          sensorTypeId: data['sensor_type_id'] as String,
          sensorParameterId:
              sensorParameterId.isEmpty ? null : sensorParameterId,
          name: _asString(data['name'] ?? data['serial_number'], 'Sensor'),
          serialNumber: _asString(data['serial_number']),
          macAddress: _asString(data['mac_address']),
          channelNumber: int.tryParse(_asString(data['channel_number'])),
          lat: double.tryParse(_asString(data['lat'])),
          log: double.tryParse(_asString(data['log'])),
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
      case 'sensor_parameters':
        final typeId =
            _asString(data['sensorTypeId'] ?? data['sensor_type_id']);
        if (typeId.isEmpty) {
          throw ArgumentError('sensorTypeId is required to update parameter');
        }
        await SensorParameterApi.updateSensorParameter(
          sensorTypeId: typeId,
          sensorParameterId:
              _asString(data['sensorParameterId'] ?? data['id'], id),
          name: _asString(data['name'], 'Parameter'),
          unit: _asString(data['unit']),
          minValue: _asDouble(data['minValue'] ?? data['min_value']),
          maxValue: _asDouble(data['maxValue'] ?? data['max_value']),
        );
        await loadSensorParameters();
        break;
      case 'users':
        final existingRole = users
            .where((item) => item.id == id)
            .map((item) => item.role)
            .firstOrNull;
        await UsersApi.updateUser(
          id: id,
          name: data['name'] as String,
          email: data['email'] as String,
          role: _asString(data['role'], existingRole ?? 'user'),
          password: _asString(data['password']),
        );
        await loadUsers();
        break;
    }
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
        sites.removeWhere((item) => item.id == id);
        zones.removeWhere((z) => z.siteId == id);
        notifyListeners();
        _refreshSitesSoon();
        break;
      case 'zones':
        await org_api.OrgServiceApi.deleteZone(id);
        zones.removeWhere((item) => item.id == id);
        notifyListeners();
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
        notifyListeners();
        break;
      case 'thresholds':
        await ThresholdsApi.deleteProfile(id);
        await loadThresholdProfiles();
        break;
      case 'threshold_values':
        await ThresholdsApi.deleteThresholdValue(id);
        await loadThresholdValues();
        break;
      case 'users':
        final existingRole = users
            .where((item) => item.id == id)
            .map((item) => item.role)
            .firstOrNull;
        await UsersApi.deleteUser(id, role: existingRole);
        await loadUsers();
        break;
      case 'audit':
        auditLogs.removeWhere((item) => item.id == id);
        notifyListeners();
        break;
    }
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
