import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user/providers/user_database_provider.dart';

final vendorDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserDatabaseProvider>(
  (ref) => UserDatabaseProvider(),
);

final vendorLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final vendorLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
