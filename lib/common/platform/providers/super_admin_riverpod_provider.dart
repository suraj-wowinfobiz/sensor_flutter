import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../models/sensor.dart';
import 'super_admin_backend_provider.dart';

final superAdminBackendChangeNotifierProvider =
    ChangeNotifierProvider<SuperAdminBackendProvider>(
        (ref) => SuperAdminBackendProvider());

final superAdminCurrentViewStateProvider =
    StateProvider<String>((ref) => 'dashboard');

final superAdminIsLoadingStateProvider = StateProvider<bool>((ref) => false);

final superAdminSelectedOrganizationIdStateProvider =
    StateProvider<String?>((ref) => null);

final superAdminSelectedSiteIdStateProvider =
    StateProvider<String?>((ref) => null);

final superAdminSelectedZoneIdStateProvider =
    StateProvider<String?>((ref) => null);

final superAdminLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final superAdminLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);

// Use StateNotifierProvider for better control
final devicesProvider =
    FutureProvider.autoDispose.family<List<Device>, int>((ref, _) async {
  final backend = ref.read(superAdminBackendChangeNotifierProvider);

  // Devices screen: hit only the single get-all devices API.
  await backend.loadDevices();
  return backend.devices;
});

final sensorsProvider =
    FutureProvider.autoDispose.family<List<Sensor>, int>((ref, _) async {
  final backend = ref.read(superAdminBackendChangeNotifierProvider);

  // Sensors screen: hit only the single get-all sensors API.
  if (backend.sensors.isNotEmpty) {
    return backend.sensors;
  }

  await backend.loadSensors();
  return backend.sensors;
});
