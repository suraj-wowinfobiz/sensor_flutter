import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user/providers/user_database_provider.dart';
import '../user/screens/user_screen.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late final UserDatabaseProvider _databaseProvider;

  @override
  void initState() {
    super.initState();
    _databaseProvider = UserDatabaseProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _databaseProvider,
      child: const UserScreen(),
    );
  }

  @override
  void dispose() {
    _databaseProvider.dispose();
    super.dispose();
  }
}
