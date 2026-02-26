import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_admin_database_provider.dart';

final userAdminDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<UserAdminDatabaseProvider>(
  (ref) => UserAdminDatabaseProvider(),
);

final userAdminCurrentViewStateProvider =
    StateProvider<String>((ref) => 'dashboard');

final userAdminIsLoadingStateProvider = StateProvider<bool>((ref) => false);

final userAdminSelectedOrganizationIdStateProvider =
    StateProvider<String?>((ref) => null);

final userAdminSelectedSiteIdStateProvider =
    StateProvider<String?>((ref) => null);

final userAdminSelectedZoneIdStateProvider =
    StateProvider<String?>((ref) => null);

final userAdminLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final userAdminLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
