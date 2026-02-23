import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../engineer/providers/engineer_riverpod_provider.dart';
import '../engineer/screens/engineer_screen.dart';

class EngineerPage extends ConsumerWidget {
  const EngineerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(engineerDatabaseChangeNotifierProvider);
    return p.ChangeNotifierProvider.value(
      value: db,
      child: const EngineerScreen(),
    );
  }
}
