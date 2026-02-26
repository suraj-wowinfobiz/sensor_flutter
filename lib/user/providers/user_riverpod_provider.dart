import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_database_provider.dart';

final userDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserDatabaseProvider>(
  (ref) => UserDatabaseProvider(),
);

final userCurrentViewStateProvider = StateProvider<String>((ref) => 'dashboard');

final userIsLoadingStateProvider = StateProvider<bool>((ref) => false);

final userSelectedDeviceIdStateProvider = StateProvider<String?>((ref) => null);

final userSelectedSensorIdStateProvider = StateProvider<String?>((ref) => null);

final userLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final userLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
