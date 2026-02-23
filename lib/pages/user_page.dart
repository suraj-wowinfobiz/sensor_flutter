import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import '../user/providers/user_riverpod_provider.dart';
import '../user/screens/user_screen.dart';

class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(userDatabaseChangeNotifierProvider);
    return p.ChangeNotifierProvider.value(
      value: db,
      child: const UserScreen(),
    );
  }
}
