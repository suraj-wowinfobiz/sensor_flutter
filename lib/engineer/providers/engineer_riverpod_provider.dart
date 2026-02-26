import 'package:flutter_riverpod/flutter_riverpod.dart';

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
