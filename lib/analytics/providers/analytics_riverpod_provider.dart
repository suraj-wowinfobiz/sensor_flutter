import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user/providers/user_database_provider.dart';

final analyticsDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserDatabaseProvider>(
  (ref) => UserDatabaseProvider(),
);

final analyticsLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final analyticsLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
