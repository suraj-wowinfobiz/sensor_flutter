import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/alert_model.dart';
import '../../models/organization_model.dart';
import '../../models/sensor_model.dart';
import '../../models/user_model.dart';

class LocalDatabaseProvider {
  static const String _organizationsKey = 'organizations';
  static const String _sensorsKey = 'sensors';
  static const String _alertsKey = 'alerts';
  static const String _usersKey = 'users';
  static const String _configKey = 'config';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_configKey)) {
      await prefs.setString(
        _configKey,
        jsonEncode({
          'global_threshold': 3.0,
          'warning_threshold': 2.6,
          'critical_threshold': 4.2,
          'retention_days': 90,
          'backup_enabled': true,
          'backup_frequency': 'daily',
          'alert_notification': true,
          'api_rate_limit': 100,
        }),
      );
    }
  }

  Future<List<OrganizationModel>> getAllOrganizations() async {
    final list = await _getList(_organizationsKey);
    return list.map(OrganizationModel.fromJson).toList();
  }

  Future<List<SensorModel>> getAllSensors() async {
    final list = await _getList(_sensorsKey);
    return list.map(SensorModel.fromJson).toList();
  }

  Future<List<AlertModel>> getAllAlerts() async {
    final list = await _getList(_alertsKey);
    return list.map(AlertModel.fromJson).toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    final list = await _getList(_usersKey);
    return list.map(UserModel.fromJson).toList();
  }

  Future<Map<String, dynamic>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null || raw.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> updateConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config));
  }

  Future<void> addOrganization(OrganizationModel org) =>
      _upsert(_organizationsKey, org.id, org.toJson());
  Future<void> updateOrganization(OrganizationModel org) =>
      _upsert(_organizationsKey, org.id, org.toJson());
  Future<void> deleteOrganization(String id) => _delete(_organizationsKey, id);

  Future<void> addSensor(SensorModel sensor) =>
      _upsert(_sensorsKey, sensor.id, sensor.toJson());
  Future<void> updateSensor(SensorModel sensor) =>
      _upsert(_sensorsKey, sensor.id, sensor.toJson());
  Future<void> deleteSensor(String id) => _delete(_sensorsKey, id);

  Future<void> addAlert(AlertModel alert) =>
      _upsert(_alertsKey, alert.id, alert.toJson());
  Future<void> updateAlert(AlertModel alert) =>
      _upsert(_alertsKey, alert.id, alert.toJson());
  Future<void> deleteAlert(String id) => _delete(_alertsKey, id);

  Future<void> addUser(UserModel user) =>
      _upsert(_usersKey, user.id, user.toJson());
  Future<void> updateUser(UserModel user) =>
      _upsert(_usersKey, user.id, user.toJson());
  Future<void> deleteUser(String id) => _delete(_usersKey, id);

  Future<void> _upsert(
      String key, String id, Map<String, dynamic> value) async {
    final items = await _getList(key);
    final updated = items.where((e) => e['id'] != id).toList()..add(value);
    await _setList(key, updated);
  }

  Future<void> _delete(String key, String id) async {
    final items = await _getList(key);
    await _setList(key, items.where((e) => e['id'] != id).toList());
  }

  Future<List<Map<String, dynamic>>> _getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _setList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}
