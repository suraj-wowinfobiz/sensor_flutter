import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../user_admin/providers/user_admin_riverpod_provider.dart';
import '../user_admin/screens/user_admin_screen.dart';

class UserAdminPage extends ConsumerWidget {
  const UserAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(userAdminDatabaseChangeNotifierProvider);
    return p.ChangeNotifierProvider.value(
      value: db,
      child: const UserAdminScreen(),
    );
  }
}
