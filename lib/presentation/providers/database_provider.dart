import 'package:flutter/material.dart';

import '../../data/datasources/local/database_provider.dart' as local;
import '../../data/models/alert_model.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/sensor_model.dart';
import '../../data/models/user_model.dart';

class DatabaseProvider extends ChangeNotifier {
  final local.LocalDatabaseProvider _db = local.LocalDatabaseProvider();

  List<OrganizationModel> _organizations = [];
  List<SensorModel> _sensors = [];
  List<AlertModel> _alerts = [];
  List<UserModel> _users = [];
  Map<String, dynamic> _config = {};

  List<OrganizationModel> get organizations => _organizations;
  List<SensorModel> get sensors => _sensors;
  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get activeAlerts =>
      _alerts.where((a) => !a.isResolved).toList();
  List<UserModel> get users => _users;
  Map<String, dynamic> get config => _config;

  DatabaseProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _organizations = await _db.getAllOrganizations();
    _sensors = await _db.getAllSensors();
    _alerts = await _db.getAllAlerts();
    _users = await _db.getAllUsers();
    _config = await _db.getConfig();
    notifyListeners();
  }

  Future<void> addOrganization(OrganizationModel organization) async {
    await _db.addOrganization(organization);
    await loadData();
  }

  Future<void> updateOrganization(OrganizationModel organization) async {
    await _db.updateOrganization(organization);
    await loadData();
  }

  Future<void> deleteOrganization(String id) async {
    await _db.deleteOrganization(id);
    await loadData();
  }

  Future<void> addSensor(SensorModel sensor) async {
    await _db.addSensor(sensor);
    await loadData();
  }

  Future<void> updateSensor(SensorModel sensor) async {
    await _db.updateSensor(sensor);
    await loadData();
  }

  Future<void> deleteSensor(String id) async {
    await _db.deleteSensor(id);
    await loadData();
  }

  Future<void> addAlert(AlertModel alert) async {
    await _db.addAlert(alert);
    await loadData();
  }

  Future<void> updateAlert(AlertModel alert) async {
    await _db.updateAlert(alert);
    await loadData();
  }

  Future<void> deleteAlert(String id) async {
    await _db.deleteAlert(id);
    await loadData();
  }

  Future<void> resolveAlert(String id) async {
    AlertModel? alert;
    for (final item in _alerts) {
      if (item.id == id) {
        alert = item;
        break;
      }
    }
    if (alert == null) {
      return;
    }
    await _db.updateAlert(alert.copyWith(resolvedAt: DateTime.now()));
    await loadData();
  }

  Future<void> addUser(UserModel user) async {
    await _db.addUser(user);
    await loadData();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.updateUser(user);
    await loadData();
  }

  Future<void> deleteUser(String id) async {
    await _db.deleteUser(id);
    await loadData();
  }

  Future<void> updateConfig(Map<String, dynamic> config) async {
    await _db.updateConfig(config);
    await loadData();
  }
}
