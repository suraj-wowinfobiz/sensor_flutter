import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engineer/providers/engineer_database_provider.dart';
import '../engineer/screens/engineer_screen.dart';

class EngineerPage extends StatefulWidget {
  const EngineerPage({super.key});

  @override
  State<EngineerPage> createState() => _EngineerPageState();
}

class _EngineerPageState extends State<EngineerPage> {
  late final EngineerDatabaseProvider _databaseProvider;

  @override
  void initState() {
    super.initState();
    _databaseProvider = EngineerDatabaseProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _databaseProvider,
      child: const EngineerScreen(),
    );
  }

  @override
  void dispose() {
    _databaseProvider.dispose();
    super.dispose();
  }
}
