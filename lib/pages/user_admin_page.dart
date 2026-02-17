import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_admin/providers/user_admin_database_provider.dart';
import '../user_admin/screens/user_admin_screen.dart';

class UserAdminPage extends StatefulWidget {
  const UserAdminPage({super.key});

  @override
  State<UserAdminPage> createState() => _UserAdminPageState();
}

class _UserAdminPageState extends State<UserAdminPage> {
  late final UserAdminDatabaseProvider _databaseProvider;

  @override
  void initState() {
    super.initState();
    _databaseProvider = UserAdminDatabaseProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _databaseProvider,
      child: const UserAdminScreen(),
    );
  }

  @override
  void dispose() {
    _databaseProvider.dispose();
    super.dispose();
  }
}
