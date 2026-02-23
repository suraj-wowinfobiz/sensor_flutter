import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';

final superAdminDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<DatabaseProvider>((ref) => DatabaseProvider());
