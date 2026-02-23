import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_database_provider.dart';

final userDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserDatabaseProvider>(
  (ref) => UserDatabaseProvider(),
);
