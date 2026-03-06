import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../models/sensor.dart';
import 'engineer_database_provider.dart';

final engineerDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<EngineerDatabaseProvider>(
  (ref) => EngineerDatabaseProvider(),
);

final engineerCurrentViewStateProvider =
    StateProvider<String>((ref) => 'dashboard');

final engineerIsLoadingStateProvider = StateProvider<bool>((ref) => false);

final engineerSelectedDeviceIdStateProvider =
    StateProvider<String?>((ref) => null);

final engineerSelectedSensorIdStateProvider =
    StateProvider<String?>((ref) => null);

final engineerLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final engineerLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);

final devicesProvider = FutureProvider.autoDispose.family<List<Device>, int>((
  ref,
  _,
) async {
  final backend = ref.read(engineerDatabaseChangeNotifierProvider);
  await backend.loadDevices();
  return backend.devices;
});

final sensorsProvider = FutureProvider.autoDispose.family<List<Sensor>, int>((
  ref,
  _,
) async {
  final backend = ref.read(engineerDatabaseChangeNotifierProvider);
  if (backend.sensors.isNotEmpty) {
    return backend.sensors;
  }
  await backend.loadSensors();
  return backend.sensors;
});
