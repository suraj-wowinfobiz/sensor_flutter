import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user/providers/user_database_provider.dart';

final analyticsRoleDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserDatabaseProvider>(
  (ref) => UserDatabaseProvider(),
);

final analyticsRoleLoginLoadingStateProvider =
    StateProvider<bool>((ref) => false);

final analyticsRoleLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
