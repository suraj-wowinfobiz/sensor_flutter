import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'super_admin_backend_provider.dart';

final superAdminBackendChangeNotifierProvider =
    ChangeNotifierProvider<SuperAdminBackendProvider>((ref) => SuperAdminBackendProvider());

final superAdminCurrentViewStateProvider =
    StateProvider<String>((ref) => 'dashboard');

final superAdminIsLoadingStateProvider = StateProvider<bool>((ref) => false);

final superAdminSelectedOrganizationIdStateProvider =
    StateProvider<String?>((ref) => null);

final superAdminSelectedSiteIdStateProvider =
    StateProvider<String?>((ref) => null);

final superAdminSelectedZoneIdStateProvider =
    StateProvider<String?>((ref) => null);

final superAdminLoginLoadingStateProvider =
    StateProvider<bool>((ref) => false);

final superAdminLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
