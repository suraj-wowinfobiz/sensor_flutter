import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import 'providers/analytics_riverpod_provider.dart';
import 'screens/analytics_screen.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(analyticsDatabaseChangeNotifierProvider);
    return p.ChangeNotifierProvider.value(
      value: db,
      child: const AnalyticsScreen(),
    );
  }
}
