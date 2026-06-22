import '../../data/models/alert_model.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/sensor_model.dart';
import '../../data/models/user_model.dart';

abstract class DatabaseRepository {
  Future<List<OrganizationModel>> getOrganizations();
  Future<OrganizationModel?> getOrganization(String id);
  Future<void> addOrganization(OrganizationModel organization);
  Future<void> updateOrganization(OrganizationModel organization);
  Future<void> deleteOrganization(String id);

  Future<List<SensorModel>> getSensors();
  Future<SensorModel?> getSensor(String id);
  Future<void> addSensor(SensorModel sensor);
  Future<void> updateSensor(SensorModel sensor);
  Future<void> deleteSensor(String id);

  Future<List<AlertModel>> getAlerts();
  Future<List<AlertModel>> getActiveAlerts();
  Future<void> addAlert(AlertModel alert);
  Future<void> updateAlert(AlertModel alert);
  Future<void> deleteAlert(String id);
  Future<void> resolveAlert(String id);

  Future<List<UserModel>> getUsers();
  Future<void> addUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String id);

  Future<Map<String, dynamic>> getConfig();
  Future<void> updateConfig(Map<String, dynamic> config);
}
