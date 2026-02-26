import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'super_admin_database_provider.dart';

final superAdminDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<DatabaseProvider>((ref) => DatabaseProvider());
