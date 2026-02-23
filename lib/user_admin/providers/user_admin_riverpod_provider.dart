import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_admin_database_provider.dart';

final userAdminDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserAdminDatabaseProvider>(
  (ref) => UserAdminDatabaseProvider(),
);
