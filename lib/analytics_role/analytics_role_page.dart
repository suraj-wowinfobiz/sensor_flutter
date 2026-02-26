import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import 'providers/analytics_role_riverpod_provider.dart';
import 'screens/analytics_role_screen.dart';

class AnalyticsRolePage extends ConsumerWidget {
  const AnalyticsRolePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(analyticsRoleDatabaseChangeNotifierProvider);
    return p.ChangeNotifierProvider.value(
      value: db,
      child: const AnalyticsRoleScreen(),
    );
  }
}
