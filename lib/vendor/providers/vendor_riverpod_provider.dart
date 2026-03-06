import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vendor_backend_provider.dart';

final vendorDatabaseChangeNotifierProvider =
    ChangeNotifierProvider<VendorBackendProvider>(
  (ref) => VendorBackendProvider(),
);

final vendorLoginLoadingStateProvider = StateProvider<bool>((ref) => false);

final vendorLoginObscurePasswordStateProvider =
    StateProvider<bool>((ref) => true);
