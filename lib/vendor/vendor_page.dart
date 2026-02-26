import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import 'providers/vendor_riverpod_provider.dart';
import 'screens/vendor_screen.dart';

class VendorPage extends ConsumerWidget {
  const VendorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(vendorDatabaseChangeNotifierProvider);
    return p.ChangeNotifierProvider.value(
      value: db,
      child: const VendorScreen(),
    );
  }
}
