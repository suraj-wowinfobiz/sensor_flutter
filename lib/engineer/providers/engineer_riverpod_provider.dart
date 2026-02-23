import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'engineer_database_provider.dart';

final engineerDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<EngineerDatabaseProvider>(
  (ref) => EngineerDatabaseProvider(),
);
